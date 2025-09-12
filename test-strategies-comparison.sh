#!/bin/bash

# Script de comparaison des stratégies Trend Following vs Mean Reversion
# Usage: ./test-strategies-comparison.sh [binance|hyperliquid|both]

set -e

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
EXCHANGE=${1:-both}
TIMERANGE="20250101-20250130"
STRATEGIES=("TrendFollowingStrategy" "MeanReversionStrategy")

echo -e "${BLUE}🚀 Comparaison des Stratégies de Trading${NC}"
echo -e "${BLUE}=======================================${NC}"
echo ""

# Fonction pour tester une stratégie sur un exchange
test_strategy() {
    local strategy=$1
    local exchange=$2
    local config_file=""
    
    case $exchange in
        "binance")
            config_file="config-multi-exchange.json"
            ;;
        "hyperliquid")
            config_file="config-hyperliquid-multi.json"
            ;;
        *)
            echo -e "${RED}❌ Exchange non supporté: $exchange${NC}"
            return 1
            ;;
    esac
    
    echo -e "${YELLOW}📊 Test de $strategy sur $exchange...${NC}"
    
    # Backtest
    freqtrade backtesting \
        --config $config_file \
        --strategy $strategy \
        --timerange $TIMERANGE \
        --export trades \
        --export-filename "user_data/backtest_results/${strategy}_${exchange}_${TIMERANGE//-/_}" \
        --breakdown month \
        --cache none \
        --logfile "user_data/logs/backtest_${strategy}_${exchange}.log" \
        --verbose
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Backtest $strategy sur $exchange terminé avec succès${NC}"
    else
        echo -e "${RED}❌ Erreur lors du backtest $strategy sur $exchange${NC}"
        return 1
    fi
}

# Fonction pour analyser les résultats
analyze_results() {
    local exchange=$1
    
    echo -e "${PURPLE}📈 Analyse des résultats pour $exchange...${NC}"
    echo ""
    
    # Lister les fichiers de résultats
    local results_dir="user_data/backtest_results"
    local files=($(ls -t ${results_dir}/*${exchange}*_${TIMERANGE//-/_}*.json 2>/dev/null || true))
    
    if [ ${#files[@]} -eq 0 ]; then
        echo -e "${RED}❌ Aucun fichier de résultats trouvé pour $exchange${NC}"
        return 1
    fi
    
    echo -e "${CYAN}📋 Fichiers de résultats trouvés:${NC}"
    for file in "${files[@]}"; do
        echo "  - $(basename $file)"
    done
    echo ""
    
    # Analyser chaque stratégie
    for strategy in "${STRATEGIES[@]}"; do
        local strategy_files=($(ls -t ${results_dir}/*${strategy}*${exchange}*_${TIMERANGE//-/_}*.json 2>/dev/null || true))
        
        if [ ${#strategy_files[@]} -gt 0 ]; then
            echo -e "${BLUE}🔍 Analyse de $strategy sur $exchange:${NC}"
            ./analyze-backtest-results.sh latest "${strategy_files[0]}"
            echo ""
        fi
    done
}

# Fonction principale
main() {
    echo -e "${CYAN}📅 Période de test: $TIMERANGE${NC}"
    echo -e "${CYAN}🎯 Exchange(s): $EXCHANGE${NC}"
    echo ""
    
    # Créer le répertoire de logs s'il n'existe pas
    mkdir -p user_data/logs
    mkdir -p user_data/backtest_results
    
    case $EXCHANGE in
        "binance")
            echo -e "${GREEN}🎯 Test sur Binance uniquement${NC}"
            for strategy in "${STRATEGIES[@]}"; do
                test_strategy $strategy "binance"
            done
            analyze_results "binance"
            ;;
        "hyperliquid")
            echo -e "${GREEN}🎯 Test sur Hyperliquid uniquement${NC}"
            for strategy in "${STRATEGIES[@]}"; do
                test_strategy $strategy "hyperliquid"
            done
            analyze_results "hyperliquid"
            ;;
        "both")
            echo -e "${GREEN}🎯 Test sur les deux exchanges${NC}"
            for exchange in "binance" "hyperliquid"; do
                echo -e "${YELLOW}🔄 Test sur $exchange...${NC}"
                for strategy in "${STRATEGIES[@]}"; do
                    test_strategy $strategy $exchange
                done
                analyze_results $exchange
                echo ""
            done
            ;;
        *)
            echo -e "${RED}❌ Usage: $0 [binance|hyperliquid|both]${NC}"
            echo -e "${YELLOW}   binance    - Test sur Binance uniquement${NC}"
            echo -e "${YELLOW}   hyperliquid - Test sur Hyperliquid uniquement${NC}"
            echo -e "${YELLOW}   both       - Test sur les deux exchanges (défaut)${NC}"
            exit 1
            ;;
    esac
    
    echo -e "${GREEN}🎉 Comparaison des stratégies terminée !${NC}"
    echo ""
    echo -e "${CYAN}📊 Résultats disponibles dans: user_data/backtest_results/${NC}"
    echo -e "${CYAN}📝 Logs disponibles dans: user_data/logs/${NC}"
}

# Exécution
main "$@"
