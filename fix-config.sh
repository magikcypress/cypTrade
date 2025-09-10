#!/bin/bash

# Script pour corriger les configurations FreqTrad
# Usage: ./fix-config.sh

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

print_message "=== Correction des Configurations FreqTrad ==="

# 1. Vérifier et corriger config.json
print_message "1. Correction de config.json..."
if [ -f "config.json" ]; then
    # Sauvegarder l'ancien fichier
    cp config.json config.json.backup
    
    # Ajouter candle_type_def si manquant
    if ! grep -q "candle_type_def" config.json; then
        # Ajouter avant la dernière accolade
        sed -i '$i\    "candle_type_def": "spot",' config.json
        # Supprimer la virgule de la ligne précédente si nécessaire
        sed -i 's/"process_throttle_secs": 5/"process_throttle_secs": 5/' config.json
        print_success "candle_type_def ajouté à config.json"
    else
        print_message "candle_type_def déjà présent dans config.json"
    fi
else
    print_warning "config.json non trouvé"
fi

# 2. Vérifier et corriger config-webserver.json
print_message "2. Correction de config-webserver.json..."
if [ -f "config-webserver.json" ]; then
    # Sauvegarder l'ancien fichier
    cp config-webserver.json config-webserver.json.backup
    
    # Ajouter candle_type_def si manquant
    if ! grep -q "candle_type_def" config-webserver.json; then
        # Ajouter avant la dernière accolade
        sed -i '$i\    "candle_type_def": "spot",' config-webserver.json
        print_success "candle_type_def ajouté à config-webserver.json"
    else
        print_message "candle_type_def déjà présent dans config-webserver.json"
    fi
else
    print_warning "config-webserver.json non trouvé"
fi

# 3. Vérifier et corriger config-test.json
print_message "3. Correction de config-test.json..."
if [ -f "config-test.json" ]; then
    # Sauvegarder l'ancien fichier
    cp config-test.json config-test.json.backup
    
    # Ajouter candle_type_def si manquant
    if ! grep -q "candle_type_def" config-test.json; then
        # Ajouter avant la dernière accolade
        sed -i '$i\    "candle_type_def": "spot"' config-test.json
        print_success "candle_type_def ajouté à config-test.json"
    else
        print_message "candle_type_def déjà présent dans config-test.json"
    fi
else
    print_warning "config-test.json non trouvé"
fi

# 4. Ajouter d'autres configurations manquantes
print_message "4. Ajout d'autres configurations manquantes..."

# Fonction pour ajouter une configuration si elle manque
add_config_if_missing() {
    local file="$1"
    local key="$2"
    local value="$3"
    
    if [ -f "$file" ] && ! grep -q "\"$key\"" "$file"; then
        # Ajouter avant la dernière accolade
        sed -i "\$i\    \"$key\": $value," "$file"
        print_success "$key ajouté à $file"
    fi
}

# Ajouter des configurations communes
add_config_if_missing "config.json" "candle_type_def" "\"spot\""
add_config_if_missing "config-webserver.json" "candle_type_def" "\"spot\""
add_config_if_missing "config-test.json" "candle_type_def" "\"spot\""

# 5. Redémarrer FreqTrad si nécessaire
if pgrep -f freqtrade > /dev/null; then
    print_message "5. Redémarrage de FreqTrad..."
    pkill -f freqtrade
    sleep 2
    
    if [ -f "start-webserver.sh" ]; then
        ./start-webserver.sh &
        print_success "FreqTrad redémarré"
    else
        print_warning "Script start-webserver.sh non trouvé, redémarrez manuellement"
    fi
else
    print_message "5. FreqTrad n'est pas en cours d'exécution"
fi

print_success "=== Correction terminée ! ==="
echo
print_message "Configurations corrigées:"
echo "  - candle_type_def: spot"
echo "  - Fichiers sauvegardés avec extension .backup"
echo
print_message "Si FreqTrad était en cours d'exécution, il a été redémarré"
print_message "Vérifiez les logs avec: ./logs.sh"
