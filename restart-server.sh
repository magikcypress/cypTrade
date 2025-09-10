#!/bin/bash

# Script pour redémarrer FreqTrad sur le serveur
# Usage: ./restart-server.sh

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

print_message "=== Redémarrage de FreqTrad sur le Serveur ==="

# 1. Arrêter FreqTrad
print_message "Arrêt de FreqTrad..."
if systemctl is-active --quiet freqtrade 2>/dev/null; then
    sudo systemctl stop freqtrade
    print_success "Service FreqTrad arrêté"
else
    print_message "Arrêt des processus FreqTrad..."
    pkill -f freqtrade
    sleep 2
fi

# 2. Vérifier que FreqTrad est arrêté
if pgrep -f freqtrade > /dev/null; then
    print_warning "FreqTrad encore en cours d'exécution, forçage de l'arrêt..."
    pkill -9 -f freqtrade
    sleep 2
fi

# 3. Redémarrer FreqTrad
print_message "Redémarrage de FreqTrad..."
if systemctl is-enabled --quiet freqtrade 2>/dev/null; then
    sudo systemctl start freqtrade
    print_success "Service FreqTrad redémarré"
else
    print_message "Démarrage manuel de FreqTrad..."
    cd /home/freqtrade/cypTrade
    sudo -u freqtrade bash -c "source venv/bin/activate && freqtrade webserver --config config.json" &
    print_success "FreqTrad démarré manuellement"
fi

# 4. Attendre que FreqTrad démarre
print_message "Attente du démarrage de FreqTrad..."
sleep 5

# 5. Vérifier que FreqTrad fonctionne
print_message "Vérification du statut de FreqTrad..."
if pgrep -f freqtrade > /dev/null; then
    print_success "FreqTrad est en cours d'exécution"
    
    # Afficher l'adresse IP
    SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || echo "localhost")
    print_message "FreqTrad accessible sur:"
    echo "  - Local: http://127.0.0.1:8080"
    echo "  - Externe: http://$SERVER_IP:8080"
    echo "  - Toutes interfaces: http://0.0.0.0:8080"
    
    # Tester la connexion
    if curl -s http://127.0.0.1:8080/api/v1/ping > /dev/null; then
        print_success "API FreqTrad répond correctement"
    else
        print_warning "API FreqTrad ne répond pas encore, attendez quelques secondes"
    fi
else
    print_error "FreqTrad n'a pas démarré correctement"
    print_message "Vérifiez les logs avec: sudo journalctl -u freqtrade -f"
    exit 1
fi

print_success "=== Redémarrage terminé ! ==="
