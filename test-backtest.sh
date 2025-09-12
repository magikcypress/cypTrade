#!/bin/bash

# Script de test rapide de backtesting avec sélection interactive
# Usage: ./test-backtest.sh [strategy] [timerange] [exchange]

set -e

# Configuration par défaut
CONFIG="config.json"
STRATEGY=""
TIMERANGE="20240901-20240910"  # 10 jours récents
TIMEFRAME="5m"
DRY_RUN_WALLET="1000"
EXCHANGE=""

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction d'affichage
print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  Test Rapide de Backtesting${NC}"
    echo -e "${BLUE}================================${NC}"
}

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Fonction d'aide
show_help() {
    echo "Usage: $0 [strategy] [timerange] [exchange]"
    echo ""
    echo "Arguments:"
    echo "  strategy    Nom de la stratégie (interactif si non fourni)"
    echo "  timerange   Période de test (défaut: 20240901-20240910)"
    echo "  exchange    Exchange à utiliser (défaut: interactif)"
    echo ""
    echo "Exemples:"
    echo "  $0                                    # Sélection interactive"
    echo "  $0 TrendFollowingStrategy            # Test avec TrendFollowingStrategy"
    echo "  $0 MeanReversionStrategy 20240901-20240915 # Test sur 15 jours"
    echo "  $0 MultiExchangeStrategy 20240801-20240831 binance # Test sur Binance"
    echo ""
    echo "Périodes recommandées:"
    echo "  - Test rapide: 20240901-20240910 (10 jours)"
    echo "  - Test moyen: 20240801-20240901 (1 mois)"
    echo "  - Test long: 20240701-20240901 (2 mois)"
    echo "  - Test complet: 20240101-20240901 (8 mois)"
    echo ""
    echo "Exchanges disponibles:"
    echo "  - binance     (USDT pairs)"
    echo "  - hyperliquid (USDC pairs)"
}

