#!/bin/bash

# Script de monitoring de /tmp en temps réel
# Usage: ./monitor-tmp.sh

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

print_message "=== Monitoring de /tmp en temps réel ==="
print_message "Appuyez sur Ctrl+C pour arrêter"

# Fonction de nettoyage
cleanup() {
    echo
    print_message "Arrêt du monitoring..."
    exit 0
}

# Capturer Ctrl+C
trap cleanup SIGINT

# Monitoring en boucle
while true; do
    clear
    echo "=== Monitoring /tmp - $(date) ==="
    echo
    
    # Espace utilisé par /tmp
    echo "Espace utilisé par /tmp:"
    du -sh /tmp 2>/dev/null || echo "Impossible d'accéder à /tmp"
    echo
    
    # Top 10 des plus gros répertoires dans /tmp
    echo "Top 10 des plus gros répertoires dans /tmp:"
    du -h /tmp 2>/dev/null | sort -hr | head -10 || echo "Impossible d'accéder à /tmp"
    echo
    
    # Fichiers pip dans /tmp
    echo "Fichiers pip dans /tmp:"
    find /tmp -name "pip-*" -type d 2>/dev/null | head -5 || echo "Aucun fichier pip trouvé"
    echo
    
    # Fichiers build dans /tmp
    echo "Fichiers build dans /tmp:"
    find /tmp -name "build-*" -type d 2>/dev/null | head -5 || echo "Aucun fichier build trouvé"
    echo
    
    # Espace disque total
    echo "Espace disque total:"
    df -h / | tail -1
    echo
    
    # Attendre 5 secondes
    sleep 5
done
