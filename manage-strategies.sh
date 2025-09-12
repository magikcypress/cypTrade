#!/bin/bash

# Script de gestion complet pour toutes les stratégies FreqTrad
# Usage: ./manage-strategies.sh [command] [options]

set -e

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
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

print_header() {
    echo -e "${PURPLE}[HEADER]${NC} $1"
}

print_subheader() {
    echo -e "${CYAN}[SUB]${NC} $1"
}

# Vérifier si l'environnement virtuel existe
if [ ! -d "venv" ]; then
    print_error "Environnement virtuel non trouvé. Exécutez d'abord: python3 -m venv venv"
    exit 1
fi

# Activer l'environnement virtuel
source venv/bin/activate

# Créer les répertoires nécessaires
mkdir -p user_data/logs
mkdir -p user_data/backtest_results
mkdir -p user_data/hyperopt_results

# Configuration des stratégies et leurs ports
# Note: Utilisation de fonctions pour simuler les tableaux associatifs sur macOS
get_strategy_port() {
    case "$1" in
        "HyperoptWorking") echo "8080" ;;
        "MultiExchangeStrategy") echo "8081" ;;
        "TrendFollowingStrategy") echo "8082" ;;
        "MeanReversionStrategy") echo "8083" ;;
        "PowerTowerStrategy") echo "8084" ;;
        *) echo "8080" ;;
    esac
}

get_strategy_config() {
    case "$1" in
        "HyperoptWorking") echo "config.json" ;;
        "MultiExchangeStrategy") echo "config-multi-exchange.json" ;;
        "TrendFollowingStrategy") echo "config.json" ;;
        "MeanReversionStrategy") echo "config.json" ;;
        "PowerTowerStrategy") echo "config.json" ;;
        *) echo "config.json" ;;
    esac
}

get_all_strategies() {
    echo "HyperoptWorking MultiExchangeStrategy TrendFollowingStrategy MeanReversionStrategy PowerTowerStrategy"
}

# Fonction pour afficher l'aide
show_help() {
    print_header "🤖 Gestionnaire de Stratégies FreqTrad"
    echo ""
    print_subheader "Commandes disponibles:"
    echo ""
    echo "  📊 STATUS & MONITORING"
    echo "    status                    - Afficher le statut de toutes les stratégies"
    echo "    logs [strategy]          - Afficher les logs d'une stratégie"
    echo "    performance              - Afficher les performances de toutes les stratégies"
    echo "    trades [strategy]        - Afficher les trades d'une stratégie"
    echo ""
    echo "  🚀 DÉMARRAGE & ARRÊT"
    echo "    start [strategy1,strategy2,...] - Démarrer des stratégies spécifiques"
    echo "    start-all                - Démarrer toutes les stratégies"
    echo "    stop [strategy1,strategy2,...]  - Arrêter des stratégies spécifiques"
    echo "    stop-all                 - Arrêter toutes les stratégies"
    echo "    restart [strategy]       - Redémarrer une stratégie"
    echo ""
    echo "  🧪 TESTING & OPTIMIZATION"
    echo "    test [strategy] [timerange]     - Tester une stratégie"
    echo "    test-all [timerange]           - Tester toutes les stratégies"
    echo "    hyperopt [strategy] [epochs]   - Optimiser une stratégie"
    echo "    compare [strategy1,strategy2]  - Comparer deux stratégies"
    echo ""
    echo "  🔧 MAINTENANCE"
    echo "    clean                    - Nettoyer les logs et fichiers temporaires"
    echo "    backup                   - Sauvegarder les configurations"
    echo "    update                   - Mettre à jour les données de marché"
    echo ""
    print_subheader "Exemples d'utilisation:"
    echo "  ./manage-strategies.sh start HyperoptWorking,TrendFollowingStrategy"
    echo "  ./manage-strategies.sh test HyperoptWorking 20241201-20241210"
    echo "  ./manage-strategies.sh logs MultiExchangeStrategy"
    echo "  ./manage-strategies.sh performance"
}