# Fonction pour lister les stratégies disponibles
list_strategies() {
    local strategies=()
    for file in user_data/strategies/*.py; do
        if [[ -f "$file" ]]; then
            local basename=$(basename "$file" .py)
            strategies+=("$basename")
        fi
    done
    printf '%s\n' "${strategies[@]}"
}

# Fonction de sélection interactive de stratégie
select_strategy() {
    local strategies=($(list_strategies))
    local count=${#strategies[@]}
    
    if [[ $count -eq 0 ]]; then
        print_error "Aucune stratégie trouvée dans user_data/strategies/"
        exit 1
    fi
    
    echo -e "${YELLOW}📋 Stratégies disponibles:${NC}"
    for i in "${!strategies[@]}"; do
        echo "  $((i+1)). ${strategies[i]}"
    done
    echo ""
    
    while true; do
        echo -n -e "${BLUE}Choisissez une stratégie (1-$count): ${NC}"
        read -r choice
        
        if [[ "$choice" =~ ^[0-9]+$ ]] && [[ $choice -ge 1 ]] && [[ $choice -le $count ]]; then
            STRATEGY="${strategies[$((choice-1))]}"
            break
        else
            print_error "Choix invalide. Veuillez entrer un nombre entre 1 et $count"
        fi
    done
}

# Fonction de sélection interactive d'exchange
select_exchange() {
    echo -e "${YELLOW}📋 Exchanges disponibles:${NC}"
    echo "  1. binance     (USDT pairs, config: config-multi-exchange.json)"
    echo "  2. hyperliquid (USDC pairs, config: config-hyperliquid-multi.json)"
    echo ""
    
    while true; do
        echo -n -e "${BLUE}Choisissez un exchange (1-2): ${NC}"
        read -r choice
        
        case $choice in
            1)
                EXCHANGE="binance"
                CONFIG="config-multi-exchange.json"
                break
                ;;
            2)
                EXCHANGE="hyperliquid"
                CONFIG="config-hyperliquid-multi.json"
                break
                ;;
            *)
                print_error "Choix invalide. Veuillez entrer 1 ou 2"
                ;;
        esac
    done
}

# Vérifier les arguments
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    show_help
    exit 0
fi

# Récupérer les arguments
if [[ -n "$1" ]]; then
    STRATEGY="$1"
fi

if [[ -n "$2" ]]; then
    TIMERANGE="$2"
fi

if [[ -n "$3" ]]; then
    EXCHANGE="$3"
    case $EXCHANGE in
        "binance")
            CONFIG="config-multi-exchange.json"
            ;;
        "hyperliquid")
            CONFIG="config-hyperliquid-multi.json"
            ;;
        *)
            print_error "Exchange non supporté: $EXCHANGE"
            print_info "Exchanges supportés: binance, hyperliquid"
            exit 1
            ;;
    esac
fi

print_header

# Sélection interactive si nécessaire
if [[ -z "$STRATEGY" ]]; then
    select_strategy
fi

if [[ -z "$EXCHANGE" ]]; then
    select_exchange
fi

# Vérifications préliminaires
print_info "Vérification de l'environnement..."

# Vérifier que FreqTrad est installé
if ! command -v freqtrade &> /dev/null; then
    print_error "FreqTrad n'est pas installé ou n'est pas dans le PATH"
    print_info "Installez FreqTrad avec: pip install freqtrade"
    exit 1
fi

# Vérifier que la configuration existe
if [[ ! -f "$CONFIG" ]]; then
    print_error "Fichier de configuration '$CONFIG' non trouvé"
    exit 1
fi

# Vérifier que la stratégie existe
STRATEGY_FILE="user_data/strategies/${STRATEGY}.py"
if [[ ! -f "$STRATEGY_FILE" ]]; then
    print_error "Stratégie '$STRATEGY' non trouvée dans $STRATEGY_FILE"
    print_info "Stratégies disponibles:"
    ls -1 user_data/strategies/*.py 2>/dev/null | sed 's/.*\///' | sed 's/\.py$//' | sed 's/^/  - /'
    exit 1
fi

# Vérifier que l'environnement virtuel est activé
if [[ -z "$VIRTUAL_ENV" ]]; then
    print_warning "Environnement virtuel non détecté"
    print_info "Activation recommandée: source venv/bin/activate"
fi

# Déterminer la devise
CURRENCY="USDT"
if [[ "$EXCHANGE" == "hyperliquid" ]]; then
    CURRENCY="USDC"
fi

print_info "Configuration:"
echo "  - Stratégie: $STRATEGY"
echo "  - Exchange: $EXCHANGE"
echo "  - Période: $TIMERANGE"
echo "  - Timeframe: $TIMEFRAME"
echo "  - Config: $CONFIG"
echo "  - Wallet: $DRY_RUN_WALLET ${CURRENCY}"
echo ""

# Vérifier les données disponibles
print_info "Vérification des données disponibles..."
DATA_DIR="user_data/data/$EXCHANGE"

if [[ ! -d "$DATA_DIR" ]]; then
    print_error "Répertoire de données '$DATA_DIR' non trouvé"
    print_info "Téléchargez les données avec:"
    echo "  freqtrade download-data --config $CONFIG --timerange $TIMERANGE --timeframes $TIMEFRAME"
    exit 1
fi

# Compter les fichiers de données
DATA_COUNT=$(find "$DATA_DIR" -name "*${CURRENCY}-${TIMEFRAME}.feather" | wc -l)
if [[ $DATA_COUNT -eq 0 ]]; then
    print_error "Aucune donnée ${CURRENCY} trouvée pour le timeframe $TIMEFRAME"
    print_info "Téléchargez les données avec:"
    echo "  freqtrade download-data --config $CONFIG --timerange $TIMERANGE --timeframes $TIMEFRAME"
    exit 1
fi

print_info "Données trouvées: $DATA_COUNT paires ${CURRENCY}"

# Lancer le backtest
print_info "Lancement du backtest..."
echo ""

# Commande de backtest
freqtrade backtesting \
    --config "$CONFIG" \
    --strategy "$STRATEGY" \
    --timerange "$TIMERANGE" \
    --timeframe "$TIMEFRAME" \
    --max-open-trades 3 \
    --dry-run-wallet "$DRY_RUN_WALLET"

# Vérifier le résultat
if [[ $? -eq 0 ]]; then
    echo ""
    print_info "Backtest terminé avec succès !"
    print_info "Consultez les logs pour plus de détails:"
    echo "  tail -f user_data/logs/freqtrade.log"
else
    print_error "Erreur lors du backtest"
    exit 1
fi
