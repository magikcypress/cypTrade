#!/bin/bash

# Script d'installation FreqTrad universel pour serveur
# Détecte automatiquement la version de Python disponible
# Usage: ./install-freqtrade-universal.sh

set -e  # Arrêter en cas d'erreur

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction pour afficher les messages
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

# Vérifier si le script est exécuté en tant que root
if [[ $EUID -eq 0 ]]; then
   print_error "Ce script ne doit pas être exécuté en tant que root"
   print_message "Utilisez un utilisateur normal avec des privilèges sudo"
   exit 1
fi

# Configuration
FREQTRADE_USER="freqtrade"
FREQTRADE_HOME="/home/$FREQTRADE_USER"
FREQTRADE_DIR="$FREQTRADE_HOME/cypTrade"

print_message "=== Installation de FreqTrad sur le serveur ==="

# 1. Mise à jour du système
print_message "Mise à jour du système..."
sudo apt update && sudo apt upgrade -y

# 2. Installation des dépendances de base
print_message "Installation des dépendances de base..."
sudo apt install -y \
    software-properties-common \
    git \
    curl \
    wget \
    unzip \
    build-essential \
    libffi-dev \
    libssl-dev \
    libjpeg-dev \
    zlib1g-dev \
    libfreetype6-dev \
    liblcms2-dev \
    libwebp-dev \
    tcl8.6-dev \
    tk8.6-dev \
    python3-tk \
    libharfbuzz-dev \
    libfribidi-dev \
    libxcb1-dev

# 3. Détection et installation de Python
print_message "Détection de la version de Python disponible..."

# Fonction pour vérifier si une version de Python est disponible
check_python_version() {
    local version=$1
    if command -v python$version &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# Fonction pour installer une version de Python
install_python_version() {
    local version=$1
    print_message "Installation de Python $version..."
    
    case $version in
        "3.11")
            sudo add-apt-repository -y ppa:deadsnakes/ppa
            sudo apt update
            sudo apt install -y python3.11 python3.11-venv python3.11-dev
            ;;
        "3.10")
            sudo add-apt-repository -y ppa:deadsnakes/ppa
            sudo apt update
            sudo apt install -y python3.10 python3.10-venv python3.10-dev
            ;;
        "3.9")
            sudo add-apt-repository -y ppa:deadsnakes/ppa
            sudo apt update
            sudo apt install -y python3.9 python3.9-venv python3.9-dev
            ;;
        "3.8")
            sudo apt install -y python3.8 python3.8-venv python3.8-dev
            ;;
        *)
            print_error "Version de Python $version non supportée"
            return 1
            ;;
    esac
}

# Détecter la version de Python à utiliser
PYTHON_VERSION=""
for version in "3.11" "3.10" "3.9" "3.8"; do
    if check_python_version $version; then
        PYTHON_VERSION=$version
        print_success "Python $version trouvé sur le système"
        break
    fi
done

# Si aucune version n'est trouvée, essayer d'installer Python 3.11
if [ -z "$PYTHON_VERSION" ]; then
    print_message "Aucune version de Python compatible trouvée, installation de Python 3.11..."
    if install_python_version "3.11"; then
        PYTHON_VERSION="3.11"
    elif install_python_version "3.10"; then
        PYTHON_VERSION="3.10"
    elif install_python_version "3.9"; then
        PYTHON_VERSION="3.9"
    else
        print_error "Impossible d'installer une version compatible de Python"
        exit 1
    fi
fi

print_success "Python $PYTHON_VERSION sera utilisé"

# 4. Création de l'utilisateur FreqTrad (si n'existe pas)
if ! id "$FREQTRADE_USER" &>/dev/null; then
    print_message "Création de l'utilisateur $FREQTRADE_USER..."
    sudo useradd -m -s /bin/bash $FREQTRADE_USER
    sudo usermod -aG sudo $FREQTRADE_USER
    print_success "Utilisateur $FREQTRADE_USER créé"
else
    print_warning "L'utilisateur $FREQTRADE_USER existe déjà"
fi

# 5. Configuration du répertoire de travail
print_message "Configuration du répertoire de travail..."
sudo mkdir -p $FREQTRADE_DIR
sudo chown $FREQTRADE_USER:$FREQTRADE_USER $FREQTRADE_DIR

# 6. Cloner ou copier le projet
if [ -d "$FREQTRADE_DIR/.git" ]; then
    print_message "Mise à jour du projet existant..."
    sudo -u $FREQTRADE_USER git -C $FREQTRADE_DIR pull
else
    print_message "Copie du projet vers $FREQTRADE_DIR..."
    sudo cp -r . $FREQTRADE_DIR/
    sudo chown -R $FREQTRADE_USER:$FREQTRADE_USER $FREQTRADE_DIR
fi

# 7. Création de l'environnement virtuel
VENV_DIR="$FREQTRADE_DIR/venv"
print_message "Création de l'environnement virtuel Python $PYTHON_VERSION..."
sudo -u $FREQTRADE_USER python$PYTHON_VERSION -m venv $VENV_DIR

