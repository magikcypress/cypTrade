#!/bin/bash

# Script pour tester la stratégie multi-exchange
# Usage: ./test-multi-exchange.sh [binance|hyperliquid|both]

set -e

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

# Vérifier si l'environnement virtuel existe
if [ ! -d "venv" ]; then
    print_error "Environnement virtuel non trouvé. Exécutez d'abord: python3 -m venv venv"
    exit 1
fi

# Activer l'environnement virtuel
source venv/bin/activate

print_message "🧪 Test de la stratégie multi-exchange"
echo ""

# Fonction pour tester un exchange
test_exchange() {
    local exchange=$1
    local config_file=$2
    local strategy=$3
    local timerange=$4
    
    print_message "Test de $exchange avec $strategy..."
    
    # Créer le répertoire de résultats s'il n'existe pas
    mkdir -p user_data/backtest_results
    
    # Lancer le backtest
    freqtrade backtesting \
        --config "$config_file" \
        --strategy "$strategy" \
        --timerange "$timerange" \
        --export trades \
        --export-filename "user_data/backtest_results/backtest-${exchange}-${strategy}-$(date +%Y%m%d-%H%M%S).json"
    
    print_success "Test de $exchange terminé"
}

# Gestion des arguments
case "${1:-both}" in
    "binance")
        print_message "Test de Binance uniquement"
        test_exchange "binance" "config-multi-exchange.json" "MultiExchangeStrategy" "20241201-20241210"
        ;;
    "hyperliquid")
        print_message "Test de Hyperliquid uniquement"
        test_exchange "hyperliquid" "config-hyperliquid-multi.json" "MultiExchangeStrategy" "20250701-20250710"
        ;;
    "both")
        print_message "Test des deux exchanges"
        test_exchange "binance" "config-multi-exchange.json" "MultiExchangeStrategy" "20241201-20241210"
        echo ""
        test_exchange "hyperliquid" "config-hyperliquid-multi.json" "MultiExchangeStrategy" "20250701-20250710"
        ;;
    *)
        print_error "Usage: $0 [binance|hyperliquid|both]"
        print_message "  binance    - Tester Binance uniquement"
        print_message "  hyperliquid - Tester Hyperliquid uniquement"
        print_message "  both       - Tester les deux exchanges (défaut)"
        exit 1
        ;;
esac

echo ""
print_success "🎉 Tests terminés !"
print_message "📊 Résultats disponibles dans: user_data/backtest_results/"
