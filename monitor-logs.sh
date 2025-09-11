#!/bin/bash

# Script de surveillance des logs FreqTrad
# Usage: ./monitor-logs.sh [filter]
# Exemples:
#   ./monitor-logs.sh                    # Tous les logs
#   ./monitor-logs.sh "ERROR"            # Erreurs seulement
#   ./monitor-logs.sh "buy\|sell"        # Signaux de trading
#   ./monitor-logs.sh "heartbeat"        # Heartbeat

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
    echo -e "${PURPLE}=== Surveillance des Logs FreqTrad ===${NC}"
}

# Fonction pour afficher l'aide
show_help() {
    echo "Usage: $0 [filter]"
    echo ""
    echo "Arguments:"
    echo "  filter     Filtre pour les logs (optionnel)"
    echo ""
    echo "Exemples:"
    echo "  $0                    # Tous les logs"
    echo "  $0 ERROR              # Erreurs seulement"
    echo "  $0 'buy|sell'         # Signaux de trading"
    echo "  $0 heartbeat          # Heartbeat"
    echo "  $0 'BTC/USDC'         # Logs pour une paire spécifique"
    echo ""
    echo "Filtres utiles:"
    echo "  ERROR                 # Erreurs"
    echo "  WARNING               # Avertissements"
    echo "  'buy|sell'            # Signaux de trading"
    echo "  heartbeat             # Heartbeat du bot"
    echo "  'BTC/USDC'            # Paire spécifique"
    echo "  'strategy'            # Logs de stratégie"
    echo "  'exchange'            # Logs d'échange"
}

# Fonction pour surveiller les logs
monitor_logs() {
    local filter="$1"
    local log_file="user_data/logs/freqtrade.log"
    
    print_header
    
    # Vérifier que le fichier de log existe
    if [ ! -f "$log_file" ]; then
        print_error "Fichier de log non trouvé: $log_file"
        print_message "Démarrez d'abord FreqTrad avec: ./start-bot.sh"
        exit 1
    fi
    
    print_message "Surveillance des logs FreqTrad..."
    if [ -n "$filter" ]; then
        print_message "Filtre: $filter"
    fi
    print_message "Fichier: $log_file"
    print_message "Appuyez sur Ctrl+C pour arrêter"
    echo ""
    
    # Surveiller les logs avec filtre
    if [ -n "$filter" ]; then
        tail -f "$log_file" | grep --color=always -E "$filter|$"
    else
        tail -f "$log_file"
    fi
}

# Fonction pour analyser les logs récents
analyze_recent_logs() {
    local log_file="user_data/logs/freqtrade.log"
    
    print_message "Analyse des logs récents (dernières 100 lignes)..."
    echo ""
    
    # Erreurs
    echo -e "${RED}=== ERREURS ===${NC}"
    tail -n 100 "$log_file" | grep -i error | tail -n 5
    
    # Avertissements
    echo -e "${YELLOW}=== AVERTISSEMENTS ===${NC}"
    tail -n 100 "$log_file" | grep -i warning | tail -n 5
    
    # Signaux de trading
    echo -e "${GREEN}=== SIGNAUX DE TRADING ===${NC}"
    tail -n 100 "$log_file" | grep -E "buy|sell" | tail -n 5
    
    # Heartbeat
    echo -e "${BLUE}=== HEARTBEAT ===${NC}"
    tail -n 100 "$log_file" | grep heartbeat | tail -n 3
}

# Fonction pour afficher les statistiques
show_stats() {
    local log_file="user_data/logs/freqtrade.log"
    
    print_message "Statistiques des logs..."
    echo ""
    
    # Compter les erreurs
    local error_count=$(grep -c -i error "$log_file" 2>/dev/null || echo "0")
    echo -e "${RED}Erreurs: $error_count${NC}"
    
    # Compter les avertissements
    local warning_count=$(grep -c -i warning "$log_file" 2>/dev/null || echo "0")
    echo -e "${YELLOW}Avertissements: $warning_count${NC}"
    
    # Compter les signaux de trading
    local buy_count=$(grep -c "buy" "$log_file" 2>/dev/null || echo "0")
    local sell_count=$(grep -c "sell" "$log_file" 2>/dev/null || echo "0")
    echo -e "${GREEN}Signaux d'achat: $buy_count${NC}"
    echo -e "${GREEN}Signaux de vente: $sell_count${NC}"
    
    # Dernière activité
    echo -e "${BLUE}Dernière activité:${NC}"
    tail -n 1 "$log_file"
}

# Fonction principale
main() {
    local filter=""
    local analyze=false
    local stats=false
    
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
            *)
                filter="$1"
                shift
                ;;
        esac
    done
    
    # Exécuter selon les options
    if [ "$analyze" = true ]; then
        analyze_recent_logs
    elif [ "$stats" = true ]; then
        show_stats
    else
        monitor_logs "$filter"
    fi
}

# Exécuter la fonction principale
main "$@"
