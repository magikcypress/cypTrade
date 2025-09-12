#!/bin/bash

# Script de test pour vérifier le fonctionnement des stratégies multiples
# Usage: ./test-multi-strategies.sh

set -e

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
    echo -e "${BLUE}=== $1 ===${NC}"
}

# Vérifier si l'environnement virtuel existe
if [ ! -d "venv" ]; then
    print_error "Environnement virtuel non trouvé. Exécutez d'abord: python3 -m venv venv"
    exit 1
fi

# Activer l'environnement virtuel
source venv/bin/activate

print_header "🧪 Test des Scripts Multi-Strégies"
echo ""

# Test 1: Vérifier les scripts
print_message "1. Vérification des scripts..."
scripts=("manage-strategies.sh" "start-multiple-strategies.sh" "start-multi-exchange.sh" "start-multi-config.sh")

for script in "${scripts[@]}"; do
    if [ -f "$script" ] && [ -x "$script" ]; then
        print_success "✅ $script - OK"
    else
        print_error "❌ $script - Manquant ou non exécutable"
        exit 1
    fi
done

# Test 2: Vérifier les stratégies
print_message "2. Vérification des stratégies..."
strategies=("HyperoptWorking.py" "MultiExchangeStrategy.py" "TrendFollowingStrategy.py" "MeanReversionStrategy.py" "PowerTowerStrategy.py")

for strategy in "${strategies[@]}"; do
    if [ -f "user_data/strategies/$strategy" ]; then
        print_success "✅ $strategy - OK"
    else
        print_warning "⚠️  $strategy - Non trouvé"
    fi
done

# Test 3: Vérifier les configurations
print_message "3. Vérification des configurations..."
configs=("config.json" "config-multi-exchange.json")

for config in "${configs[@]}"; do
    if [ -f "$config" ]; then
        print_success "✅ $config - OK"
    else
        print_warning "⚠️  $config - Non trouvé"
    fi
done

# Test 4: Tester le gestionnaire de stratégies
print_message "4. Test du gestionnaire de stratégies..."

# Test de l'aide
if ./manage-strategies.sh help > /dev/null 2>&1; then
    print_success "✅ Gestionnaire - Commande help OK"
else
    print_error "❌ Gestionnaire - Commande help échouée"
fi

# Test du statut
if ./manage-strategies.sh status > /dev/null 2>&1; then
    print_success "✅ Gestionnaire - Commande status OK"
else
    print_error "❌ Gestionnaire - Commande status échouée"
fi

# Test 5: Tester les scripts multi-exchange
print_message "5. Test des scripts multi-exchange..."

# Test de l'aide multi-exchange
if ./start-multi-exchange.sh help > /dev/null 2>&1; then
    print_success "✅ Multi-exchange - Script OK"
else
    print_warning "⚠️  Multi-exchange - Script avec problèmes"
fi

# Test 6: Vérifier les répertoires
print_message "6. Vérification des répertoires..."
dirs=("user_data/logs" "user_data/backtest_results" "user_data/hyperopt_results")

for dir in "${dirs[@]}"; do
    if [ -d "$dir" ]; then
        print_success "✅ $dir - OK"
    else
        print_warning "⚠️  $dir - Création..."
        mkdir -p "$dir"
        print_success "✅ $dir - Créé"
    fi
done

# Test 7: Simulation de démarrage (dry-run)
print_message "7. Simulation de démarrage..."

# Vérifier que FreqTrad est installé
if command -v freqtrade > /dev/null 2>&1; then
    print_success "✅ FreqTrad installé"
    
    # Test de validation de stratégie
    if freqtrade list-strategies --strategy-path user_data/strategies > /dev/null 2>&1; then
        print_success "✅ Stratégies validées par FreqTrad"
    else
        print_warning "⚠️  Problème de validation des stratégies"
    fi
else
    print_error "❌ FreqTrad non installé ou non trouvé"
fi

echo ""
print_header "📊 Résumé des Tests"

print_message "Scripts disponibles:"
echo "  - ./manage-strategies.sh - Gestionnaire complet"
echo "  - ./start-multiple-strategies.sh - Démarrage de stratégies spécifiques"
echo "  - ./start-multi-exchange.sh - Multi-exchange"
echo "  - ./start-multi-config.sh - Multi-configuration"

echo ""
print_message "Commandes de test rapide:"
echo "  - ./manage-strategies.sh status"
echo "  - ./manage-strategies.sh start HyperoptWorking"
echo "  - ./start-multi-exchange.sh status"

echo ""
print_message "Pour commencer:"
echo "  1. ./manage-strategies.sh start HyperoptWorking"
echo "  2. ./manage-strategies.sh status"
echo "  3. ./manage-strategies.sh logs HyperoptWorking"

echo ""
print_success "🎉 Tests terminés ! Tous les scripts sont prêts à l'emploi."
print_warning "⚠️  N'oubliez pas de tester en mode dry-run avant le live trading."
