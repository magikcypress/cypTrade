#!/bin/bash

# Script de démarrage FreqTrad avec choix de stratégie et mode
# Usage: ./start-bot.sh [strategy] [mode]
# Exemples:
#   ./start-bot.sh SampleStrategy dry-run
#   ./start-bot.sh PowerTowerStrategy live
#   ./start-bot.sh (interactif)

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

print_message() {
    echo -e "${BLUE}[INFO]${NC} $1" >&2
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" >&2
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" >&2
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

print_header() {
    echo -e "${PURPLE}=== FreqTrad Bot Starter ===${NC}" >&2
}

# Fonction pour afficher l'aide
show_help() {
    echo "Usage: $0 [strategy] [mode]"
    echo ""
    echo "Arguments:"
    echo "  strategy    Nom de la stratégie (optionnel, interactif si omis)"
    echo "  mode        Mode de trading: dry-run ou live (optionnel, interactif si omis)"
    echo ""
    echo "Exemples:"
    echo "  $0 SampleStrategy dry-run"
    echo "  $0 PowerTowerStrategy live"
    echo "  $0 (mode interactif)"
    echo ""
    echo "Stratégies disponibles:"
    ls user_data/strategies/*.py 2>/dev/null | sed 's/.*\///' | sed 's/\.py$//' | sed 's/^/  - /'
}

# Fonction pour lister les stratégies disponibles
list_strategies() {
    local strategies=()
    for file in user_data/strategies/*.py; do
        if [ -f "$file" ]; then
            local basename=$(basename "$file" .py)
            strategies+=("$basename")
        fi
    done
    echo "${strategies[@]}"
}

# Fonction pour vérifier si une stratégie existe
strategy_exists() {
    local strategy="$1"
    [ -f "user_data/strategies/${strategy}.py" ]
}

# Fonction pour choisir la stratégie de manière interactive
choose_strategy() {
    local strategies=($(list_strategies))
    
    if [ ${#strategies[@]} -eq 0 ]; then
        print_error "Aucune stratégie trouvée dans user_data/strategies/"
        exit 1
    fi
    
    echo ""
    print_message "Stratégies disponibles:"
    for i in "${!strategies[@]}"; do
        echo "  $((i+1)). ${strategies[i]}"
    done
    
    while true; do
        echo ""
        read -p "Choisissez une stratégie (1-${#strategies[@]}): " choice
        
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#strategies[@]} ]; then
            selected_strategy="${strategies[$((choice-1))]}"
            break
        else
            print_error "Choix invalide. Veuillez entrer un nombre entre 1 et ${#strategies[@]}"
        fi
    done
}

# Fonction pour choisir le mode de manière interactive
choose_mode() {
    echo ""
    print_message "Mode de trading:"
    echo "  1. dry-run (simulation - recommandé pour débuter)"
    echo "  2. live (trading réel - ATTENTION!)"
    
    while true; do
        echo ""
        read -p "Choisissez le mode (1-2): " choice
        
        case $choice in
            1)
                selected_mode="dry-run"
                break
                ;;
            2)
                print_warning "ATTENTION: Vous allez démarrer en mode LIVE!"
                read -p "Êtes-vous sûr? (oui/non): " confirm
                if [[ "$confirm" =~ ^(oui|o|yes|y)$ ]]; then
                    selected_mode="live"
                    break
                else
                    print_message "Retour au choix du mode..."
                fi
                ;;
            *)
                print_error "Choix invalide. Veuillez entrer 1 ou 2"
                ;;
        esac
    done
}

# Fonction pour créer la configuration selon le mode
create_config() {
    local strategy="$1"
    local mode="$2"
    local config_file="config-${strategy}-${mode}.json"
    
    print_message "Création de la configuration: $config_file"
    
    # Copier la configuration de base
    cp config.json "$config_file"
    
    # Modifier selon le mode (compatible macOS et Linux)
    if [ "$mode" = "live" ]; then
        # Mode live
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            sed -i '' 's/"dry_run": true/"dry_run": false/' "$config_file"
        else
            # Linux
            sed -i 's/"dry_run": true/"dry_run": false/' "$config_file"
        fi
        print_warning "Mode LIVE activé - Trading réel!"
    else
        # Mode dry-run
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            sed -i '' 's/"dry_run": false/"dry_run": true/' "$config_file"
        else
            # Linux
            sed -i 's/"dry_run": false/"dry_run": true/' "$config_file"
        fi
        print_message "Mode DRY-RUN activé - Simulation uniquement"
    fi
    
    # Vérifier que le fichier a été créé
    if [ ! -f "$config_file" ]; then
        print_error "Erreur lors de la création du fichier de configuration"
        exit 1
    fi
    
    # Retourner le nom du fichier (sans messages de debug)
    echo "$config_file"
}

# Fonction pour démarrer FreqTrad
start_freqtrade() {
    local strategy="$1"
    local mode="$2"
    local config_file="$3"
    
    print_header
    print_message "Démarrage de FreqTrad..."
    print_message "Stratégie: $strategy"
    print_message "Mode: $mode"
    print_message "Configuration: $config_file"
    
    # Vérifier que l'environnement virtuel existe
    if [ ! -d "venv" ]; then
        print_error "Environnement virtuel 'venv' non trouvé"
        print_message "Créez d'abord l'environnement: python3 -m venv venv"
        exit 1
    fi
    
    # Activer l'environnement virtuel
    print_message "Activation de l'environnement virtuel..."
    source venv/bin/activate
    
    # Vérifier que freqtrade est installé
    if ! command -v freqtrade &> /dev/null; then
        print_error "FreqTrad non installé dans l'environnement virtuel"
        print_message "Installez avec: pip install freqtrade"
        exit 1
    fi
    
    # Arrêter les processus FreqTrad existants
    print_message "Arrêt des processus FreqTrad existants..."
    pkill -f freqtrade 2>/dev/null || true
    sleep 2
    
    # Démarrer FreqTrad
    print_message "Démarrage de FreqTrad..."
    print_success "=== FreqTrad démarré! ==="
    print_message "Pour arrêter: Ctrl+C ou pkill -f freqtrade"
    print_message "Logs: tail -f user_data/logs/freqtrade.log"
    
    if [ "$mode" = "live" ]; then
        print_warning "⚠️  MODE LIVE ACTIVÉ - TRADING RÉEL! ⚠️"
    fi
    
    # Démarrer FreqTrad
    freqtrade trade --config "$config_file" --strategy "$strategy"
}

# Fonction principale
main() {
    local selected_strategy=""
    local selected_mode=""
    
    # Vérifier les arguments
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        show_help
        exit 0
    fi
    
    # Si des arguments sont fournis
    if [ $# -ge 1 ]; then
        selected_strategy="$1"
        if [ $# -ge 2 ]; then
            selected_mode="$2"
        fi
    fi
    
    # Vérifier la stratégie si fournie
    if [ -n "$selected_strategy" ] && ! strategy_exists "$selected_strategy"; then
        print_error "Stratégie '$selected_strategy' non trouvée"
        print_message "Stratégies disponibles:"
        list_strategies | sed 's/^/  - /'
        exit 1
    fi
    
    # Mode interactif si des arguments manquent
    if [ -z "$selected_strategy" ]; then
        choose_strategy
    fi
    
    if [ -z "$selected_mode" ]; then
        choose_mode
    fi
    
    # Créer la configuration
    local config_file=$(create_config "$selected_strategy" "$selected_mode")
    
    # Démarrer FreqTrad
    start_freqtrade "$selected_strategy" "$selected_mode" "$config_file"
}

# Exécuter la fonction principale
main "$@"