#!/bin/bash

# Script de surveillance des trades FreqTrad
# Usage: ./monitor-trades.sh

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Vérifier si FreqTrad fonctionne
check_freqtrade() {
    if pgrep -f freqtrade > /dev/null; then
        print_success "FreqTrad est en cours d'exécution"
        return 0
    else
        print_error "FreqTrad n'est pas en cours d'exécution"
        return 1
    fi
}

# Analyser les logs pour les trades
analyze_trades() {
    local log_file="user_data/logs/freqtrade.log"
    
    if [[ ! -f "$log_file" ]]; then
        print_error "Fichier de log non trouvé: $log_file"
        return 1
    fi
    
    print_header "Analyse des Trades"
    
    # Compter les signaux
    local buy_signals=$(grep -c "buy signal\|enter_long" "$log_file" 2>/dev/null | tail -n 1 || echo "0")
    local sell_signals=$(grep -c "sell signal\|exit_long" "$log_file" 2>/dev/null | tail -n 1 || echo "0")
    local orders_created=$(grep -c "Creating.*order\|Order created" "$log_file" 2>/dev/null | tail -n 1 || echo "0")
    local orders_filled=$(grep -c "Order filled\|Trade completed" "$log_file" 2>/dev/null | tail -n 1 || echo "0")
    
    # Nettoyer les valeurs
    buy_signals=$(echo "$buy_signals" | tr -d ' \n\r')
    sell_signals=$(echo "$sell_signals" | tr -d ' \n\r')
    orders_created=$(echo "$orders_created" | tr -d ' \n\r')
    orders_filled=$(echo "$orders_filled" | tr -d ' \n\r')
    
    echo "Signaux d'achat: $buy_signals"
    echo "Signaux de vente: $sell_signals"
    echo "Ordres créés: $orders_created"
    echo "Ordres exécutés: $orders_filled"
    
    # Analyser les erreurs
    local errors=$(grep -c "ERROR\|Exception" "$log_file" 2>/dev/null | tail -n 1 || echo "0")
    local warnings=$(grep -c "WARNING" "$log_file" 2>/dev/null | tail -n 1 || echo "0")
    
    errors=$(echo "$errors" | tr -d ' \n\r')
    warnings=$(echo "$warnings" | tr -d ' \n\r')
    
    echo "Erreurs: $errors"
    echo "Avertissements: $warnings"
    
    # Dernière activité
    echo ""
    print_header "Dernière Activité"
    tail -n 5 "$log_file"
}

# Surveiller en temps réel
monitor_realtime() {
    local log_file="user_data/logs/freqtrade.log"
    
    if [[ ! -f "$log_file" ]]; then
        print_error "Fichier de log non trouvé: $log_file"
        return 1
    fi
    
    print_header "Surveillance en Temps Réel"
    print_info "Appuyez sur Ctrl+C pour arrêter"
    
    tail -f "$log_file" | grep -E "(buy signal|sell signal|Order|Trade|ERROR|WARNING)"
}

# Menu principal
main() {
    case "${1:-status}" in
        "status")
            check_freqtrade
            analyze_trades
            ;;
        "monitor")
            check_freqtrade
            monitor_realtime
            ;;
        "trades")
            analyze_trades
            ;;
        *)
            echo "Usage: $0 [status|monitor|trades]"
            echo ""
            echo "Options:"
            echo "  status  - Afficher le statut et analyser les trades (défaut)"
            echo "  monitor - Surveiller en temps réel"
            echo "  trades  - Analyser uniquement les trades"
            ;;
    esac
}

# Exécuter le script
main "$@"
