#!/bin/bash

# Script de vérification de l'espace disque
# Usage: ./check-disk-space.sh

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

print_message "=== Vérification de l'espace disque ==="

# 1. Espace disque total
print_message "Espace disque total:"
df -h /

# 2. Espace utilisé par /tmp
print_message "Espace utilisé par /tmp:"
du -sh /tmp 2>/dev/null || echo "Impossible d'accéder à /tmp"

# 3. Fichiers temporaires dans /tmp
print_message "Fichiers temporaires dans /tmp:"
ls -la /tmp/ | head -10

# 4. Cache pip
print_message "Cache pip:"
if [ -d ~/.cache/pip ]; then
    du -sh ~/.cache/pip
else
    echo "Cache pip non trouvé"
fi

# 5. Espace requis pour FreqTrad
print_message "Espace requis pour FreqTrad:"
echo "  - Environnement virtuel: ~1-2 GB"
echo "  - FreqTrad et dépendances: ~2-3 GB"
echo "  - Données et logs: ~100-500 MB"
echo "  - Total estimé: ~3-5 GB"

# 6. Vérification de l'espace disponible
AVAILABLE_SPACE=$(df / | tail -1 | awk '{print $4}')
REQUIRED_SPACE=5000000  # 5GB en KB

if [ $AVAILABLE_SPACE -gt $REQUIRED_SPACE ]; then
    print_success "Espace disque suffisant ($(($AVAILABLE_SPACE/1024/1024))GB disponible)"
else
    print_warning "Espace disque faible ($(($AVAILABLE_SPACE/1024/1024))GB disponible, 5GB recommandé)"
fi

# 7. Nettoyage des caches (optionnel)
if [ "$1" = "--clean" ]; then
    print_message "Nettoyage des caches..."
    
    # Nettoyer le cache pip
    if command -v pip &> /dev/null; then
        pip cache purge 2>/dev/null || true
        print_success "Cache pip nettoyé"
    fi
    
    # Nettoyer les fichiers temporaires
    sudo find /tmp -name "pip-*" -type d -exec rm -rf {} + 2>/dev/null || true
    sudo find /tmp -name "build-*" -type d -exec rm -rf {} + 2>/dev/null || true
    print_success "Fichiers temporaires nettoyés"
    
    # Afficher l'espace libéré
    print_message "Espace après nettoyage:"
    df -h /
fi

print_success "Vérification terminée !"
