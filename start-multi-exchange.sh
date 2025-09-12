#!/bin/bash

# Script pour démarrer FreqTrad avec configuration multi-exchange
# Usage: ./start-multi-exchange.sh [binance|hyperliquid|both]

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

print_message "🌐 Démarrage de FreqTrad avec configuration multi-exchange"
echo ""

# Fonction pour démarrer un exchange
start_exchange() {
    local exchange=$1
    local config_file=$2
    local strategy=$3
    local log_file=$4
    local port=$5
    
    print_message "Démarrage de $exchange avec $strategy..."
    
    # Créer le répertoire de logs s'il n'existe pas
    mkdir -p user_data/logs
    
    # Démarrer FreqTrad en arrière-plan
    nohup freqtrade trade \
        --config "$config_file" \
        --strategy "$strategy" \
        --logfile "$log_file" \
        > /dev/null 2>&1 &
    
    local pid=$!
    echo "$pid" > "user_data/logs/${exchange}.pid"
    
    print_success "$exchange démarré (PID: $pid)"
    print_message "Logs: $log_file"
    print_message "Interface web: http://localhost:$port"
}

# Fonction pour arrêter un exchange
stop_exchange() {
    local exchange=$1
    local pid_file="user_data/logs/${exchange}.pid"
    
    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            print_message "Arrêt de $exchange (PID: $pid)..."
            kill -TERM "$pid"
            sleep 2
            
            # Vérifier si le processus est toujours en cours
            if kill -0 "$pid" 2>/dev/null; then
                print_warning "Arrêt forcé de $exchange..."
                kill -KILL "$pid"
            fi
            
            print_success "$exchange arrêté"
        else
            print_warning "$exchange n'était pas en cours d'exécution"
        fi
        rm -f "$pid_file"
    else
        print_warning "Fichier PID pour $exchange non trouvé"
    fi
}

# Gestion des arguments
case "${1:-both}" in
    "binance")
        print_message "Démarrage de Binance uniquement"
        start_exchange "binance" "config-multi-exchange.json" "MultiExchangeStrategy" "user_data/logs/freqtrade-binance-multi.log" 8080
        ;;
    "hyperliquid")
        print_message "Démarrage de Hyperliquid uniquement"
        start_exchange "hyperliquid" "config-hyperliquid-multi.json" "MultiExchangeStrategy" "user_data/logs/freqtrade-hyperliquid-multi.log" 8081
        ;;
    "both")
        print_message "Démarrage des deux exchanges"
        start_exchange "binance" "config-multi-exchange.json" "MultiExchangeStrategy" "user_data/logs/freqtrade-binance-multi.log" 8080
        sleep 3
        start_exchange "hyperliquid" "config-hyperliquid-multi.json" "MultiExchangeStrategy" "user_data/logs/freqtrade-hyperliquid-multi.log" 8081
        ;;
    "stop")
        print_message "Arrêt de tous les exchanges"
        stop_exchange "binance"
        stop_exchange "hyperliquid"
        exit 0
        ;;
    "status")
        print_message "Statut des exchanges"
        echo ""
        echo "🤖 Binance:"
        if [ -f "user_data/logs/binance.pid" ]; then
            pid=$(cat "user_data/logs/binance.pid")
            if kill -0 "$pid" 2>/dev/null; then
                print_success "  ✅ En cours d'exécution (PID: $pid)"
                print_message "  🌐 Interface: http://127.0.0.1:8080"
            else
                print_error "  ❌ Arrêté"
            fi
        else
            print_warning "  ⚠️  Fichier PID non trouvé"
        fi
        
        echo ""
        echo "🤖 Hyperliquid:"
        if [ -f "user_data/logs/hyperliquid.pid" ]; then
            pid=$(cat "user_data/logs/hyperliquid.pid")
            if kill -0 "$pid" 2>/dev/null; then
                print_success "  ✅ En cours d'exécution (PID: $pid)"
                print_message "  🌐 Interface: http://127.0.0.1:8081"
            else
                print_error "  ❌ Arrêté"
            fi
        else
            print_warning "  ⚠️  Fichier PID non trouvé"
        fi
        exit 0
        ;;
    *)
        print_error "Usage: $0 [binance|hyperliquid|both|stop|status]"
        print_message "  binance    - Démarrer Binance uniquement"
        print_message "  hyperliquid - Démarrer Hyperliquid uniquement"
        print_message "  both       - Démarrer les deux exchanges (défaut)"
        print_message "  stop       - Arrêter tous les exchanges"
        print_message "  status     - Voir le statut des exchanges"
        exit 1
        ;;
esac

echo ""
print_success "🎉 Configuration multi-exchange démarrée !"
echo ""
print_message "📊 Interfaces web disponibles:"
print_message "  - Binance: http://127.0.0.1:8080"
print_message "  - Hyperliquid: http://127.0.0.1:8081"
echo ""
print_message "📋 Commandes utiles:"
print_message "  - Voir le statut: ./start-multi-exchange.sh status"
print_message "  - Arrêter: ./start-multi-exchange.sh stop"
print_message "  - Voir les logs: tail -f user_data/logs/freqtrade-*-multi.log"
