#!/bin/bash

# Script pour démarrer plusieurs stratégies différentes simultanément
# Usage: ./start-multiple-strategies.sh [strategy1,strategy2,...] [stop|status]

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

# Créer le répertoire de logs s'il n'existe pas
mkdir -p user_data/logs

# Configuration des stratégies disponibles
# Note: Utilisation de fonctions pour simuler les tableaux associatifs sur macOS
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

# Ports de base pour l'API
BASE_PORT=8080

# Fonction pour démarrer une stratégie
start_strategy() {
    local strategy_name=$1
    local config_file=$2
    local port=$3
    
    print_message "Démarrage de $strategy_name avec $config_file (port: $port)..."
    
    # Créer une configuration temporaire basée sur config-simple.json
    local temp_config="config-${strategy_name}.json"
    cp "config-simple.json" "$temp_config"
    
    # Mettre à jour la configuration avec des paramètres spécifiques
    python3 -c "
import json
import sys

# Lire le fichier de configuration simple
with open('$temp_config', 'r') as f:
    config = json.load(f)

# Modifier les paramètres spécifiques
config['api_server']['listen_port'] = $port
config['api_server']['enabled'] = True
config['api_server']['listen_ip_address'] = '127.0.0.1'
config['bot_name'] = 'cypTrade-$strategy_name'
config['logfile'] = 'user_data/logs/freqtrade-$strategy_name.log'

# Ajuster les CORS origins pour le bon port
config['api_server']['CORS_origins'] = [
    'http://localhost:$port',
    'http://127.0.0.1:$port'
]

# Écrire le fichier modifié
with open('$temp_config', 'w') as f:
    json.dump(config, f, indent=4)
"
    
    # Démarrer FreqTrad en arrière-plan
    nohup freqtrade trade \
        --config "$temp_config" \
        --strategy "$strategy_name" \
        > "user_data/logs/${strategy_name}.out" 2>&1 &
    
    local pid=$!
    echo "$pid" > "user_data/logs/${strategy_name}.pid"
    
    # Attendre un peu pour voir si le processus démarre correctement
    sleep 3
    
    # Vérifier si le processus est encore en cours
    if kill -0 "$pid" 2>/dev/null; then
        print_success "$strategy_name démarré (PID: $pid, Port: $port)"
        print_message "Interface web: http://localhost:$port"
        print_message "Logs: user_data/logs/freqtrade-${strategy_name}.log"
    else
        print_error "$strategy_name n'a pas pu démarrer"
        print_message "Vérifiez les logs: user_data/logs/${strategy_name}.out"
    fi
}

# Fonction pour arrêter une stratégie
stop_strategy() {
    local strategy_name=$1
    local pid_file="user_data/logs/${strategy_name}.pid"
    
    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            print_message "Arrêt de $strategy_name (PID: $pid)..."
            kill -TERM "$pid"
            sleep 2
            
            # Vérifier si le processus est toujours en cours
            if kill -0 "$pid" 2>/dev/null; then
                print_warning "Arrêt forcé de $strategy_name..."
                kill -KILL "$pid"
            fi
            
            print_success "$strategy_name arrêté"
        else
            print_warning "$strategy_name n'était pas en cours d'exécution"
        fi
        rm -f "$pid_file"
    else
        print_warning "Fichier PID pour $strategy_name non trouvé"
    fi
}

# Fonction pour afficher le statut
show_status() {
    print_message "Statut des stratégies"
    echo ""
    
    for strategy in $(get_all_strategies); do
        echo "🤖 $strategy:"
        if [ -f "user_data/logs/${strategy}.pid" ]; then
            pid=$(cat "user_data/logs/${strategy}.pid")
            if kill -0 "$pid" 2>/dev/null; then
                print_success "  ✅ En cours d'exécution (PID: $pid)"
                # Trouver le port en lisant la configuration
                config_file="config-${strategy}.json"
                if [ -f "$config_file" ]; then
                    port=$(python3 -c "import json; print(json.load(open('$config_file'))['api_server']['listen_port'])" 2>/dev/null)
                    if [ -n "$port" ]; then
                        print_message "  🌐 Interface: http://127.0.0.1:$port"
                    else
                        print_message "  🌐 Interface: Port non détecté"
                    fi
                else
                    print_message "  🌐 Interface: Configuration non trouvée"
                fi
            else
                print_error "  ❌ Arrêté"
            fi
        else
            print_warning "  ⚠️  Fichier PID non trouvé"
        fi
        echo ""
    done
}

# Fonction pour arrêter toutes les stratégies
stop_all() {
    print_message "Arrêt de toutes les stratégies..."
    
    for strategy in $(get_all_strategies); do
        stop_strategy "$strategy"
    done
    
    print_success "Toutes les stratégies ont été arrêtées"
}

# Gestion des arguments
case "${1:-help}" in
    "stop")
        stop_all
        exit 0
        ;;
    "status")
        show_status
        exit 0
        ;;
    "help")
        print_message "Usage: $0 [strategy1,strategy2,...] [stop|status|help]"
        echo ""
        print_message "Stratégies disponibles:"
        for strategy in $(get_all_strategies); do
            echo "  - $strategy"
        done
        echo ""
        print_message "Exemples:"
        print_message "  $0 HyperoptWorking,TrendFollowingStrategy"
        print_message "  $0 MultiExchangeStrategy,MeanReversionStrategy"
        print_message "  $0 stop"
        print_message "  $0 status"
        exit 0
        ;;
    *)
        # Démarrer les stratégies spécifiées
        IFS=',' read -ra STRATEGY_ARRAY <<< "$1"
        
        if [ ${#STRATEGY_ARRAY[@]} -eq 0 ]; then
            print_error "Aucune stratégie spécifiée"
            print_message "Utilisez '$0 help' pour voir les options"
            exit 1
        fi
        
        print_message "🚀 Démarrage de ${#STRATEGY_ARRAY[@]} stratégie(s)"
        echo ""
        
        port_counter=0
        for strategy in "${STRATEGY_ARRAY[@]}"; do
            config=$(get_strategy_config "$strategy")
            if [[ -n "$config" ]]; then
                start_strategy "$strategy" "$config" $((BASE_PORT + port_counter))
                port_counter=$((port_counter + 1))
                sleep 2  # Délai entre les démarrages
            else
                print_error "Stratégie non reconnue: $strategy"
                print_message "Stratégies disponibles: $(get_all_strategies)"
            fi
        done
        
        echo ""
        print_success "🎉 Toutes les stratégies démarrées !"
        echo ""
        print_message "📊 Commandes utiles:"
        print_message "  - Voir le statut: $0 status"
        print_message "  - Arrêter: $0 stop"
        print_message "  - Voir les logs: tail -f user_data/logs/freqtrade-*.log"
        ;;
esac
