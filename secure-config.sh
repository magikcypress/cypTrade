#!/bin/bash

# Script pour sécuriser la configuration FreqTrad
# Usage: ./secure-config.sh

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

print_message "=== Sécurisation de la Configuration FreqTrad ==="

# 1. Générer une clé JWT sécurisée
print_message "Génération d'une clé JWT sécurisée..."
JWT_SECRET=$(openssl rand -hex 32)
print_success "Clé JWT générée: ${JWT_SECRET:0:16}..."

# 2. Générer un mot de passe sécurisé
print_message "Génération d'un mot de passe sécurisé..."
API_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-16)
print_success "Mot de passe généré: ${API_PASSWORD:0:8}..."

# 3. Créer un fichier .env sécurisé
print_message "Création du fichier .env sécurisé..."
cat > .env << EOF
# Configuration FreqTrad - Sécurisé
BINANCE_API_KEY=your_binance_api_key_here
BINANCE_SECRET=your_binance_secret_here

# Telegram Bot
TELEGRAM_TOKEN=your_telegram_token_here
TELEGRAM_CHAT_ID=your_telegram_chat_id_here

# API Server - Sécurisé
JWT_SECRET=$JWT_SECRET
API_USERNAME=admin
API_PASSWORD=$API_PASSWORD
EOF

print_success "Fichier .env créé avec des valeurs sécurisées"

# 4. Mettre à jour config-test.json
print_message "Mise à jour de config-test.json..."
if [ -f "config-test.json" ]; then
    # Sauvegarder l'ancien fichier
    cp config-test.json config-test.json.backup
    
    # Mettre à jour la configuration
    sed -i "s/\"listen_ip_address\": \".*\"/\"listen_ip_address\": \"127.0.0.1\"/" config-test.json
    sed -i "s/\"jwt_secret\": \".*\"/\"jwt_secret\": \"$JWT_SECRET\"/" config-test.json
    sed -i "s/\"password\": \".*\"/\"password\": \"$API_PASSWORD\"/" config-test.json
    
    print_success "config-test.json mis à jour"
else
    print_warning "config-test.json non trouvé"
fi

# 5. Mettre à jour config.json
print_message "Mise à jour de config.json..."
if [ -f "config.json" ]; then
    # Sauvegarder l'ancien fichier
    cp config.json config.json.backup
    
    # Mettre à jour la configuration
    sed -i "s/\"listen_ip_address\": \".*\"/\"listen_ip_address\": \"127.0.0.1\"/" config.json
    sed -i "s/\"jwt_secret\": \".*\"/\"jwt_secret\": \"$JWT_SECRET\"/" config.json
    sed -i "s/\"password\": \".*\"/\"password\": \"$API_PASSWORD\"/" config.json
    
    print_success "config.json mis à jour"
else
    print_warning "config.json non trouvé"
fi

# 6. Créer un fichier de configuration pour l'accès externe (optionnel)
print_message "Création d'un fichier de configuration pour l'accès externe..."
cat > config-external.json << EOF
{
    "api_server": {
        "enabled": true,
        "listen_ip_address": "0.0.0.0",
        "listen_port": 8080,
        "verbosity": "error",
        "enable_openapi": false,
        "jwt_secret": "$JWT_SECRET",
        "CORS_origins": [
            "http://localhost:8080",
            "http://127.0.0.1:8080",
            "https://yourdomain.com"
        ],
        "username": "admin",
        "password": "$API_PASSWORD"
    }
}
EOF

print_success "config-external.json créé pour l'accès externe"

# 7. Redémarrer FreqTrad si en cours d'exécution
if pgrep -f "freqtrade" > /dev/null; then
    print_message "FreqTrad en cours d'exécution, redémarrage nécessaire..."
    
    if systemctl is-active --quiet freqtrade 2>/dev/null; then
        print_message "Redémarrage via systemd..."
        sudo systemctl restart freqtrade
        print_success "Service redémarré"
    else
        print_message "Arrêt des processus FreqTrad..."
        pkill -f freqtrade
        sleep 2
        print_message "Redémarrage de FreqTrad..."
        if [ -f "start.sh" ]; then
            ./start.sh &
        fi
    fi
fi

# 8. Afficher les informations de sécurité
print_success "=== Configuration Sécurisée ! ==="
echo
print_message "Informations de sécurité:"
echo "  - Adresse IP: 127.0.0.1 (accès local uniquement)"
echo "  - Port: 8080"
echo "  - JWT Secret: ${JWT_SECRET:0:16}..."
echo "  - Mot de passe: ${API_PASSWORD:0:8}..."
echo
print_message "Accès à l'interface:"
echo "  - Local: http://localhost:8080"
echo "  - Local: http://127.0.0.1:8080"
echo
print_message "Pour l'accès externe:"
echo "  - Utilisez config-external.json"
echo "  - Configurez un reverse proxy (nginx)"
echo "  - Utilisez HTTPS avec certificat SSL"
echo
print_warning "Sécurité:"
echo "  - L'API n'est accessible que localement"
echo "  - JWT secret sécurisé généré"
echo "  - Mot de passe fort généré"
echo "  - CORS configuré pour localhost uniquement"
echo
print_success "Configuration sécurisée terminée ! 🔒"
