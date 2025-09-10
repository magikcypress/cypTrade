#!/bin/bash

# Script pour afficher les logs FreqTrad en temps réel
# Usage: ./logs.sh

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

print_message "=== Logs FreqTrad ==="

# Vérifier si FreqTrad fonctionne
if ! pgrep -f "freqtrade" > /dev/null; then
    print_error "FreqTrad n'est pas en cours d'exécution"
    print_message "Démarrez FreqTrad avec: ./start.sh"
    exit 1
fi

print_success "FreqTrad est en cours d'exécution"

# Vérifier le fichier de log
LOG_FILE="user_data/logs/freqtrade.log"

if [ -f "$LOG_FILE" ]; then
    print_message "Fichier de log trouvé: $LOG_FILE"
    print_message "Taille du fichier: $(du -h "$LOG_FILE" | cut -f1)"
    echo
    print_message "=== Dernières 50 lignes ==="
    tail -50 "$LOG_FILE"
    echo
    print_message "=== Suivi en temps réel (Ctrl+C pour arrêter) ==="
    tail -f "$LOG_FILE"
else
    print_warning "Fichier de log non trouvé: $LOG_FILE"
    print_message "Vérification des logs système..."
    
    # Essayer de trouver les logs dans d'autres emplacements
    if [ -f "logs/freqtrade.log" ]; then
        print_message "Log trouvé dans: logs/freqtrade.log"
        tail -f "logs/freqtrade.log"
    elif [ -f "/tmp/freqtrade.log" ]; then
        print_message "Log trouvé dans: /tmp/freqtrade.log"
        tail -f "/tmp/freqtrade.log"
    else
        print_message "Aucun fichier de log trouvé, affichage des logs système..."
        print_message "Utilisez: journalctl -u freqtrade -f (si service systemd)"
        print_message "Ou redémarrez FreqTrad avec: ./start.sh"
    fi
fi
