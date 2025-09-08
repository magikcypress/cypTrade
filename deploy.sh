#!/bin/bash

# Script de déploiement pour VPS
# Usage: ./deploy.sh [digitalocean|vultr|hetzner]

set -e

PROVIDER=${1:-digitalocean}
PROJECT_NAME="cypTrade"

echo "🚀 Déploiement de FreqTrad sur $PROVIDER"

# Vérifier que Docker est installé
if ! command -v docker &> /dev/null; then
    echo "❌ Docker n'est pas installé. Installation..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    sudo usermod -aG docker $USER
    echo "✅ Docker installé. Redémarrez votre session."
    exit 1
fi

# Vérifier que Docker Compose est installé
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose n'est pas installé. Installation..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

# Créer le fichier .env s'il n'existe pas
if [ ! -f .env ]; then
    echo "📝 Création du fichier .env..."
    cp env.example .env
    echo "⚠️  Veuillez configurer le fichier .env avec vos clés API"
    exit 1
fi

# Construire et démarrer les services
echo "🔨 Construction de l'image Docker..."
docker-compose -f docker-compose.prod.yml build

echo "🚀 Démarrage des services..."
docker-compose -f docker-compose.prod.yml up -d

echo "✅ Déploiement terminé !"
echo "📊 Interface web: http://localhost:8080"
echo "📱 Bot Telegram: Configuré selon .env"
echo "📈 Logs: docker-compose -f docker-compose.prod.yml logs -f"

# Afficher les commandes utiles
echo ""
echo "🔧 Commandes utiles:"
echo "  Arrêter: docker-compose -f docker-compose.prod.yml down"
echo "  Redémarrer: docker-compose -f docker-compose.prod.yml restart"
echo "  Logs: docker-compose -f docker-compose.prod.yml logs -f"
echo "  Status: docker-compose -f docker-compose.prod.yml ps"