# Fonction pour démarrer une stratégie
start_strategy() {
    local strategy=$1
    local config=$(get_strategy_config "$strategy")
    local port=$(get_strategy_port "$strategy")
    
    if [[ -z "$config" ]]; then
        print_error "Stratégie non reconnue: $strategy"
        return 1
    fi
    
    print_message "Démarrage de $strategy (port: $port)..."
    
    # Créer une configuration temporaire avec le bon port
    local temp_config="config-${strategy}.json"
    cp "$config" "$temp_config"
    
    # Mettre à jour la configuration
    sed -i.bak "s/\"listen_port\": [0-9]*/\"listen_port\": $port/" "$temp_config"
    sed -i.bak "s/\"bot_name\": \".*\"/\"bot_name\": \"cypTrade-${strategy}\"/" "$temp_config"
    sed -i.bak "s/\"logfile\": \".*\"/\"logfile\": \"user_data\/logs\/freqtrade-${strategy}.log\"/" "$temp_config"
    
    # Démarrer FreqTrad
    nohup freqtrade trade \
        --config "$temp_config" \
        --strategy "$strategy" \
        > /dev/null 2>&1 &
    
    local pid=$!
    echo "$pid" > "user_data/logs/${strategy}.pid"
    
    print_success "$strategy démarré (PID: $pid)"
    print_message "Interface: http://localhost:$port"
    
    # Nettoyer
    rm -f "$temp_config" "${temp_config}.bak"
}

# Fonction pour arrêter une stratégie
stop_strategy() {
    local strategy=$1
    local pid_file="user_data/logs/${strategy}.pid"
    
    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            print_message "Arrêt de $strategy (PID: $pid)..."
            kill -TERM "$pid"
            sleep 2
            
            if kill -0 "$pid" 2>/dev/null; then
                print_warning "Arrêt forcé de $strategy..."
                kill -KILL "$pid"
            fi
            
            print_success "$strategy arrêté"
        else
            print_warning "$strategy n'était pas en cours d'exécution"
        fi
        rm -f "$pid_file"
    else
        print_warning "Fichier PID pour $strategy non trouvé"
    fi
}

# Fonction pour afficher le statut
show_status() {
    print_header "📊 Statut des Stratégies"
    echo ""
    
    local running_count=0
    local total_count=0
    
    for strategy in $(get_all_strategies); do
        total_count=$((total_count + 1))
        port=$(get_strategy_port "$strategy")
        
        echo "🤖 $strategy (port: $port):"
        
        if [ -f "user_data/logs/${strategy}.pid" ]; then
            pid=$(cat "user_data/logs/${strategy}.pid")
            if kill -0 "$pid" 2>/dev/null; then
                print_success "  ✅ En cours d'exécution (PID: $pid)"
                print_message "  🌐 Interface: http://127.0.0.1:$port"
                print_message "  📝 Logs: user_data/logs/freqtrade-${strategy}.log"
                running_count=$((running_count + 1))
            else
                print_error "  ❌ Arrêté"
            fi
        else
            print_warning "  ⚠️  Jamais démarré"
        fi
        echo ""
    done
    
    print_subheader "Résumé: $running_count/$total_count stratégies actives"
}

# Fonction pour afficher les logs
show_logs() {
    local strategy=$1
    
    if [[ -z "$strategy" ]]; then
        print_error "Stratégie non spécifiée"
        print_message "Stratégies disponibles: ${!STRATEGY_PORTS[*]}"
        return 1
    fi
    
    local log_file="user_data/logs/freqtrade-${strategy}.log"
    
    if [ -f "$log_file" ]; then
        print_message "Logs de $strategy (dernières 50 lignes):"
        echo ""
        tail -n 50 "$log_file"
    else
        print_warning "Fichier de logs non trouvé: $log_file"
    fi
}

