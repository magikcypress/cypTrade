#!/bin/bash

# Script pour lancer l'hyperopt avec sélection interactive

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration par défaut
CONFIG="config.json"
STRATEGY=""
TIMERANGE="20250101-20250131"
EPOCHS=""
EXCHANGE=""
SPACES="buy sell"
TIMEFRAME="5m"
DRY_RUN_WALLET=1000

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
    echo -e "\n${BLUE}=== $1 ===${NC}"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Fonction pour lister les stratégies disponibles
list_strategies() {
    echo -e "\n${BLUE}Stratégies disponibles :${NC}"
    local strategies=($(ls user_data/strategies/*.py 2>/dev/null | xargs -n 1 basename | sed 's/\.py$//' | grep -v __pycache__))
    
    if [ ${#strategies[@]} -eq 0 ]; then
        print_error "Aucune stratégie trouvée dans user_data/strategies/"
        exit 1
    fi
    
    for i in "${!strategies[@]}"; do
        echo "  $((i+1)). ${strategies[i]}"
    done
}

# Fonction pour sélectionner une stratégie
select_strategy() {
    list_strategies
    echo ""
    read -p "Choisissez une stratégie (numéro) : " choice
    
    local strategies=($(ls user_data/strategies/*.py 2>/dev/null | xargs -n 1 basename | sed 's/\.py$//' | grep -v __pycache__))
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#strategies[@]}" ]; then
        STRATEGY="${strategies[$((choice-1))]}"
        print_success "Stratégie sélectionnée : $STRATEGY"
    else
        print_error "Choix invalide"
        select_strategy
    fi
}

# Fonction pour sélectionner un exchange
select_exchange() {
    echo -e "\n${BLUE}Exchanges disponibles :${NC}"
    echo "  1. binance (USDT)"
    echo "  2. hyperliquid (USDC)"
    echo "  3. default (config.json)"
    echo ""
    read -p "Choisissez un exchange (numéro) : " choice
    
    case $choice in
        1)
            EXCHANGE="binance"
            CONFIG="config-multi-exchange.json"
            ;;
        2)
            EXCHANGE="hyperliquid"
            CONFIG="config-hyperliquid-multi.json"
            ;;
        3)
            EXCHANGE="default"
            CONFIG="config.json"
            ;;
        *)
            print_error "Choix invalide"
            select_exchange
            ;;
    esac
}

# Fonction pour sélectionner le nombre d'epochs
select_epochs() {
    echo -e "\n${BLUE}Options d'epochs :${NC}"
    echo "  1. 50 (test rapide)"
    echo "  2. 100 (standard)"
    echo "  3. 200 (complet)"
    echo "  4. 500 (intensif)"
    echo "  5. Personnalisé"
    echo ""
    read -p "Choisissez le nombre d'epochs (numéro) : " choice
    
    case $choice in
        1) EPOCHS=50 ;;
        2) EPOCHS=100 ;;
        3) EPOCHS=200 ;;
        4) EPOCHS=500 ;;
        5)
            read -p "Entrez le nombre d'epochs : " custom_epochs
            if [[ "$custom_epochs" =~ ^[0-9]+$ ]] && [ "$custom_epochs" -gt 0 ]; then
                EPOCHS="$custom_epochs"
            else
                print_error "Nombre invalide"
                select_epochs
            fi
            ;;
        *)
            print_error "Choix invalide"
            select_epochs
            ;;
    esac
}

# Fonction d'aide
show_help() {
    echo -e "${BLUE}Usage: $0 [OPTIONS]${NC}"
    echo ""
    echo "Options:"
    echo "  -s, --strategy STRATEGY    Stratégie à utiliser"
    echo "  -e, --exchange EXCHANGE    Exchange (binance, hyperliquid, default)"
    echo "  -t, --timerange RANGE      Période de test (ex: 20250101-20250131)"
    echo "  -p, --epochs EPOCHS        Nombre d'epochs"
    echo "  -h, --help                 Afficher cette aide"
    echo ""
    echo "Exemples:"
    echo "  $0                                    # Mode interactif"
    echo "  $0 -s MeanReversionStrategy -e binance -p 100"
    echo "  $0 --strategy TrendFollowingStrategy --timerange 20250101-20250110"
    echo ""
    echo "Exchanges disponibles:"
    echo "  binance     - Binance (USDT) - config-multi-exchange.json"
    echo "  hyperliquid - Hyperliquid (USDC) - config-hyperliquid-multi.json"
    echo "  default     - Configuration par défaut - config.json"
}

# Parser les arguments de ligne de commande
while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--strategy)
            STRATEGY="$2"
            shift 2
            ;;
        -e|--exchange)
            EXCHANGE="$2"
            case $EXCHANGE in
                binance)
                    CONFIG="config-multi-exchange.json"
                    ;;
                hyperliquid)
                    CONFIG="config-hyperliquid-multi.json"
                    ;;
                default)
                    CONFIG="config.json"
                    ;;
                *)
                    print_error "Exchange invalide: $EXCHANGE"
                    show_help
                    exit 1
                    ;;
            esac
            shift 2
            ;;
        -t|--timerange)
            TIMERANGE="$2"
            shift 2
            ;;
        -p|--epochs)
            EPOCHS="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            print_error "Option inconnue: $1"
            show_help
            exit 1
            ;;
    esac
done

# Vérifier que l'environnement virtuel existe
if [ ! -d "venv" ]; then
    print_error "Environnement virtuel 'venv' non trouvé. Veuillez d'abord installer FreqTrad."
    exit 1
fi

# Activer l'environnement virtuel
source venv/bin/activate

# Sélection interactive si nécessaire
if [[ -z "$STRATEGY" ]]; then
    select_strategy
fi

if [[ -z "$EXCHANGE" ]]; then
    select_exchange
fi

if [[ -z "$EPOCHS" ]]; then
    select_epochs
fi

# Déterminer la devise
CURRENCY="USDT"
if [[ "$EXCHANGE" == "hyperliquid" ]]; then
    CURRENCY="USDC"
fi

print_header "LANCEMENT DE L'HYPEROPT"
print_info "Configuration:"
echo "  - Stratégie: $STRATEGY"
echo "  - Exchange: $EXCHANGE"
echo "  - Période: $TIMERANGE"
echo "  - Epochs: $EPOCHS"
echo "  - Timeframe: $TIMEFRAME"
echo "  - Config: $CONFIG"
echo "  - Devise: $CURRENCY"
echo ""

# Vérifier que la stratégie existe
if [ ! -f "user_data/strategies/${STRATEGY}.py" ]; then
    print_error "Stratégie non trouvée: user_data/strategies/${STRATEGY}.py"
    exit 1
fi

# Vérifier que le fichier de config existe
if [ ! -f "$CONFIG" ]; then
    print_error "Fichier de configuration non trouvé: $CONFIG"
    exit 1
fi

# Vérifier les données disponibles
print_info "Vérification des données disponibles..."
DATA_DIR="user_data/data/$EXCHANGE"
if [[ "$EXCHANGE" == "default" ]]; then
    DATA_DIR="user_data/data/binance"
fi

if [ ! -d "$DATA_DIR" ]; then
    print_error "Répertoire de données non trouvé: $DATA_DIR"
    print_info "Veuillez d'abord télécharger les données avec: freqtrade download-data --config $CONFIG"
    exit 1
fi

# Confirmation pour les hyperopts longs
if [ "$EPOCHS" -gt 200 ]; then
    print_warning "Hyperopt long détecté ($EPOCHS epochs). Cela peut prendre plusieurs heures."
    read -p "Continuer ? (y/N): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_info "Annulé par l'utilisateur"
        exit 0
    fi
fi

print_warning "L'hyperopt peut prendre du temps. Appuyez sur Ctrl+C pour arrêter."

# Lancer l'hyperopt
freqtrade hyperopt \
    --config "$CONFIG" \
    --strategy "$STRATEGY" \
    --timerange "$TIMERANGE" \
    --epochs "$EPOCHS" \
    --spaces buy sell \
    --timeframe "$TIMEFRAME" \
    --max-open-trades 1 \
    --dry-run-wallet "$DRY_RUN_WALLET" \
    --hyperopt-loss MultiMetricHyperOptLoss \
    --random-state 42

if [ $? -eq 0 ]; then
    print_success "Hyperopt terminé avec succès !"
    print_info "Résumé:"
    echo "  - Stratégie: $STRATEGY"
    echo "  - Exchange: $EXCHANGE"
    echo "  - Période: $TIMERANGE"
    echo "  - Epochs: $EPOCHS"
    echo "  - Devise: $CURRENCY"
    echo ""
    print_info "Vérifiez les résultats dans user_data/hyperopt_results/"
    print_info "Pour analyser les résultats, utilisez: ./analyze-hyperopt-results.sh latest"
else
    print_error "Erreur lors de l'hyperopt"
    exit 1
fi
