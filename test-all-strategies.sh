#!/bin/bash

# Script pour tester toutes les stratégies et identifier celles à supprimer

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
CONFIG="config-usdt.json"
TIMERANGE="20241201-20250131"
MAX_TRADES=1
WALLET=1000

# Fichiers de résultats
GOOD_STRATEGIES="good_strategies.txt"
BAD_STRATEGIES="bad_strategies.txt"
NO_TRADES_STRATEGIES="no_trades_strategies.txt"
ERROR_STRATEGIES="error_strategies.txt"

# Initialiser les fichiers
> "$GOOD_STRATEGIES"
> "$BAD_STRATEGIES"
> "$NO_TRADES_STRATEGIES"
> "$ERROR_STRATEGIES"

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

# Fonction pour tester une stratégie
test_strategy() {
    local strategy=$1
    print_message "Test de la stratégie: $strategy"
    
    # Exécuter le backtest
    result=$(source venv/bin/activate && freqtrade backtesting \
        --config "$CONFIG" \
        --strategy "$strategy" \
        --timerange "$TIMERANGE" \
        --max-open-trades "$MAX_TRADES" \
        --dry-run-wallet "$WALLET" 2>&1)
    
    # Analyser les résultats
    if echo "$result" | grep -q "Fatal exception\|ERROR"; then
        print_error "Erreur dans $strategy"
        echo "$strategy" >> "$ERROR_STRATEGIES"
        return 1
    elif echo "$result" | grep -q "No trades made"; then
        print_warning "Aucun trade pour $strategy"
        echo "$strategy" >> "$NO_TRADES_STRATEGIES"
        return 2
    elif echo "$result" | grep -q "TOTAL.*Trades.*0"; then
        print_warning "Aucun trade pour $strategy"
        echo "$strategy" >> "$NO_TRADES_STRATEGIES"
        return 2
    else
        # Extraire le nombre de trades et le profit
        trades=$(echo "$result" | grep "TOTAL.*Trades" | head -1 | awk '{print $2}')
        profit=$(echo "$result" | grep "TOTAL.*Trades" | head -1 | awk '{print $4}')
        
        if [ -n "$trades" ] && [ "$trades" -gt 0 ]; then
            if echo "$profit" | grep -q "-"; then
                print_warning "Stratégie perdante: $strategy (Trades: $trades, Profit: $profit)"
                echo "$strategy" >> "$BAD_STRATEGIES"
            else
                print_success "Stratégie profitable: $strategy (Trades: $trades, Profit: $profit)"
                echo "$strategy" >> "$GOOD_STRATEGIES"
            fi
        else
            print_warning "Aucun trade pour $strategy"
            echo "$strategy" >> "$NO_TRADES_STRATEGIES"
        fi
        return 0
    fi
}

# Lister toutes les stratégies
strategies=(
    "BalancedStrategy"
    "BandtasticStrategy"
    "BollingerSimple"
    "EMACrossSimple"
    "MACDSimple"
    "MarketAdaptedStrategy"
    "MomentumStrategy"
    "MultiMAStrategy"
    "PowerTowerStrategy"
    "RSISimple"
    "ScalpingStrategy"
    "SimpleStrategy"
    "SimpleTestStrategy"
    "SuccessStrategy"
    "Supertrend"
    "UltraSimpleAdapted"
    "UltraSimpleStrategy"
    "VolatileMarketStrategy"
)

print_message "Début des tests de toutes les stratégies..."

# Tester chaque stratégie
for strategy in "${strategies[@]}"; do
    test_strategy "$strategy"
    echo "---"
done

# Afficher les résultats
print_message "Résultats des tests:"
echo ""

if [ -s "$GOOD_STRATEGIES" ]; then
    print_success "Stratégies profitables:"
    cat "$GOOD_STRATEGIES"
    echo ""
fi

if [ -s "$BAD_STRATEGIES" ]; then
    print_warning "Stratégies perdantes:"
    cat "$BAD_STRATEGIES"
    echo ""
fi

if [ -s "$NO_TRADES_STRATEGIES" ]; then
    print_warning "Stratégies sans trades:"
    cat "$NO_TRADES_STRATEGIES"
    echo ""
fi

if [ -s "$ERROR_STRATEGIES" ]; then
    print_error "Stratégies avec erreurs:"
    cat "$ERROR_STRATEGIES"
    echo ""
fi

print_message "Tests terminés. Vérifiez les fichiers de résultats."
