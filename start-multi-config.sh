#!/bin/bash

# Script pour démarrer FreqTrad avec plusieurs configurations
# Usage: ./start-multi-config.sh [config_name]

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

print_message "🤖 Démarrage de FreqTrad avec configuration multi-stratégie"
echo ""

# Fonction pour créer une configuration
create_config() {
    local config_name=$1
    local strategy=$2
    local pairs=$3
    local max_trades=$4
    local port=$5
    
    local config_file="config-${config_name}.json"
    
    print_message "Création de la configuration: $config_name"
    
    cat > "$config_file" << EOF
{
    "max_open_trades": $max_trades,
    "stake_currency": "USDT",
    "stake_amount": "unlimited",
    "tradable_balance_ratio": 0.99,
    "fiat_display_currency": "USD",
    "dry_run": true,
    "dry_run_wallet": 1000,
    "cancel_open_orders_on_exit": false,
    "trading_mode": "spot",
    "margin_mode": "",
    "unfilledtimeout": {
        "entry": 10,
        "exit": 10,
        "exit_timeout_count": 0,
        "unit": "minutes"
    },
    "entry_pricing": {
        "price_side": "same",
        "use_order_book": true,
        "order_book_top": 1,
        "price_last_balance": 0.0,
        "check_depth_of_market": {
            "enabled": false,
            "bids_to_ask_delta": 1
        }
    },
    "exit_pricing": {
        "price_side": "same",
        "use_order_book": true,
        "order_book_top": 1
    },
    "exchange": {
        "name": "binance",
        "key": "\${BINANCE_API_KEY}",
        "secret": "\${BINANCE_SECRET}",
        "ccxt_config": {},
        "ccxt_async_config": {},
        "pair_whitelist": $pairs,
        "pair_blacklist": [
            "BNB/BTC",
            "BNB/ETH"
        ]
    },
    "pairlists": [
        {
            "method": "StaticPairList"
        }
    ],
    "edge": {
        "enabled": false,
        "process_throttle_secs": 5,
        "calculate_since_number_of_days": 7,
        "allowed_risk": 0.01,
        "stoploss_range_min": -0.01,
        "stoploss_range_max": -0.1,
        "stoploss_range_step": -0.01,
        "minimum_winrate": 0.60,
        "minimum_expectancy": 0.20,
        "min_trade_number": 10,
        "max_trade_duration_minute": 1440,
        "remove_pumps": false
    },
    "telegram": {
        "enabled": false
    },
    "api_server": {
        "enabled": true,
        "listen_ip_address": "127.0.0.1",
        "listen_port": $port,
        "verbosity": "error",
        "enable_openapi": false,
        "jwt_secret": "\${JWT_SECRET}",
        "CORS_origins": [],
        "username": "\${API_USERNAME}",
        "password": "\${API_PASSWORD}"
    },
    "bot_name": "cypTrade-$config_name",
    "initial_state": "running",
    "force_entry_enable": false,
    "internals": {
        "process_throttle_secs": 5
    }
}
EOF

    print_success "Configuration créée: $config_file"
}

# Fonction pour démarrer FreqTrad
start_freqtrade() {
    local config_name=$1
    local strategy=$2
    local config_file="config-${config_name}.json"
    local log_file="user_data/logs/freqtrade-${config_name}.log"
    
    print_message "Démarrage de FreqTrad avec $config_name..."
    
    # Créer le répertoire de logs s'il n'existe pas
    mkdir -p user_data/logs
    
    # Démarrer FreqTrad
    freqtrade trade \
        --config "$config_file" \
        --strategy "$strategy" \
        --logfile "$log_file"
}

# Configuration par défaut si aucun argument
if [ -z "$1" ]; then
    print_message "Configuration par défaut: multi-strategy"
    config_name="multi-strategy"
    strategy="MultiConfigStrategy"
    pairs='["BTC/USDT", "ETH/USDT", "BNB/USDT", "ADA/USDT", "SOL/USDT", "DOT/USDT", "LINK/USDT", "MATIC/USDT", "AVAX/USDT", "XRP/USDT", "DOGE/USDT", "SHIB/USDT"]'
    max_trades=10
    port=8080
else
    case "$1" in
        "conservative")
            config_name="conservative"
            strategy="HyperoptWorking"
            pairs='["BTC/USDT", "ETH/USDT", "BNB/USDT"]'
            max_trades=3
            port=8080
            ;;
        "moderate")
            config_name="moderate"
            strategy="PowerTowerStrategy"
            pairs='["ADA/USDT", "SOL/USDT", "DOT/USDT", "LINK/USDT"]'
            max_trades=5
            port=8081
            ;;
        "aggressive")
            config_name="aggressive"
            strategy="HyperoptOptimized"
            pairs='["DOGE/USDT", "SHIB/USDT", "PEPE/USDT"]'
            max_trades=2
            port=8082
            ;;
        "multi")
            config_name="multi-strategy"
            strategy="MultiConfigStrategy"
            pairs='["BTC/USDT", "ETH/USDT", "BNB/USDT", "ADA/USDT", "SOL/USDT", "DOT/USDT", "LINK/USDT", "MATIC/USDT", "AVAX/USDT", "XRP/USDT", "DOGE/USDT", "SHIB/USDT"]'
            max_trades=10
            port=8080
            ;;
        *)
            print_error "Configuration non reconnue: $1"
            print_message "Configurations disponibles: conservative, moderate, aggressive, multi"
            exit 1
            ;;
    esac
fi

# Créer la configuration
create_config "$config_name" "$strategy" "$pairs" "$max_trades" "$port"

# Démarrer FreqTrad
start_freqtrade "$config_name" "$strategy"
