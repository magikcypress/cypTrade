#!/bin/bash

# Script de déploiement vers le serveur
# Usage: ./deploy-to-server.sh user@server

set -e

if [ $# -eq 0 ]; then
    echo "Usage: $0 user@server"
    echo "Exemple: $0 freqtrade@192.168.1.100"
    exit 1
fi

SERVER=$1
REMOTE_DIR="/home/$(echo $SERVER | cut -d'@' -f1)/cypTrade"

echo "🚀 Déploiement vers $SERVER..."

# Créer l'archive du projet
echo "📦 Création de l'archive..."
tar --exclude='.git' \
    --exclude='venv' \
    --exclude='__pycache__' \
    --exclude='*.pyc' \
    --exclude='.env' \
    --exclude='user_data/logs' \
    --exclude='user_data/data' \
    -czf freqtrade.tar.gz .

# Copier vers le serveur
echo "📤 Upload vers le serveur..."
scp freqtrade.tar.gz $SERVER:/tmp/

# Exécuter l'installation sur le serveur
echo "🔧 Installation sur le serveur..."
ssh $SERVER << EOF
    # Créer le répertoire
    mkdir -p $REMOTE_DIR
    cd $REMOTE_DIR
    
    # Extraire l'archive
    tar -xzf /tmp/freqtrade.tar.gz
    
    # Rendre les scripts exécutables
    chmod +x *.sh scripts/*.sh 2>/dev/null || true
    
    # Exécuter l'installation rapide
    ./quick-install.sh
    
    # Nettoyer
    rm /tmp/freqtrade.tar.gz
EOF

# Nettoyer l'archive locale
rm freqtrade.tar.gz

echo "✅ Déploiement terminé !"
echo "🌐 Connectez-vous au serveur: ssh $SERVER"
echo "📁 Répertoire: $REMOTE_DIR"
echo "🚀 Démarrer: cd $REMOTE_DIR && ./start.sh"
