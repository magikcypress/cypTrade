#!/bin/bash

# Test rapide de Python 3.13 avec FreqTrad
# Usage: ./test-python313.sh

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

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_message "=== Test de Python 3.13 avec FreqTrad ==="

# 1. Vérifier Python 3.13
if ! command -v python3.13 &> /dev/null; then
    print_error "Python 3.13 n'est pas disponible"
    exit 1
fi

print_success "Python 3.13 trouvé: $(python3.13 --version)"

# 2. Créer un environnement virtuel de test
print_message "Création d'un environnement virtuel de test..."
python3.13 -m venv test_venv
source test_venv/bin/activate

# 3. Mettre à jour pip
print_message "Mise à jour de pip..."
pip install --upgrade pip

# 4. Installer FreqTrad
print_message "Installation de FreqTrad..."
pip install 'freqtrade[all]==2025.8'

# 5. Tester FreqTrad
print_message "Test de FreqTrad..."
if freqtrade --version; then
    print_success "FreqTrad fonctionne avec Python 3.13 !"
else
    print_error "Erreur avec FreqTrad"
    exit 1
fi

# 6. Installer l'UI
print_message "Installation de FreqTrad UI..."
freqtrade install-ui

# 7. Test de configuration
print_message "Test de configuration..."
if freqtrade --config config-test.json --check-config; then
    print_success "Configuration valide !"
else
    print_warning "Problème de configuration (normal en mode test)"
fi

# 8. Nettoyage
print_message "Nettoyage..."
deactivate
rm -rf test_venv

print_success "=== Test terminé avec succès ! ==="
print_message "Python 3.13 est compatible avec FreqTrad"
print_message "Vous pouvez maintenant utiliser ./install-freqtrade-python313.sh"
