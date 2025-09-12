#!/bin/bash

# Script pour tester l'hyperopt avec peu d'epochs

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
CONFIG="config-usdt.json"
STRATEGY="HyperoptWorking"
TIMERANGE="20241201-20250131"
EPOCHS=10
SPACES="buy sell"
TIMEFRAME="5m"

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
    echo -e "\n${BLUE}=== TEST HYPEROPT ===${NC}"
}

# Vérifier que l'environnement virtuel existe
if [ ! -d "venv" ]; then
    print_error "Environnement virtuel 'venv' non trouvé. Veuillez d'abord installer FreqTrad."
    exit 1
fi

# Activer l'environnement virtuel
source venv/bin/activate

print_header "TEST HYPEROPT RAPIDE"
print_message "Stratégie: $STRATEGY"
print_message "Timerange: $TIMERANGE"
print_message "Epochs: $EPOCHS (test rapide)"
print_message "Spaces: $SPACES"
print_message "Timeframe: $TIMEFRAME"

print_warning "Test rapide avec seulement $EPOCHS epochs..."

# Lancer l'hyperopt de test
freqtrade hyperopt \
    --config "$CONFIG" \
    --strategy "$STRATEGY" \
    --timerange "$TIMERANGE" \
    --epochs "$EPOCHS" \
    --spaces buy sell \
    --timeframe "$TIMEFRAME" \
    --max-open-trades 1 \
    --dry-run-wallet 1000 \
    --hyperopt-loss SharpeHyperOptLoss \
    --random-state 42

if [ $? -eq 0 ]; then
    print_success "Test hyperopt terminé avec succès !"
    print_message "Vérifiez les résultats dans user_data/hyperopt_results/"
    print_message "Pour lancer un hyperopt complet, utilisez: ./run-hyperopt.sh"
else
    print_error "Erreur lors du test hyperopt"
    exit 1
fi
