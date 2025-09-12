#!/bin/bash

# Script pour lancer un hyperopt complet avec plus d'epochs

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
EPOCHS=500
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

print_header "HYPEROPT COMPLET"
print_message "Stratégie: $STRATEGY"
print_message "Timerange: $TIMERANGE"
print_message "Epochs: $EPOCHS"
print_message "Spaces: $SPACES"
print_message "Timeframe: $TIMEFRAME"

print_warning "L'hyperopt complet peut prendre plusieurs heures. Appuyez sur Ctrl+C pour arrêter."

# Demander confirmation
read -p "Voulez-vous continuer ? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_message "Annulé."
    exit 0
fi

# Lancer l'hyperopt complet
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
    --random-state 42 \
    --jobs -1

if [ $? -eq 0 ]; then
    print_success "Hyperopt complet terminé avec succès !"
    print_message "Vérifiez les résultats avec: ./show-hyperopt-results.sh"
    print_message "Appliquez les meilleurs paramètres avec: ./apply-best-params.sh"
else
    print_error "Erreur lors de l'hyperopt complet"
    exit 1
fi
