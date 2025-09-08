#!/bin/bash

# Installation rapide de FreqTrad
# Usage: ./quick-install.sh

set -e

echo "🚀 Installation rapide de FreqTrad..."

# Vérifier Python 3.11
if ! command -v python3.11 &> /dev/null; then
    echo "❌ Python 3.11 requis. Installation..."
    sudo apt update
    sudo apt install -y python3.11 python3.11-venv python3.11-dev
fi

# Créer l'environnement virtuel
echo "📦 Création de l'environnement virtuel..."
python3.11 -m venv venv

# Activer et installer FreqTrad
echo "🔧 Installation de FreqTrad..."
source venv/bin/activate
pip install --upgrade pip
pip install 'freqtrade[all]==2025.8'

# Installer l'interface web
echo "🌐 Installation de l'interface web..."
freqtrade install-ui

# Créer le fichier .env
echo "⚙️ Configuration..."
cat > .env << EOF
# Configuration FreqTrad
BINANCE_API_KEY=your_binance_api_key_here
BINANCE_SECRET=your_binance_secret_here

# Telegram Bot
TELEGRAM_TOKEN=your_telegram_token_here
TELEGRAM_CHAT_ID=your_telegram_chat_id_here

# API Server
JWT_SECRET=$(openssl rand -hex 32)
API_USERNAME=admin
API_PASSWORD=$(openssl rand -hex 16)
EOF

# Créer les scripts de gestion
cat > start.sh << 'EOF'
#!/bin/bash
source venv/bin/activate
freqtrade webserver --config config-test.json
EOF

cat > trade.sh << 'EOF'
#!/bin/bash
source venv/bin/activate
freqtrade trade --config config-test.json --strategy SampleStrategy
EOF

chmod +x *.sh

echo "✅ Installation terminée !"
echo "🌐 Interface web: http://localhost:8080"
echo "🔑 Identifiants: admin / $(grep API_PASSWORD .env | cut -d'=' -f2)"
echo "🚀 Démarrer: ./start.sh"
