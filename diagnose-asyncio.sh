#!/bin/bash

# Script de diagnostic des erreurs Asyncio
# Usage: ./diagnose-asyncio.sh [options]

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
    echo -e "${PURPLE}=== Diagnostic Asyncio FreqTrad ===${NC}"
}

# Fonction pour analyser les erreurs asyncio
analyze_asyncio_errors() {
    local log_file="user_data/logs/freqtrade.log"
    
    print_message "Analyse des erreurs Asyncio..."
    echo ""
    
    if [ ! -f "$log_file" ]; then
        print_error "Fichier de log non trouvé: $log_file"
        return 1
    fi
    
    # Compter les erreurs asyncio
    local asyncio_errors=$(grep -c "Task was destroyed but it is pending" "$log_file" 2>/dev/null || echo "0")
    echo -e "${CYAN}=== ERREURS ASYNCIO ===${NC}"
    echo "Erreurs asyncio totales: $asyncio_errors"
    
    if [ "$asyncio_errors" -gt 0 ]; then
        print_warning "Erreurs asyncio détectées !"
        
        # Analyser les types d'erreurs
        echo -e "${CYAN}=== TYPES D'ERREURS ===${NC}"
        local ccxt_errors=$(grep -c "ccxt/async_support" "$log_file" 2>/dev/null || echo "0")
        local throttler_errors=$(grep -c "throttler.py" "$log_file" 2>/dev/null || echo "0")
        local exchange_errors=$(grep -c "Exchange.watch_multiple" "$log_file" 2>/dev/null || echo "0")
        
        echo "Erreurs CCXT: $ccxt_errors"
        echo "Erreurs Throttler: $throttler_errors"
        echo "Erreurs Exchange: $exchange_errors"
        
        # Dernières erreurs
        echo -e "${CYAN}=== DERNIÈRES ERREURS ===${NC}"
        grep "Task was destroyed but it is pending" "$log_file" | tail -n 5
        
    else
        print_success "Aucune erreur asyncio détectée"
    fi
}

# Fonction pour vérifier les processus FreqTrad
check_freqtrade_processes() {
    print_message "Vérification des processus FreqTrad..."
    echo ""
    
    local processes=$(pgrep -f freqtrade | wc -l)
    echo -e "${CYAN}=== PROCESSUS FREQTRADE ===${NC}"
    echo "Processus FreqTrad actifs: $processes"
    
    if [ "$processes" -gt 0 ]; then
        print_warning "Processus FreqTrad détectés:"
        pgrep -f freqtrade | xargs ps -p
    else
        print_success "Aucun processus FreqTrad actif"
    fi
}

# Fonction pour nettoyer les processus
cleanup_processes() {
    print_message "Nettoyage des processus FreqTrad..."
    echo ""
    
    local processes=$(pgrep -f freqtrade | wc -l)
    
    if [ "$processes" -gt 0 ]; then
        print_warning "Arrêt des processus FreqTrad..."
        pkill -f freqtrade
        sleep 2
        
        # Vérifier si des processus persistent
        local remaining=$(pgrep -f freqtrade | wc -l)
        if [ "$remaining" -gt 0 ]; then
            print_warning "Arrêt forcé des processus restants..."
            pkill -9 -f freqtrade
            sleep 1
        fi
        
        local final=$(pgrep -f freqtrade | wc -l)
        if [ "$final" -eq 0 ]; then
            print_success "Tous les processus FreqTrad arrêtés"
        else
            print_error "Certains processus persistent"
        fi
    else
        print_success "Aucun processus à nettoyer"
    fi
}

