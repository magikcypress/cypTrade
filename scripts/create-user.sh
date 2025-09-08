#!/bin/bash

# Script de création d'utilisateur pour FreqTrad
# Usage: ./create-user.sh [nom_utilisateur]

set -e

USERNAME=${1:-freqtrade}
HOMEDIR="/home/$USERNAME"

echo "🔧 Création de l'utilisateur $USERNAME pour FreqTrad..."

# Vérifier si l'utilisateur existe déjà
if id "$USERNAME" &>/dev/null; then
    echo "⚠️  L'utilisateur $USERNAME existe déjà"
    exit 1
fi

# Créer l'utilisateur avec répertoire home et shell bash
echo "👤 Création de l'utilisateur..."
sudo useradd -m -s /bin/bash "$USERNAME"

# Ajouter aux groupes nécessaires
echo "🔐 Ajout aux groupes..."
sudo usermod -aG sudo "$USERNAME"
sudo usermod -aG docker "$USERNAME"

# Créer le répertoire .ssh
echo "🔑 Configuration SSH..."
sudo mkdir -p "$HOMEDIR/.ssh"
sudo chown "$USERNAME:$USERNAME" "$HOMEDIR/.ssh"
sudo chmod 700 "$HOMEDIR/.ssh"

# Copier la clé SSH du root si elle existe
if [ -f /root/.ssh/authorized_keys ]; then
    sudo cp /root/.ssh/authorized_keys "$HOMEDIR/.ssh/"
    sudo chown "$USERNAME:$USERNAME" "$HOMEDIR/.ssh/authorized_keys"
    sudo chmod 600 "$HOMEDIR/.ssh/authorized_keys"
    echo "✅ Clé SSH copiée"
fi

# Créer les répertoires FreqTrad
echo "📁 Création des répertoires FreqTrad..."
sudo mkdir -p "$HOMEDIR/freqtrade"
sudo chown "$USERNAME:$USERNAME" "$HOMEDIR/freqtrade"

# Configurer les permissions Docker
echo "🐳 Configuration Docker..."
sudo chmod 666 /var/run/docker.sock 2>/dev/null || true

echo "✅ Utilisateur $USERNAME créé avec succès !"
echo ""
echo "📋 Informations de connexion :"
echo "   Utilisateur: $USERNAME"
echo "   Répertoire: $HOMEDIR"
echo "   Groupes: $(groups $USERNAME)"
echo ""
echo "🔑 Pour définir un mot de passe :"
echo "   sudo passwd $USERNAME"
echo ""
echo "🚀 Pour se connecter :"
echo "   ssh $USERNAME@$(hostname -I | awk '{print $1}')"
