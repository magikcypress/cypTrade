#!/bin/bash

# Script de vérification de la compatibilité Python
# Usage: ./check-python.sh

set -e

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

print_message "=== Vérification de la compatibilité Python ==="

# Vérifier la distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    print_message "Distribution détectée: $PRETTY_NAME"
else
    print_warning "Impossible de détecter la distribution"
fi

# Vérifier les versions de Python disponibles
print_message "Vérification des versions de Python disponibles..."

PYTHON_VERSIONS=("3.11" "3.10" "3.9" "3.8")
AVAILABLE_VERSIONS=()

for version in "${PYTHON_VERSIONS[@]}"; do
    if command -v python$version &> /dev/null; then
        AVAILABLE_VERSIONS+=($version)
        print_success "Python $version trouvé"
    else
        print_warning "Python $version non trouvé"
    fi
done

# Vérifier Python3 par défaut
if command -v python3 &> /dev/null; then
    DEFAULT_VERSION=$(python3 --version | cut -d' ' -f2 | cut -d'.' -f1-2)
    print_message "Python3 par défaut: $DEFAULT_VERSION"
else
    print_error "Python3 non trouvé"
    exit 1
fi

# Recommandations
echo
print_message "=== Recommandations ==="

if [ ${#AVAILABLE_VERSIONS[@]} -eq 0 ]; then
    print_error "Aucune version de Python compatible trouvée"
    print_message "Installation recommandée:"
    echo "  sudo apt update"
    echo "  sudo apt install software-properties-common"
    echo "  sudo add-apt-repository ppa:deadsnakes/ppa"
    echo "  sudo apt update"
    echo "  sudo apt install python3.11 python3.11-venv python3.11-dev"
elif [ ${#AVAILABLE_VERSIONS[@]} -eq 1 ]; then
    print_success "Version recommandée: Python ${AVAILABLE_VERSIONS[0]}"
else
    print_success "Versions disponibles: ${AVAILABLE_VERSIONS[*]}"
    print_message "Version recommandée: Python ${AVAILABLE_VERSIONS[0]} (la plus récente)"
fi

# Vérifier les dépendances système
print_message "Vérification des dépendances système..."

REQUIRED_PACKAGES=("git" "curl" "wget" "build-essential" "libffi-dev" "libssl-dev")
MISSING_PACKAGES=()

for package in "${REQUIRED_PACKAGES[@]}"; do
    if dpkg -l | grep -q "^ii  $package "; then
        print_success "$package installé"
    else
        MISSING_PACKAGES+=($package)
        print_warning "$package manquant"
    fi
done

if [ ${#MISSING_PACKAGES[@]} -gt 0 ]; then
    print_message "Packages manquants: ${MISSING_PACKAGES[*]}"
    print_message "Installation recommandée:"
    echo "  sudo apt update"
    echo "  sudo apt install ${MISSING_PACKAGES[*]}"
fi

# Vérifier l'espace disque
print_message "Vérification de l'espace disque..."
AVAILABLE_SPACE=$(df / | tail -1 | awk '{print $4}')
REQUIRED_SPACE=1000000  # 1GB en KB

if [ $AVAILABLE_SPACE -gt $REQUIRED_SPACE ]; then
    print_success "Espace disque suffisant ($(($AVAILABLE_SPACE/1024))MB disponible)"
else
    print_warning "Espace disque faible ($(($AVAILABLE_SPACE/1024))MB disponible, 1GB recommandé)"
fi

# Vérifier la mémoire
print_message "Vérification de la mémoire..."
TOTAL_MEMORY=$(free -m | awk 'NR==2{print $2}')
if [ $TOTAL_MEMORY -gt 1024 ]; then
    print_success "Mémoire suffisante (${TOTAL_MEMORY}MB)"
else
    print_warning "Mémoire faible (${TOTAL_MEMORY}MB, 1GB recommandé)"
fi

echo
print_success "Vérification terminée !"
print_message "Utilisez ./install-freqtrade-universal.sh pour une installation automatique"
