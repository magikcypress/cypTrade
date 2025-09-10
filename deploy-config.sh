#!/bin/bash

# Script pour déployer la configuration sur le serveur
# Usage: ./deploy-config.sh [adresse_ip_serveur]

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

# Vérifier les arguments
if [ $# -eq 0 ]; then
    print_error "Usage: $0 [adresse_ip_serveur]"
    print_message "Exemple: $0 192.168.1.100"
    exit 1
fi

SERVER_IP="$1"
FREQTRADE_USER="freqtrade"
FREQTRADE_DIR="/home/$FREQTRADE_USER/cypTrade"

print_message "=== Déploiement de la Configuration FreqTrad ==="
print_message "Serveur: $SERVER_IP"
print_message "Répertoire: $FREQTRADE_DIR"

# 1. Copier la configuration mise à jour
print_message "Copie de la configuration..."
scp config.json $FREQTRADE_USER@$SERVER_IP:$FREQTRADE_DIR/
scp .env $FREQTRADE_USER@$SERVER_IP:$FREQTRADE_DIR/
scp restart-server.sh $FREQTRADE_USER@$SERVER_IP:$FREQTRADE_DIR/

print_success "Configuration copiée"

# 2. Redémarrer FreqTrad sur le serveur
print_message "Redémarrage de FreqTrad sur le serveur..."
ssh $FREQTRADE_USER@$SERVER_IP "cd $FREQTRADE_DIR && chmod +x restart-server.sh && ./restart-server.sh"

print_success "=== Déploiement terminé ! ==="
echo
print_message "FreqTrad est maintenant accessible sur:"
echo "  - http://$SERVER_IP:8080"
echo
print_message "Identifiants par défaut:"
echo "  - Utilisateur: admin"
echo "  - Mot de passe: NouveauMotDePasse2025!"
echo
print_warning "Sécurité:"
echo "  - Changez le mot de passe avec: ./change-password.sh"
echo "  - Configurez un pare-feu si nécessaire"
echo "  - Utilisez HTTPS en production"