# Fonction pour vérifier la configuration
check_config() {
    print_message "Vérification de la configuration..."
    echo ""
    
    if [ ! -f "config.json" ]; then
        print_error "Fichier de configuration non trouvé"
        return 1
    fi
    
    echo -e "${CYAN}=== CONFIGURATION ===${NC}"
    
    # Vérifier les paramètres critiques
    local dry_run=$(grep -o '"dry_run": [^,]*' config.json | cut -d' ' -f2)
    local max_trades=$(grep -o '"max_open_trades": [^,]*' config.json | cut -d' ' -f2)
    local verbosity=$(grep -A 1 '"verbosity":' config.json | head -n 1 | grep -o '[0-9]\+' || echo "0")
    
    echo "Mode dry run: $dry_run"
    echo "Max trades: $max_trades"
    echo "Verbosity: $verbosity"
    
    # Recommandations
    echo -e "${CYAN}=== RECOMMANDATIONS ===${NC}"
    
    if [ "$verbosity" -gt 1 ]; then
        print_warning "Verbosity élevé peut causer des erreurs asyncio"
        echo "Recommandation: Réduire verbosity à 1 ou 0"
    fi
    
    if [ "$max_trades" -gt 5 ]; then
        print_warning "Max trades élevé peut causer des problèmes de performance"
        echo "Recommandation: Réduire max_open_trades à 3-5"
    fi
}

# Fonction pour redémarrer proprement
restart_freqtrade() {
    local strategy="${1:-SampleStrategy}"
    local mode="${2:-dry-run}"
    
    print_message "Redémarrage propre de FreqTrad..."
    echo ""
    
    # Nettoyer les processus
    cleanup_processes
    
    # Attendre un peu
    sleep 3
    
    # Redémarrer
    print_message "Redémarrage avec stratégie: $strategy, mode: $mode"
    ./start-bot.sh "$strategy" "$mode"
}

# Fonction pour surveiller les erreurs en temps réel
monitor_asyncio() {
    print_message "Surveillance des erreurs asyncio en temps réel..."
    print_message "Appuyez sur Ctrl+C pour arrêter"
    echo ""
    
    local log_file="user_data/logs/freqtrade.log"
    
    if [ ! -f "$log_file" ]; then
        print_error "Fichier de log non trouvé: $log_file"
        return 1
    fi
    
    # Surveiller les erreurs asyncio
    tail -f "$log_file" | grep --color=always -E "asyncio|ERROR|Task.*pending"
}

# Fonction pour afficher l'aide
show_help() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -h, --help           Afficher cette aide"
    echo "  -a, --analyze        Analyser les erreurs asyncio"
    echo "  -c, --check          Vérifier les processus et config"
    echo "  -l, --cleanup        Nettoyer les processus"
    echo "  -r, --restart        Redémarrer proprement"
    echo "  -m, --monitor        Surveiller en temps réel"
    echo ""
    echo "Exemples:"
    echo "  $0 --analyze         # Analyser les erreurs"
    echo "  $0 --cleanup         # Nettoyer les processus"
    echo "  $0 --restart         # Redémarrer proprement"
    echo "  $0 --monitor         # Surveiller en temps réel"
}

# Fonction principale
main() {
    local analyze=false
    local check=false
    local cleanup=false
    local restart=false
    local monitor=false
    local strategy=""
    local mode=""
    
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
            -c|--check)
                check=true
                shift
                ;;
            -l|--cleanup)
                cleanup=true
                shift
                ;;
            -r|--restart)
                restart=true
                if [ $# -gt 1 ] && [[ ! $2 =~ ^- ]]; then
                    strategy="$2"
                    shift
                fi
                if [ $# -gt 1 ] && [[ ! $2 =~ ^- ]]; then
                    mode="$2"
                    shift
                fi
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
        analyze_asyncio_errors
    elif [ "$check" = true ]; then
        check_freqtrade_processes
        echo ""
        check_config
    elif [ "$cleanup" = true ]; then
        cleanup_processes
    elif [ "$restart" = true ]; then
        restart_freqtrade "$strategy" "$mode"
    elif [ "$monitor" = true ]; then
        monitor_asyncio
    else
        # Par défaut, faire une analyse complète
        analyze_asyncio_errors
        echo ""
        check_freqtrade_processes
        echo ""
        check_config
    fi
}

# Exécuter la fonction principale
main "$@"