# Fonction pour tester une stratégie
test_strategy() {
    local strategy=$1
    local timerange=${2:-"20241201-20241210"}
    
    if [[ -z "$strategy" ]]; then
        print_error "Stratégie non spécifiée"
        return 1
    fi
    
    local config=$(get_strategy_config "$strategy")
    
    if [[ -z "$config" ]]; then
        print_error "Stratégie non reconnue: $strategy"
        return 1
    fi
    
    print_message "Test de $strategy avec timerange: $timerange"
    
    freqtrade backtesting \
        --config "$config" \
        --strategy "$strategy" \
        --timerange "$timerange" \
        --export trades \
        --export-filename "user_data/backtest_results/backtest-${strategy}-$(date +%Y%m%d-%H%M%S).json"
    
    print_success "Test de $strategy terminé"
}

# Fonction pour afficher les performances
show_performance() {
    print_header "📈 Performances des Stratégies"
    echo ""
    
    for strategy in $(get_all_strategies); do
        echo "🤖 $strategy:"
        
        # Chercher les derniers résultats de backtest
        local latest_result=$(find user_data/backtest_results -name "*${strategy}*" -type f -name "*.json" | sort | tail -1)
        
        if [ -n "$latest_result" ]; then
            print_message "  📊 Dernier backtest: $(basename "$latest_result")"
            
            # Extraire les métriques principales (approximation)
            local total_trades=$(grep -o '"total_trades":[0-9]*' "$latest_result" | cut -d':' -f2 | head -1)
            local profit_pct=$(grep -o '"profit_total":[0-9.-]*' "$latest_result" | cut -d':' -f2 | head -1)
            
            if [ -n "$total_trades" ]; then
                print_message "  📈 Trades: $total_trades"
            fi
            if [ -n "$profit_pct" ]; then
                print_message "  💰 Profit: ${profit_pct}%"
            fi
        else
            print_warning "  ⚠️  Aucun backtest trouvé"
        fi
        echo ""
    done
}