# 8. Activation et installation des dépendances
print_message "Installation des dépendances Python..."
sudo -u $FREQTRADE_USER bash -c "source $VENV_DIR/bin/activate && pip install --upgrade pip"
sudo -u $FREQTRADE_USER bash -c "source $VENV_DIR/bin/activate && pip install -r $FREQTRADE_DIR/requirements.txt"

# 9. Installation de FreqTrad UI
print_message "Installation de FreqTrad UI..."
sudo -u $FREQTRADE_USER bash -c "source $VENV_DIR/bin/activate && freqtrade install-ui"

# 10. Configuration des permissions
print_message "Configuration des permissions..."
sudo chown -R $FREQTRADE_USER:$FREQTRADE_USER $FREQTRADE_DIR
sudo chmod +x $FREQTRADE_DIR/scripts/*.sh 2>/dev/null || true

# 11. Création du fichier .env
print_message "Création du fichier .env..."
sudo -u $FREQTRADE_USER tee $FREQTRADE_DIR/.env > /dev/null << EOF
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

# 12. Création du service systemd
print_message "Création du service systemd..."
sudo tee /etc/systemd/system/freqtrade.service > /dev/null << EOF
[Unit]
Description=FreqTrad Trading Bot
After=network.target

[Service]
Type=simple
User=$FREQTRADE_USER
Group=$FREQTRADE_USER
WorkingDirectory=$FREQTRADE_DIR
Environment=PATH=$VENV_DIR/bin
ExecStart=$VENV_DIR/bin/freqtrade webserver --config config-test.json
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# 13. Rechargement et activation du service
print_message "Configuration du service systemd..."
sudo systemctl daemon-reload
sudo systemctl enable freqtrade

# 14. Configuration du pare-feu
print_message "Configuration du pare-feu..."
sudo ufw allow 8080/tcp comment "FreqTrad Web Interface"
sudo ufw --force enable

# 15. Création des scripts de gestion
print_message "Création des scripts de gestion..."

# Script de démarrage
sudo -u $FREQTRADE_USER tee $FREQTRADE_DIR/start.sh > /dev/null << 'EOF'
#!/bin/bash
source venv/bin/activate
freqtrade webserver --config config-test.json
EOF

# Script d'arrêt
sudo -u $FREQTRADE_USER tee $FREQTRADE_DIR/stop.sh > /dev/null << 'EOF'
#!/bin/bash
pkill -f freqtrade
EOF

# Script de redémarrage
sudo -u $FREQTRADE_USER tee $FREQTRADE_DIR/restart.sh > /dev/null << 'EOF'
#!/bin/bash
./stop.sh
sleep 2
./start.sh
EOF

# Script de trading
sudo -u $FREQTRADE_USER tee $FREQTRADE_DIR/trade.sh > /dev/null << 'EOF'
#!/bin/bash
source venv/bin/activate
freqtrade trade --config config-test.json --strategy SampleStrategy
EOF

# Rendre les scripts exécutables
sudo chmod +x $FREQTRADE_DIR/*.sh

# 16. Création du script de mise à jour
sudo -u $FREQTRADE_USER tee $FREQTRADE_DIR/update.sh > /dev/null << 'EOF'
#!/bin/bash
echo "Mise à jour de FreqTrad..."
git pull
source venv/bin/activate
pip install --upgrade freqtrade[all]
freqtrade install-ui
echo "Mise à jour terminée. Redémarrez le service avec: sudo systemctl restart freqtrade"
EOF

sudo chmod +x $FREQTRADE_DIR/update.sh

# 17. Affichage des informations finales
print_success "=== Installation terminée avec succès ! ==="
echo
print_message "Informations importantes:"
echo "  - Répertoire FreqTrad: $FREQTRADE_DIR"
echo "  - Utilisateur: $FREQTRADE_USER"
echo "  - Python Version: $PYTHON_VERSION"
echo "  - Interface web: http://$(curl -s ifconfig.me):8080"
echo "  - Identifiants: admin / $(sudo cat $FREQTRADE_DIR/.env | grep API_PASSWORD | cut -d'=' -f2)"
echo
print_message "Commandes utiles:"
echo "  - Démarrer: sudo systemctl start freqtrade"
echo "  - Arrêter: sudo systemctl stop freqtrade"
echo "  - Redémarrer: sudo systemctl restart freqtrade"
echo "  - Statut: sudo systemctl status freqtrade"
echo "  - Logs: sudo journalctl -u freqtrade -f"
echo
print_message "Scripts disponibles dans $FREQTRADE_DIR:"
echo "  - ./start.sh    : Démarrer FreqTrad"
echo "  - ./stop.sh     : Arrêter FreqTrad"
echo "  - ./restart.sh  : Redémarrer FreqTrad"
echo "  - ./trade.sh    : Mode trading"
echo "  - ./update.sh   : Mettre à jour"
echo
print_warning "N'oubliez pas de:"
echo "  1. Configurer vos clés API dans $FREQTRADE_DIR/.env"
echo "  2. Démarrer le service: sudo systemctl start freqtrade"
echo "  3. Vérifier les logs: sudo journalctl -u freqtrade -f"
echo
print_success "Installation terminée ! 🎉"
