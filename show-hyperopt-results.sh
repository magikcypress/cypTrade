#!/bin/bash

# Script pour afficher les résultats de l'hyperopt

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0;m'

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

# Vérifier que l'environnement virtuel existe
if [ ! -d "venv" ]; then
    print_error "Environnement virtuel 'venv' non trouvé."
    exit 1
fi

# Activer l'environnement virtuel
source venv/bin/activate

print_header "RÉSULTATS DE L'HYPEROPT"

# Vérifier si des résultats existent
if [ ! -d "user_data/hyperopt_results" ]; then
    print_warning "Aucun résultat d'hyperopt trouvé."
    print_message "Lancez d'abord: ./test-hyperopt.sh ou ./run-hyperopt.sh"
    exit 1
fi

# Lister les fichiers de résultats
print_message "Fichiers de résultats disponibles:"
ls -la user_data/hyperopt_results/

echo ""

# Afficher les meilleurs résultats
print_message "Meilleurs résultats:"
freqtrade hyperopt-show --best

echo ""

# Afficher les résultats profitables uniquement
print_message "Résultats profitables:"
if freqtrade hyperopt-show --profitable 2>/dev/null; then
    echo "Résultats profitables trouvés"
else
    echo "Aucun résultat profitable trouvé"
fi

echo ""

# Afficher les 5 meilleurs résultats (il n'y en a que 7 au total)
print_message "Top 5 des meilleurs résultats:"
freqtrade hyperopt-show --best -n 5

print_success "Affichage des résultats terminé !"
