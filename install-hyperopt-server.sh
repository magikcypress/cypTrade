#!/bin/bash

# Script d'installation de HyperoptWorking sur serveur Debian

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

print_header() {
    echo -e "\n${BLUE}=== $1 ===${NC}"
}

# Vérifier que nous sommes sur le serveur
if [ ! -f "config-usdt.json" ]; then
    print_error "Fichier config-usdt.json non trouvé. Assurez-vous d'être dans le bon répertoire."
    exit 1
fi

print_header "INSTALLATION DE HYPEROPTWORKING"

# Vérifier l'environnement virtuel
if [ ! -d "venv" ]; then
    print_error "Environnement virtuel 'venv' non trouvé. Installez d'abord FreqTrad."
    exit 1
fi

# Activer l'environnement virtuel
source venv/bin/activate

# Vérifier que FreqTrad est installé
if ! command -v freqtrade &> /dev/null; then
    print_error "FreqTrad n'est pas installé dans l'environnement virtuel."
    exit 1
fi

print_success "FreqTrad trouvé: $(freqtrade --version)"

# Vérifier que la stratégie existe
if [ ! -f "user_data/strategies/HyperoptWorking.py" ]; then
    print_error "Stratégie HyperoptWorking.py non trouvée."
    exit 1
fi

print_success "Stratégie HyperoptWorking.py trouvée"

# Rendre les scripts exécutables
print_message "Rendu des scripts exécutables..."
chmod +x test-hyperopt.sh run-hyperopt.sh run-full-hyperopt.sh show-hyperopt-results.sh apply-best-params.sh

# Vérifier que la stratégie est reconnue
print_message "Vérification de la stratégie..."
if freqtrade list-strategies | grep -q "HyperoptWorking"; then
    print_success "Stratégie HyperoptWorking reconnue par FreqTrad"
else
    print_error "Stratégie HyperoptWorking non reconnue par FreqTrad"
    exit 1
fi

# Tester la stratégie
print_message "Test de la stratégie..."
if ./test-hyperopt.sh; then
    print_success "Test de la stratégie réussi !"
else
    print_warning "Test de la stratégie échoué, mais l'installation est terminée."
fi

print_header "INSTALLATION TERMINÉE"
print_success "HyperoptWorking est maintenant installé et prêt à utiliser !"
print_message "Commandes disponibles:"
print_message "  ./test-hyperopt.sh          - Test rapide (10 epochs)"
print_message "  ./run-hyperopt.sh           - Hyperopt standard (100 epochs)"
print_message "  ./run-full-hyperopt.sh      - Hyperopt complet (500 epochs)"
print_message "  ./show-hyperopt-results.sh  - Voir les résultats"
print_message "  ./apply-best-params.sh      - Appliquer les meilleurs paramètres"
print_message ""
print_message "Pour lancer un hyperopt complet:"
print_message "  ./run-full-hyperopt.sh"
