#!/bin/bash

# Script de test de l'API FreqTrad avec authentification
# Usage: ./test-api-auth.sh

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

# Configuration
API_URL="http://127.0.0.1:8080"
USERNAME="admin"
PASSWORD="NouveauMotDePasse2025!"

print_message "=== Test de l'API FreqTrad avec Authentification ==="

# 1. Obtenir le token d'authentification
print_message "1. Authentification..."
AUTH_RESPONSE=$(curl -s -X POST "$API_URL/api/v1/token/login" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "username=$USERNAME&password=$PASSWORD")

if echo "$AUTH_RESPONSE" | grep -q "access_token"; then
    TOKEN=$(echo "$AUTH_RESPONSE" | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)
    print_success "Authentification réussie"
    echo "Token: ${TOKEN:0:20}..."
else
    print_error "Échec de l'authentification"
    echo "Réponse: $AUTH_RESPONSE"
    exit 1
fi

# 2. Tester les endpoints avec authentification
print_message "2. Test des endpoints avec authentification..."

# Test status
print_message "Test /api/v1/status..."
STATUS_RESPONSE=$(curl -s -H "Authorization: Bearer $TOKEN" "$API_URL/api/v1/status")
if [ $? -eq 0 ]; then
    print_success "✓ Status: $STATUS_RESPONSE"
else
    print_error "✗ Status failed"
fi

# Test version
print_message "Test /api/v1/version..."
VERSION_RESPONSE=$(curl -s -H "Authorization: Bearer $TOKEN" "$API_URL/api/v1/version")
if [ $? -eq 0 ]; then
    print_success "✓ Version: $VERSION_RESPONSE"
else
    print_error "✗ Version failed"
fi

# Test balance
print_message "Test /api/v1/balance..."
BALANCE_RESPONSE=$(curl -s -H "Authorization: Bearer $TOKEN" "$API_URL/api/v1/balance")
if [ $? -eq 0 ]; then
    print_success "✓ Balance: $BALANCE_RESPONSE"
else
    print_warning "⚠ Balance: $BALANCE_RESPONSE"
fi

# Test trades
print_message "Test /api/v1/trades..."
TRADES_RESPONSE=$(curl -s -H "Authorization: Bearer $TOKEN" "$API_URL/api/v1/trades")
if [ $? -eq 0 ]; then
    print_success "✓ Trades: $TRADES_RESPONSE"
else
    print_warning "⚠ Trades: $TRADES_RESPONSE"
fi

# Test performance
print_message "Test /api/v1/performance..."
PERF_RESPONSE=$(curl -s -H "Authorization: Bearer $TOKEN" "$API_URL/api/v1/performance")
if [ $? -eq 0 ]; then
    print_success "✓ Performance: $PERF_RESPONSE"
else
    print_warning "⚠ Performance: $PERF_RESPONSE"
fi

print_message "=== Test terminé ==="
