#!/bin/bash

# Script pour démarrer FreqTrad en mode webserver avec stratégie
# Usage: ./start-webserver.sh

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

print_message "=== Démarrage de FreqTrad en Mode Web avec Stratégie ==="

# 1. Arrêter FreqTrad s'il fonctionne
print_message "Arrêt de FreqTrad..."
pkill -f freqtrade
sleep 2

# 2. Vérifier la configuration
if [ ! -f "config.json" ]; then
    print_error "Fichier config.json non trouvé"
    exit 1
fi

# 3. Démarrer FreqTrad en mode webserver avec stratégie
print_message "Démarrage de FreqTrad..."
print_message "Mode: webserver avec stratégie BalancedAdvancedStrategy"
print_message "Configuration: config.json"
print_message "Accès: http://0.0.0.0:8080"

# Démarrer en arrière-plan
source venv/bin/activate && freqtrade trade --config config.json --strategy BalancedAdvancedStrategy &
FREQTRADE_PID=$!

# Attendre que FreqTrad démarre
print_message "Attente du démarrage..."
sleep 5

# Vérifier que FreqTrad fonctionne
if kill -0 $FREQTRADE_PID 2>/dev/null; then
    print_success "FreqTrad démarré avec succès (PID: $FREQTRADE_PID)"
    
    # Tester l'API
    print_message "Test de l'API..."
    sleep 3
    
    if curl -s http://127.0.0.1:8080/api/v1/ping | grep -q "pong"; then
        print_success "API accessible"
        
        # Afficher les informations de connexion
        SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || echo "localhost")
        print_message "FreqTrad accessible sur:"
        echo "  - Local: http://127.0.0.1:8080"
        echo "  - Externe: http://$SERVER_IP:8080"
        echo "  - Toutes interfaces: http://0.0.0.0:8080"
        echo
        print_message "Identifiants:"
        echo "  - Utilisateur: admin"
        echo "  - Mot de passe: NouveauMotDePasse2025!"
        echo
        print_message "Commandes utiles:"
        echo "  - Voir les logs: ./logs.sh"
        echo "  - Tester l'API: ./test-api-auth.sh"
        echo "  - Arrêter: pkill -f freqtrade"
    else
        print_warning "API pas encore accessible, attendez quelques secondes"
    fi
else
    print_error "FreqTrad n'a pas démarré correctement"
    print_message "Vérifiez les logs avec: ./logs.sh"
    exit 1
fi

print_success "=== FreqTrad démarré ! ==="
