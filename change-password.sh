#!/bin/bash

# Script pour changer le mot de passe FreqTrad
# Usage: ./change-password.sh [nouveau_mot_de_passe]

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

# Vérifier les arguments
if [ $# -eq 0 ]; then
    print_message "Usage: $0 [nouveau_mot_de_passe]"
    print_message "Ou exécutez sans argument pour un mode interactif"
    echo
    read -p "Entrez le nouveau mot de passe: " -s NEW_PASSWORD
    echo
    if [ -z "$NEW_PASSWORD" ]; then
        print_error "Mot de passe vide, annulation"
        exit 1
    fi
else
    NEW_PASSWORD="$1"
fi

print_message "Changement du mot de passe FreqTrad..."

# 1. Changer dans config.json (fichier principal)
if [ -f "config.json" ]; then
    print_message "Mise à jour de config.json..."
    # Sauvegarder l'ancien fichier
    cp config.json config.json.backup
    
    # Changer le mot de passe dans les variables d'environnement
    if grep -q "API_PASSWORD" .env; then
        sed -i "s/API_PASSWORD=.*/API_PASSWORD=$NEW_PASSWORD/" .env
        print_success "config.json mis à jour via .env"
    else
        print_warning "API_PASSWORD non trouvé dans .env"
    fi
else
    print_warning "config.json non trouvé"
fi

# 2. Changer dans config-test.json (fichier de test)
if [ -f "config-test.json" ]; then
    print_message "Mise à jour de config-test.json..."
    # Sauvegarder l'ancien fichier
    cp config-test.json config-test.json.backup
    
    # Changer le mot de passe
    sed -i "s/\"password\": \".*\"/\"password\": \"$NEW_PASSWORD\"/" config-test.json
    print_success "config-test.json mis à jour"
else
    print_warning "config-test.json non trouvé"
fi


# 3. Changer dans .env (si existe)
if [ -f ".env" ]; then
    print_message "Mise à jour de .env..."
    # Sauvegarder l'ancien fichier
    cp .env .env.backup
    
    # Changer le mot de passe
    if grep -q "API_PASSWORD" .env; then
        sed -i "s/API_PASSWORD=.*/API_PASSWORD=$NEW_PASSWORD/" .env
        print_success ".env mis à jour"
    else
        echo "API_PASSWORD=$NEW_PASSWORD" >> .env
        print_success "API_PASSWORD ajouté à .env"
    fi
else
    print_warning ".env non trouvé"
fi

# 4. Redémarrer FreqTrad si en cours d'exécution
if pgrep -f "freqtrade" > /dev/null; then
    print_message "FreqTrad en cours d'exécution, redémarrage nécessaire..."
    
    # Essayer de redémarrer via systemd
    if systemctl is-active --quiet freqtrade 2>/dev/null; then
        print_message "Redémarrage via systemd..."
        sudo systemctl restart freqtrade
        print_success "Service redémarré"
    else
        print_message "Arrêt des processus FreqTrad..."
        pkill -f freqtrade
        sleep 2
        print_message "Redémarrage de FreqTrad..."
        if [ -f "start.sh" ]; then
            ./start.sh &
        else
            print_warning "Script start.sh non trouvé, redémarrez manuellement"
        fi
    fi
else
    print_message "FreqTrad n'est pas en cours d'exécution"
fi

print_success "=== Mot de passe changé avec succès ! ==="
echo
print_message "Nouveau mot de passe: $NEW_PASSWORD"
print_message "Identifiants: admin / $NEW_PASSWORD"
echo
print_message "Fichiers sauvegardés:"
echo "  - config-test.json.backup"
echo "  - config.json.backup"
echo "  - .env.backup"
echo
print_warning "N'oubliez pas de:"
echo "  1. Redémarrer FreqTrad si nécessaire"
echo "  2. Tester la connexion avec le nouveau mot de passe"
echo "  3. Supprimer les fichiers .backup après vérification"