# Fonction pour nettoyer
clean_files() {
    print_message "Nettoyage des fichiers temporaires..."
    
    # Nettoyer les logs anciens (> 7 jours)
    find user_data/logs -name "*.log" -mtime +7 -delete 2>/dev/null || true
    
    # Nettoyer les fichiers temporaires
    rm -f config-*.json.bak 2>/dev/null || true
    rm -f user_data/logs/*.pid 2>/dev/null || true
    
    print_success "Nettoyage terminé"
}

# Fonction pour l'hyperoptimisation
hyperopt_strategy() {
    local strategy=$1
    local epochs=${2:-100}
    
    if [[ -z "$strategy" ]]; then
        print_error "Stratégie non spécifiée pour l'hyperoptimisation"
        return 1
    fi
    
    local config=$(get_strategy_config "$strategy")
    
    if [[ -z "$config" ]]; then
        print_error "Stratégie non reconnue: $strategy"
        return 1
    fi
    
    print_message "Hyperoptimisation de $strategy avec $epochs epochs..."
    
    freqtrade hyperopt \
        --config "$config" \
        --strategy "$strategy" \
        --epochs "$epochs" \
        --timerange "20241201-20250130" \
        --spaces buy sell roi stoploss trailing \
        --hyperopt-loss SharpeHyperOptLoss
    
    print_success "Hyperoptimisation de $strategy terminée"
}

# Fonction pour tester toutes les stratégies
test_all_strategies() {
    local timerange=${1:-"20250101-20250130"}
    
    print_message "Test de toutes les stratégies avec timerange: $timerange"
    
    for strategy in $(get_all_strategies); do
        test_strategy "$strategy" "$timerange"
        echo ""
    done
    
    print_success "Tests de toutes les stratégies terminés"
}

# Fonction pour comparer deux stratégies
compare_strategies() {
    local strategies_input=$1
    
    if [[ -z "$strategies_input" ]]; then
        print_error "Stratégies non spécifiées pour la comparaison"
        print_message "Usage: compare Strategy1,Strategy2"
        return 1
    fi
    
    IFS=',' read -ra STRATEGIES <<< "$strategies_input"
    
    if [ ${#STRATEGIES[@]} -ne 2 ]; then
        print_error "Veuillez spécifier exactement 2 stratégies séparées par une virgule"
        return 1
    fi
    
    local strategy1=${STRATEGIES[0]}
    local strategy2=${STRATEGIES[1]}
    local timerange="20250101-20250130"
    
    print_message "Comparaison de $strategy1 vs $strategy2"
    
    # Tester la première stratégie
    print_subheader "Test de $strategy1..."
    test_strategy "$strategy1" "$timerange"
    
    echo ""
    
    # Tester la deuxième stratégie
    print_subheader "Test de $strategy2..."
    test_strategy "$strategy2" "$timerange"
    
    echo ""
    print_subheader "Résultats de la comparaison:"
    print_message "Consultez les fichiers de résultats dans user_data/backtest_results/"
    print_message "Utilisez 'freqtrade plot-dataframe' pour visualiser les performances"
}

# Fonction pour sauvegarder les configurations
backup_configurations() {
    local backup_dir="backups/$(date +%Y%m%d_%H%M%S)"
    
    print_message "Sauvegarde des configurations dans $backup_dir..."
    
    mkdir -p "$backup_dir"
    
    # Sauvegarder les configurations
    cp config*.json "$backup_dir/" 2>/dev/null || true
    cp user_data/strategies/*.py "$backup_dir/" 2>/dev/null || true
    cp user_data/strategies/*.json "$backup_dir/" 2>/dev/null || true
    
    print_success "Sauvegarde terminée dans $backup_dir"
}

# Fonction pour mettre à jour les données de marché
update_market_data() {
    print_message "Mise à jour des données de marché..."
    
    # Télécharger les données pour Binance
    freqtrade download-data \
        --config config.json \
        --timerange 20250101- \
        --timeframes 1m 5m 15m 1h 4h 1d
    
    print_success "Données de marché mises à jour"
}

# Fonction principale
main() {
    case "${1:-help}" in
        "help"|"")
            show_help
            ;;
        "status")
            show_status
            ;;
        "logs")
            show_logs "$2"
            ;;
        "performance")
            show_performance
            ;;
        "start")
            if [ "$2" = "all" ]; then
                print_message "Démarrage de toutes les stratégies..."
                for strategy in $(get_all_strategies); do
                    start_strategy "$strategy"
                    sleep 2
                done
            else
                IFS=',' read -ra STRATEGIES <<< "$2"
                for strategy in "${STRATEGIES[@]}"; do
                    start_strategy "$strategy"
                    sleep 2
                done
            fi
            ;;
        "stop")
            if [ "$2" = "all" ]; then
                print_message "Arrêt de toutes les stratégies..."
                for strategy in $(get_all_strategies); do
                    stop_strategy "$strategy"
                done
            else
                IFS=',' read -ra STRATEGIES <<< "$2"
                for strategy in "${STRATEGIES[@]}"; do
                    stop_strategy "$strategy"
                done
            fi
            ;;
        "restart")
            if [ -z "$2" ]; then
                print_error "Stratégie non spécifiée pour le redémarrage"
                return 1
            fi
            stop_strategy "$2"
            sleep 3
            start_strategy "$2"
            ;;
        "test")
            test_strategy "$2" "$3"
            ;;
        "clean")
            clean_files
            ;;
        "hyperopt")
            hyperopt_strategy "$2" "$3"
            ;;
        "test-all")
            test_all_strategies "$2"
            ;;
        "compare")
            compare_strategies "$2"
            ;;
        "backup")
            backup_configurations
            ;;
        "update")
            update_market_data
            ;;
        *)
            print_error "Commande non reconnue: $1"
            print_message "Utilisez '$0 help' pour voir les commandes disponibles"
            exit 1
            ;;
    esac
}

# Exécuter la fonction principale
main "$@"
