#!/bin/bash

# Script de diagnostic des trades FreqTrad
# Usage: ./diagnose-trading.sh [options]

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
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
    echo -e "${PURPLE}=== Diagnostic des Trades FreqTrad ===${NC}"
}

# Fonction pour afficher l'aide
show_help() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Afficher cette aide"
    echo "  -a, --analyze  Analyser les logs récents"
    echo "  -s, --stats    Afficher les statistiques de trading"
    echo "  -t, --test     Tester la stratégie avec des données"
    echo "  -c, --config   Vérifier la configuration"
    echo ""
    echo "Exemples:"
    echo "  $0 --analyze    # Analyser les logs"
    echo "  $0 --stats      # Statistiques de trading"
    echo "  $0 --test       # Tester la stratégie"
}

# Fonction pour analyser les logs
analyze_logs() {
    local log_file="user_data/logs/freqtrade.log"
    
    print_message "Analyse des logs FreqTrad..."
    echo ""
    
    if [ ! -f "$log_file" ]; then
        print_error "Fichier de log non trouvé: $log_file"
        return 1
    fi
    
    # Vérifier les signaux de trading
    echo -e "${CYAN}=== SIGNAUX DE TRADING ===${NC}"
    local buy_signals=$(grep -c "buy signal\|enter_long" "$log_file" 2>/dev/null | tail -n 1 || echo "0")
    local sell_signals=$(grep -c "sell signal\|exit_long" "$log_file" 2>/dev/null | tail -n 1 || echo "0")
    
    # Nettoyer les valeurs (enlever les espaces et nouvelles lignes)
    buy_signals=$(echo "$buy_signals" | tr -d ' \n\r')
    sell_signals=$(echo "$sell_signals" | tr -d ' \n\r')
    
    echo "Signaux d'achat détectés: $buy_signals"
    echo "Signaux de vente détectés: $sell_signals"
    
    if [ "$buy_signals" -eq 0 ] && [ "$sell_signals" -eq 0 ]; then
        print_warning "Aucun signal de trading détecté !"
    else
        print_success "Signaux de trading détectés"
    fi
    
    # Vérifier les ordres créés
    echo -e "${CYAN}=== ORDRES CRÉÉS ===${NC}"
    local orders_created=$(grep -c "Creating.*order\|Order created" "$log_file" 2>/dev/null | tail -n 1 || echo "0")
    
    # Nettoyer la valeur
    orders_created=$(echo "$orders_created" | tr -d ' \n\r')
    
    echo "Ordres créés: $orders_created"
    
    if [ "$orders_created" -eq 0 ]; then
        print_warning "Aucun ordre créé !"
    else
        print_success "Ordres créés avec succès"
    fi
    
    # Vérifier les erreurs
    echo -e "${CYAN}=== ERREURS ===${NC}"
    local errors=$(grep -c "ERROR" "$log_file" 2>/dev/null || echo "0")
    # Nettoyer la valeur (enlever les espaces et nouvelles lignes)
    errors=$(echo "$errors" | tr -d ' \n\r')
    echo "Erreurs totales: $errors"
    
    if [ "$errors" -gt 0 ]; then
        print_warning "Erreurs détectées:"
        grep "ERROR" "$log_file" | tail -n 5
    fi
    
    # Vérifier les avertissements
    echo -e "${CYAN}=== AVERTISSEMENTS ===${NC}"
    local warnings=$(grep -c "WARNING" "$log_file" 2>/dev/null || echo "0")
    # Nettoyer la valeur (enlever les espaces et nouvelles lignes)
    warnings=$(echo "$warnings" | tr -d ' \n\r')
    echo "Avertissements: $warnings"
    
    if [ "$warnings" -gt 0 ]; then
        print_warning "Avertissements détectés:"
        grep "WARNING" "$log_file" | tail -n 5
    fi
}

# Fonction pour afficher les statistiques
show_stats() {
    local log_file="user_data/logs/freqtrade.log"
    
    print_message "Statistiques de trading..."
    echo ""
    
    if [ ! -f "$log_file" ]; then
        print_error "Fichier de log non trouvé: $log_file"
        return 1
    fi
    
    # Statistiques générales
    echo -e "${CYAN}=== STATISTIQUES GÉNÉRALES ===${NC}"
    local total_lines=$(wc -l < "$log_file" 2>/dev/null || echo "0")
    echo "Lignes de log totales: $total_lines"
    
    # Statistiques de trading
    echo -e "${CYAN}=== STATISTIQUES DE TRADING ===${NC}"
    local buy_signals=$(grep -c "buy signal\|enter_long" "$log_file" 2>/dev/null | tail -n 1 || echo "0")
    local sell_signals=$(grep -c "sell signal\|exit_long" "$log_file" 2>/dev/null | tail -n 1 || echo "0")
    local orders_created=$(grep -c "Creating.*order\|Order created" "$log_file" 2>/dev/null | tail -n 1 || echo "0")
    local orders_filled=$(grep -c "Order filled\|Trade executed" "$log_file" 2>/dev/null | tail -n 1 || echo "0")
    
    # Nettoyer les valeurs
    buy_signals=$(echo "$buy_signals" | tr -d ' \n\r')
    sell_signals=$(echo "$sell_signals" | tr -d ' \n\r')
    orders_created=$(echo "$orders_created" | tr -d ' \n\r')
    orders_filled=$(echo "$orders_filled" | tr -d ' \n\r')
    
    echo "Signaux d'achat: $buy_signals"
    echo "Signaux de vente: $sell_signals"
    echo "Ordres créés: $orders_created"
    echo "Ordres exécutés: $orders_filled"
    
    # Calcul du taux de succès
    if [ "$orders_created" -gt 0 ]; then
        local success_rate=$((orders_filled * 100 / orders_created))
        echo "Taux de succès: $success_rate%"
    else
        echo "Taux de succès: N/A (aucun ordre créé)"
    fi
    
    # Dernière activité
    echo -e "${CYAN}=== DERNIÈRE ACTIVITÉ ===${NC}"
    echo "Dernière ligne de log:"
    tail -n 1 "$log_file"
    
    # Temps depuis le dernier signal
    local last_signal=$(grep "buy signal\|sell signal\|enter_long\|exit_long" "$log_file" | tail -n 1)
    if [ -n "$last_signal" ]; then
        echo "Dernier signal: $last_signal"
    else
        print_warning "Aucun signal de trading trouvé"
    fi
}

