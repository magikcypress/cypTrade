#!/bin/bash

# Script de diagnostic de l'API FreqTrad
# Usage: ./diagnose-api.sh

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_message() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_message "=== Diagnostic de l'API FreqTrad ==="

# 1. Vérifier si FreqTrad fonctionne
print_message "1. Vérification du processus FreqTrad..."
if pgrep -f freqtrade > /dev/null; then
    print_success "FreqTrad est en cours d'exécution"
    echo "PID: $(pgrep -f freqtrade)"
else
    print_error "FreqTrad n'est pas en cours d'exécution"
    exit 1
fi

# 2. Vérifier la connectivité API
print_message "2. Test de connectivité API..."
if curl -s http://127.0.0.1:8080/api/v1/ping > /dev/null; then
    print_success "API répond au ping"
else
    print_error "API ne répond pas"
    exit 1
fi

# 3. Vérifier l'état du bot
print_message "3. Vérification de l'état du bot..."
STATUS_RESPONSE=$(curl -s http://127.0.0.1:8080/api/v1/status 2>/dev/null)
if [ $? -eq 0 ]; then
    echo "Réponse status: $STATUS_RESPONSE"
    if echo "$STATUS_RESPONSE" | grep -q "running"; then
        print_success "Bot en état 'running'"
    else
        print_warning "Bot pas en état 'running'"
    fi
else
    print_error "Impossible de récupérer l'état du bot"
fi

# 4. Vérifier les logs récents
print_message "4. Vérification des logs récents..."
if [ -f "user_data/logs/freqtrade.log" ]; then
    print_message "Dernières erreurs dans les logs:"
    tail -20 user_data/logs/freqtrade.log | grep -i error || echo "Aucune erreur récente"
else
    print_warning "Fichier de log non trouvé"
fi

# 5. Vérifier la configuration
print_message "5. Vérification de la configuration..."
if grep -q '"initial_state": "running"' config.json; then
    print_success "Configuration: initial_state = running"
else
    print_warning "Configuration: initial_state != running"
fi

# 6. Tester les endpoints API
print_message "6. Test des endpoints API..."

# Test ping
if curl -s http://127.0.0.1:8080/api/v1/ping | grep -q "pong"; then
    print_success "✓ /api/v1/ping"
else
    print_error "✗ /api/v1/ping"
fi

# Test version
VERSION_RESPONSE=$(curl -s http://127.0.0.1:8080/api/v1/version 2>/dev/null)
if [ $? -eq 0 ] && [ -n "$VERSION_RESPONSE" ]; then
    print_success "✓ /api/v1/version: $VERSION_RESPONSE"
else
    print_error "✗ /api/v1/version"
fi

# Test balance (peut échouer en dry run)
BALANCE_RESPONSE=$(curl -s http://127.0.0.1:8080/api/v1/balance 2>/dev/null)
if [ $? -eq 0 ]; then
    print_success "✓ /api/v1/balance"
else
    print_warning "⚠ /api/v1/balance (normal en dry run)"
fi

# 7. Recommandations
print_message "7. Recommandations..."

if echo "$STATUS_RESPONSE" | grep -q "Bot is not in the correct state"; then
    print_warning "Problème détecté: Bot pas dans le bon état"
    echo "Solutions possibles:"
    echo "  1. Redémarrer FreqTrad: ./restart-server.sh"
    echo "  2. Vérifier la configuration: config.json"
    echo "  3. Démarrer en mode trade: freqtrade trade --config config.json --strategy SampleStrategy"
    echo "  4. Vérifier les logs: ./logs.sh"
fi

print_message "=== Diagnostic terminé ==="
