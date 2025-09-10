#!/bin/bash

# Script pour générer un mot de passe sécurisé pour FreqTrad
# Usage: ./generate-password.sh

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

print_message() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Générer un mot de passe sécurisé
print_message "Génération d'un mot de passe sécurisé..."

# Méthode 1: openssl (recommandée)
if command -v openssl &> /dev/null; then
    PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-16)
    print_success "Mot de passe généré avec openssl"
else
    # Méthode 2: /dev/urandom
    PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9!@#$%^&*' | fold -w 16 | head -n 1)
    print_success "Mot de passe généré avec /dev/urandom"
fi

echo
print_message "=== Mot de Passe Sécurisé Généré ==="
echo "Mot de passe: $PASSWORD"
echo
print_message "Caractéristiques:"
echo "  - Longueur: 16 caractères"
echo "  - Contient: lettres, chiffres, symboles"
echo "  - Sécurisé: généré aléatoirement"
echo
print_message "Pour l'utiliser:"
echo "  ./change-password.sh '$PASSWORD'"
echo
print_message "Ou copiez-collez manuellement dans vos fichiers de configuration"
