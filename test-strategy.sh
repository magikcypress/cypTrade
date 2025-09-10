#!/bin/bash

# Script pour tester les stratégies FreqTrad
# Usage: ./test-strategy.sh [strategy_name]

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

# Stratégie par défaut
STRATEGY=${1:-"SampleStrategy"}

print_message "=== Test de la Stratégie FreqTrad ==="
print_message "Stratégie: $STRATEGY"

# 1. Vérifier que FreqTrad fonctionne
print_message "1. Vérification de FreqTrad..."
if ! pgrep -f freqtrade > /dev/null; then
    print_error "FreqTrad n'est pas en cours d'exécution"
    print_message "Démarrez FreqTrad avec: ./start-webserver.sh"
    exit 1
fi
print_success "FreqTrad fonctionne"

# 2. Tester la stratégie avec backtesting
print_message "2. Test de la stratégie avec backtesting..."
if [ -f "config-webserver.json" ]; then
    CONFIG_FILE="config-webserver.json"
else
    CONFIG_FILE="config.json"
fi

print_message "Configuration: $CONFIG_FILE"

# Test rapide avec backtesting
source venv/bin/activate
freqtrade backtesting \
    --config $CONFIG_FILE \
    --strategy $STRATEGY \
    --timerange 20240901-20240910 \
    --max-open-trades 1 \
    --dry-run-wallet 1000

if [ $? -eq 0 ]; then
    print_success "Stratégie $STRATEGY testée avec succès"
else
    print_error "Erreur lors du test de la stratégie $STRATEGY"
    print_message "Vérifiez les logs pour plus de détails"
fi

# 3. Tester l'API avec la stratégie
print_message "3. Test de l'API avec la stratégie..."
if curl -s http://127.0.0.1:8080/api/v1/ping | grep -q "pong"; then
    print_success "API accessible"
    
    # Tester l'endpoint de performance
    print_message "Test de l'endpoint de performance..."
    PERF_RESPONSE=$(curl -s http://127.0.0.1:8080/api/v1/performance 2>/dev/null)
    if [ $? -eq 0 ]; then
        print_success "Endpoint de performance accessible"
        echo "Réponse: $PERF_RESPONSE"
    else
        print_warning "Endpoint de performance non accessible (normal si pas de trades)"
    fi
else
    print_error "API non accessible"
fi

print_message "=== Test terminé ==="
