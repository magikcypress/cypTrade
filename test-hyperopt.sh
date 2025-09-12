#!/bin/bash

# Script pour tester l'hyperopt avec peu d'epochs et sélection interactive
# Usage: ./test-hyperopt.sh [strategy] [timerange] [exchange] [epochs]

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration par défaut
CONFIG="config.json"
STRATEGY=""
TIMERANGE="20241201-20250131"
EPOCHS=10
SPACES="buy sell"
TIMEFRAME="5m"
EXCHANGE=""

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
    echo -e "\n${BLUE}=== TEST HYPEROPT RAPIDE ===${NC}"
}

# Fonction d'aide
show_help() {
    echo "Usage: $0 [strategy] [timerange] [exchange] [epochs]"
    echo ""
    echo "Arguments:"
    echo "  strategy    Nom de la stratégie (interactif si non fourni)"
    echo "  timerange   Période de test (défaut: 20241201-20250131)"
    echo "  exchange    Exchange à utiliser (défaut: interactif)"
    echo "  epochs      Nombre d'epochs (défaut: 10)"
    echo ""
    echo "Exemples:"
    echo "  $0                                    # Sélection interactive"
    echo "  $0 TrendFollowingStrategy            # Test avec TrendFollowingStrategy"
    echo "  $0 MeanReversionStrategy 20250101-20250110 # Test sur 10 jours"
    echo "  $0 MultiExchangeStrategy 20250101-20250110 binance 20 # Test sur Binance avec 20 epochs"
    echo ""
    echo "Périodes recommandées:"
    echo "  - Test rapide: 20250101-20250110 (10 jours)"
    echo "  - Test moyen: 20241201-20250101 (1 mois)"
    echo "  - Test long: 20241101-20250101 (2 mois)"
    echo ""
    echo "Exchanges disponibles:"
    echo "  - binance     (USDT pairs)"
    echo "  - hyperliquid (USDC pairs)"
    echo "  - default     (USDT pairs, config par défaut)"
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
    echo "  3. default     (USDT pairs, config: config.json)"
    echo ""
    
    while true; do
        echo -n -e "${BLUE}Choisissez un exchange (1-3): ${NC}"
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
            3)
                EXCHANGE="default"
                CONFIG="config.json"
                break
                ;;
            *)
                print_error "Choix invalide. Veuillez entrer 1, 2 ou 3"
                ;;
        esac
    done
}

# Fonction de sélection du nombre d'epochs
select_epochs() {
    echo -e "${YELLOW}📊 Nombre d'epochs pour le test:${NC}"
    echo "  1. 5 epochs   (très rapide, test basique)"
    echo "  2. 10 epochs  (rapide, test standard)"
    echo "  3. 20 epochs  (moyen, test approfondi)"
    echo "  4. 50 epochs  (long, test complet)"
    echo "  5. Personnalisé"
    echo ""
    
    while true; do
        echo -n -e "${BLUE}Choisissez le nombre d'epochs (1-5): ${NC}"
        read -r choice
        
        case $choice in
            1)
                EPOCHS=5
                break
                ;;
            2)
                EPOCHS=10
                break
                ;;
            3)
                EPOCHS=20
                break
                ;;
            4)
                EPOCHS=50
                break
                ;;
            5)
                while true; do
                    echo -n -e "${BLUE}Entrez le nombre d'epochs (5-1000): ${NC}"
                    read -r custom_epochs
                    if [[ "$custom_epochs" =~ ^[0-9]+$ ]] && [[ $custom_epochs -ge 5 ]] && [[ $custom_epochs -le 1000 ]]; then
                        EPOCHS=$custom_epochs
                        break
                    else
                        print_error "Veuillez entrer un nombre entre 5 et 1000"
                    fi
                done
                break
                ;;
            *)
                print_error "Choix invalide. Veuillez entrer 1, 2, 3, 4 ou 5"
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
        "default")
            CONFIG="config.json"
            ;;
        *)
            print_error "Exchange non supporté: $EXCHANGE"
            print_message "Exchanges supportés: binance, hyperliquid, default"
            exit 1
            ;;
    esac
fi

if [[ -n "$4" ]]; then
    if [[ "$4" =~ ^[0-9]+$ ]] && [[ $4 -ge 5 ]] && [[ $4 -le 1000 ]]; then
        EPOCHS="$4"
    else
        print_error "Nombre d'epochs invalide: $4 (doit être entre 5 et 1000)"
        exit 1
    fi
fi

# Vérifier que l'environnement virtuel existe
if [ ! -d "venv" ]; then
    print_error "Environnement virtuel 'venv' non trouvé. Veuillez d'abord installer FreqTrad."
    exit 1
fi

# Activer l'environnement virtuel
source venv/bin/activate

print_header

# Sélection interactive si nécessaire
if [[ -z "$STRATEGY" ]]; then
    select_strategy
fi

if [[ -z "$EXCHANGE" ]]; then
    select_exchange
fi

# Déterminer la devise
CURRENCY="USDT"
if [[ "$EXCHANGE" == "hyperliquid" ]]; then
    CURRENCY="USDC"
fi

print_message "Configuration:"
echo "  - Stratégie: $STRATEGY"
echo "  - Exchange: $EXCHANGE"
echo "  - Période: $TIMERANGE"
echo "  - Epochs: $EPOCHS (test rapide)"
echo "  - Spaces: $SPACES"
echo "  - Timeframe: $TIMEFRAME"
echo "  - Config: $CONFIG"
echo "  - Devise: $CURRENCY"

print_warning "Test rapide avec seulement $EPOCHS epochs..."

# Vérifier que la stratégie existe
STRATEGY_FILE="user_data/strategies/${STRATEGY}.py"
if [[ ! -f "$STRATEGY_FILE" ]]; then
    print_error "Stratégie '$STRATEGY' non trouvée dans $STRATEGY_FILE"
    print_message "Stratégies disponibles:"
    ls -1 user_data/strategies/*.py 2>/dev/null | sed 's/.*\///' | sed 's/\.py$//' | sed 's/^/  - /'
    exit 1
fi

# Vérifier que la configuration existe
if [[ ! -f "$CONFIG" ]]; then
    print_error "Fichier de configuration '$CONFIG' non trouvé"
    exit 1
fi

# Lancer l'hyperopt de test
print_message "Lancement de l'hyperopt de test..."
echo ""

freqtrade hyperopt \
    --config "$CONFIG" \
    --strategy "$STRATEGY" \
    --timerange "$TIMERANGE" \
    --epochs "$EPOCHS" \
    --spaces buy sell \
    --timeframe "$TIMEFRAME" \
    --max-open-trades 1 \
    --dry-run-wallet 1000 \
    --hyperopt-loss MultiMetricHyperOptLoss \
    --random-state 42

if [ $? -eq 0 ]; then
    echo ""
    print_success "Test hyperopt terminé avec succès !"
    print_message "Résumé du test:"
    echo "  - Stratégie: $STRATEGY"
    echo "  - Exchange: $EXCHANGE"
    echo "  - Période: $TIMERANGE"
    echo "  - Epochs: $EPOCHS"
    echo "  - Devise: $CURRENCY"
    echo ""
    print_message "Vérifiez les résultats dans user_data/hyperopt_results/"
    print_message "Pour lancer un hyperopt complet, utilisez: ./run-hyperopt.sh"
    print_message "Pour analyser les résultats, utilisez: ./analyze-hyperopt-results.sh"
else
    print_error "Erreur lors du test hyperopt"
    exit 1
fi
