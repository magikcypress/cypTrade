#!/bin/bash

# Script de diagnostic pour le serveur FreqTrad
# Analyse les problèmes de données et propose des solutions

set -e

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonctions d'affichage
print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Vérifier si on est sur le serveur
check_server() {
    print_header "Vérification du Serveur"
    
    if [[ -f "/etc/debian_version" ]]; then
        print_success "Serveur Debian détecté"
        cat /etc/debian_version
    else
        print_warning "Système non-Debian détecté"
        uname -a
    fi
}

# Vérifier l'environnement Python
check_python() {
    print_header "Vérification de Python"
    
    if [[ -d "venv" ]]; then
        print_success "Environnement virtuel trouvé"
        source venv/bin/activate
        python --version
        pip --version
    else
        print_error "Environnement virtuel manquant"
        return 1
    fi
}

# Vérifier FreqTrad
check_freqtrade() {
    print_header "Vérification de FreqTrad"
    
    if command -v freqtrade &> /dev/null; then
        print_success "FreqTrad installé"
        freqtrade --version
    else
        print_error "FreqTrad non trouvé"
        return 1
    fi
}

# Analyser les données existantes
analyze_data() {
    print_header "Analyse des Données Existantes"
    
    if [[ -d "user_data/data/binance" ]]; then
        print_info "Répertoire de données trouvé"
        
        # Compter les fichiers de données
        local usdt_files=$(find user_data/data/binance -name "*USDT*" | wc -l)
        local usdc_files=$(find user_data/data/binance -name "*USDC*" | wc -l)
        
        print_info "Fichiers USDT: $usdt_files"
        print_info "Fichiers USDC: $usdc_files"
        
        # Analyser les dates des données
        print_info "Analyse des dates des données..."
        
        if [[ $usdt_files -gt 0 ]]; then
            print_info "Données USDT trouvées:"
            find user_data/data/binance -name "*USDT*" -type f | head -5 | while read file; do
                echo "  - $(basename "$file")"
            done
        fi
        
        if [[ $usdc_files -gt 0 ]]; then
            print_info "Données USDC trouvées:"
            find user_data/data/binance -name "*USDC*" -type f | head -5 | while read file; do
                echo "  - $(basename "$file")"
            done
        fi
    else
        print_error "Répertoire de données manquant"
        return 1
    fi
}

# Tester les configurations
test_configs() {
    print_header "Test des Configurations"
    
    # Test config USDT
    if [[ -f "config-usdt.json" ]]; then
        print_info "Test de la configuration USDT..."
        if source venv/bin/activate && freqtrade list-data --config config-usdt.json &> /dev/null; then
            print_success "Configuration USDT valide"
        else
            print_error "Configuration USDT invalide"
        fi
    fi
    
    # Test config USDC
    if [[ -f "config.json" ]]; then
        print_info "Test de la configuration USDC..."
        if source venv/bin/activate && freqtrade list-data --config config.json &> /dev/null; then
            print_success "Configuration USDC valide"
        else
            print_error "Configuration USDC invalide"
        fi
    fi
}

# Nettoyer et télécharger les données
fix_data() {
    print_header "Correction des Données"
    
    print_warning "Cette opération va supprimer les données corrompues"
    read -p "Continuer ? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Nettoyer les données corrompues
        print_info "Suppression des données corrompues..."
        rm -rf user_data/data/binance/*USDT*
        rm -rf user_data/data/binance/*USDC*
        
        # Télécharger les données USDT
        print_info "Téléchargement des données USDT..."
        source venv/bin/activate
        freqtrade download-data --config config-usdt.json --timerange 20240101-20250131
        
        # Télécharger les données USDC
        print_info "Téléchargement des données USDC..."
        freqtrade download-data --config config.json --timerange 20240801-20250131
        
        print_success "Données téléchargées avec succès"
    else
        print_info "Opération annulée"
    fi
}

# Tester les stratégies
test_strategies() {
    print_header "Test des Stratégies"
    
    # Test PowerTowerStrategy avec USDT
    if [[ -f "config-usdt.json" ]]; then
        print_info "Test PowerTowerStrategy avec USDT..."
        if source venv/bin/activate && freqtrade backtesting --config config-usdt.json --strategy PowerTowerStrategy --timerange 20240101-20240131 --max-open-trades 1 --dry-run-wallet 1000 &> /dev/null; then
            print_success "PowerTowerStrategy USDT fonctionne"
        else
            print_error "PowerTowerStrategy USDT échoue"
        fi
    fi
    
    # Test PowerTowerStrategy avec USDC
    if [[ -f "config.json" ]]; then
        print_info "Test PowerTowerStrategy avec USDC..."
        if source venv/bin/activate && freqtrade backtesting --config config.json --strategy PowerTowerStrategy --timerange 20240801-20240831 --max-open-trades 1 --dry-run-wallet 1000 &> /dev/null; then
            print_success "PowerTowerStrategy USDC fonctionne"
        else
            print_error "PowerTowerStrategy USDC échoue"
        fi
    fi
}

# Afficher les recommandations
show_recommendations() {
    print_header "Recommandations"
    
    echo "1. Utilisez la configuration USDC (plus stable)"
    echo "2. Vérifiez que les données sont complètes"
    echo "3. Testez les stratégies avant le trading live"
    echo "4. Surveillez les logs pour les erreurs"
    echo ""
    echo "Commandes utiles:"
    echo "  - ./start-bot.sh (démarrer avec USDC)"
    echo "  - ./diagnose-trading.sh (diagnostic complet)"
    echo "  - tail -f user_data/logs/freqtrade.log (surveiller les logs)"
}

# Menu principal
main() {
    print_header "Diagnostic FreqTrad Serveur"
    
    case "${1:-all}" in
        "server")
            check_server
            ;;
        "python")
            check_python
            ;;
        "freqtrade")
            check_freqtrade
            ;;
        "data")
            analyze_data
            ;;
        "configs")
            test_configs
            ;;
        "fix")
            fix_data
            ;;
        "test")
            test_strategies
            ;;
        "all")
            check_server
            check_python
            check_freqtrade
            analyze_data
            test_configs
            test_strategies
            show_recommendations
            ;;
        *)
            echo "Usage: $0 [server|python|freqtrade|data|configs|fix|test|all]"
            echo ""
            echo "Options:"
            echo "  server   - Vérifier le serveur"
            echo "  python   - Vérifier Python"
            echo "  freqtrade - Vérifier FreqTrad"
            echo "  data     - Analyser les données"
            echo "  configs  - Tester les configurations"
            echo "  fix      - Corriger les données"
            echo "  test     - Tester les stratégies"
            echo "  all      - Diagnostic complet (défaut)"
            ;;
    esac
}

# Exécuter le script
main "$@"
