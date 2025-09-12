#!/bin/bash

# Script pour lancer l'hyperopt sur la stratégie HyperoptWorking

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
EPOCHS=100
SPACES="buy sell protection"
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
    echo -e "\n${BLUE}=== $1 ===${NC}"
}

# Vérifier que l'environnement virtuel existe
if [ ! -d "venv" ]; then
    print_error "Environnement virtuel 'venv' non trouvé. Veuillez d'abord installer FreqTrad."
    exit 1
fi

# Activer l'environnement virtuel
source venv/bin/activate

print_header "LANCEMENT DE L'HYPEROPT"
print_message "Stratégie: $STRATEGY"
print_message "Timerange: $TIMERANGE"
print_message "Epochs: $EPOCHS"
print_message "Spaces: $SPACES"
print_message "Timeframe: $TIMEFRAME"

print_warning "L'hyperopt peut prendre du temps. Appuyez sur Ctrl+C pour arrêter."

# Lancer l'hyperopt
freqtrade hyperopt \
    --config "$CONFIG" \
    --strategy "$STRATEGY" \
    --timerange "$TIMERANGE" \
    --epochs "$EPOCHS" \
    --spaces buy sell protection \
    --timeframe "$TIMEFRAME" \
    --max-open-trades 1 \
    --dry-run-wallet 1000 \
    --hyperopt-loss SharpeHyperOptLoss \
    --random-state 42

if [ $? -eq 0 ]; then
    print_success "Hyperopt terminé avec succès !"
    print_message "Vérifiez les résultats dans user_data/hyperopt_results/"
else
    print_error "Erreur lors de l'hyperopt"
    exit 1
fi