# Fonction pour tester la stratégie
test_strategy() {
    local strategy="${1:-SampleStrategy}"
    
    print_message "Test de la stratégie: $strategy"
    echo ""
    
    # Vérifier que la stratégie existe
    if [ ! -f "user_data/strategies/${strategy}.py" ]; then
        print_error "Stratégie non trouvée: $strategy"
        return 1
    fi
    
    # Tester la stratégie avec des données
    print_message "Test de la stratégie avec des données historiques..."
    
    source venv/bin/activate
    
    # Exécuter un test de backtesting
    freqtrade backtesting \
        --config config.json \
        --strategy "$strategy" \
        --timerange 20231201-20231231 \
        --max-open-trades 1 \
        --dry-run-wallet 1000
    
    if [ $? -eq 0 ]; then
        print_success "Test de stratégie réussi"
    else
        print_error "Erreur lors du test de stratégie"
    fi
}

# Fonction pour vérifier la configuration
check_config() {
    print_message "Vérification de la configuration..."
    echo ""
    
    # Vérifier le fichier de configuration
    if [ ! -f "config.json" ]; then
        print_error "Fichier de configuration non trouvé: config.json"
        return 1
    fi
    
    # Vérifier les paramètres critiques
    echo -e "${CYAN}=== PARAMÈTRES CRITIQUES ===${NC}"
    
    # Mode dry run
    local dry_run=$(grep -o '"dry_run": [^,]*' config.json | cut -d' ' -f2)
    echo "Mode dry run: $dry_run"
    
    # Max open trades
    local max_trades=$(grep -o '"max_open_trades": [^,]*' config.json | cut -d' ' -f2)
    echo "Max trades ouverts: $max_trades"
    
    # Stake amount
    local stake_amount=$(grep -o '"stake_amount": "[^"]*"' config.json | cut -d'"' -f4)
    echo "Montant par trade: $stake_amount"
    
    # Paires tradées
    local pairs=$(grep -A 10 '"pair_whitelist"' config.json | grep -c '"[^"]*"' || echo "0")
    echo "Nombre de paires: $pairs"
    
    # Vérifier les problèmes potentiels
    echo -e "${CYAN}=== VÉRIFICATIONS ===${NC}"
    
    if [ "$dry_run" = "true" ]; then
        print_warning "Mode dry run activé - Aucun trade réel ne sera exécuté"
    fi
    
    if [ "$max_trades" = "0" ]; then
        print_error "Max trades = 0 - Aucun trade ne sera ouvert !"
    fi
    
    if [ "$stake_amount" = "0" ]; then
        print_error "Stake amount = 0 - Aucun trade ne sera ouvert !"
    fi
    
    if [ "$pairs" -eq 0 ]; then
        print_error "Aucune paire configurée - Aucun trade possible !"
    fi
}

# Fonction pour surveiller en temps réel
monitor_realtime() {
    print_message "Surveillance en temps réel des signaux..."
    print_message "Appuyez sur Ctrl+C pour arrêter"
    echo ""
    
    local log_file="user_data/logs/freqtrade.log"
    
    if [ ! -f "$log_file" ]; then
        print_error "Fichier de log non trouvé: $log_file"
        return 1
    fi
    
    # Surveiller les signaux en temps réel
    tail -f "$log_file" | grep --color=always -E "signal|buy|sell|enter|exit|order|trade"
}

# Fonction principale
main() {
    local analyze=false
    local stats=false
    local test=false
    local config=false
    local monitor=false
    local strategy=""
    
    # Analyser les arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -a|--analyze)
                analyze=true
                shift
                ;;
            -s|--stats)
                stats=true
                shift
                ;;
            -t|--test)
                test=true
                if [ $# -gt 1 ] && [[ ! $2 =~ ^- ]]; then
                    strategy="$2"
                    shift
                fi
                shift
                ;;
            -c|--config)
                config=true
                shift
                ;;
            -m|--monitor)
                monitor=true
                shift
                ;;
            *)
                print_error "Option inconnue: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    print_header
    
    # Exécuter selon les options
    if [ "$analyze" = true ]; then
        analyze_logs
    elif [ "$stats" = true ]; then
        show_stats
    elif [ "$test" = true ]; then
        test_strategy "$strategy"
    elif [ "$config" = true ]; then
        check_config
    elif [ "$monitor" = true ]; then
        monitor_realtime
    else
        # Par défaut, faire une analyse complète
        analyze_logs
        echo ""
        show_stats
        echo ""
        check_config
    fi
}

# Exécuter la fonction principale
main "$@"
