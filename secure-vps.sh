#!/bin/bash

# Script de sécurisation VPS pour FreqTrad
# Usage: ./secure-vps.sh

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
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

print_header() {
    echo -e "${PURPLE}=== Sécurisation VPS FreqTrad ===${NC}"
}

# Fonction pour configurer le firewall
setup_firewall() {
    print_message "Configuration du firewall..."
    
    # Vérifier si ufw est installé
    if ! command -v ufw >/dev/null 2>&1; then
        print_warning "UFW non installé, installation..."
        sudo apt update && sudo apt install -y ufw
    fi
    
    # Réinitialiser le firewall
    print_message "Réinitialisation du firewall..."
    sudo ufw --force reset
    
    # Politique par défaut
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    
    # Ports essentiels
    print_message "Configuration des ports essentiels..."
    sudo ufw allow ssh
    sudo ufw allow 80/tcp   # HTTP
    sudo ufw allow 443/tcp  # HTTPS
    
    # Port FreqTrad (optionnel, pour accès direct)
    read -p "Autoriser l'accès direct au port 8080 FreqTrad ? (y/N): " allow_8080
    if [[ $allow_8080 =~ ^[Yy]$ ]]; then
        sudo ufw allow 8080/tcp
        print_warning "Port 8080 ouvert - Accès direct autorisé"
    else
        print_message "Port 8080 fermé - Accès via proxy uniquement"
    fi
    
    # Activer le firewall
    sudo ufw --force enable
    
    print_success "Firewall configuré"
}

# Fonction pour configurer un proxy Nginx
setup_nginx_proxy() {
    print_message "Configuration du proxy Nginx..."
    
    # Vérifier si Nginx est installé
    if ! command -v nginx >/dev/null 2>&1; then
        print_message "Installation de Nginx..."
        sudo apt update && sudo apt install -y nginx
    fi
    
    # Créer la configuration Nginx (HTTP seulement d'abord)
    print_message "Création de la configuration Nginx (HTTP)..."
    
    sudo tee /etc/nginx/sites-available/freqtrade > /dev/null << 'EOF'
server {
    listen 80;
    server_name exemple.site;
    
    # Headers de sécurité
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    
    # Proxy vers FreqTrad
    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
EOF
    
    # Activer le site
    sudo ln -sf /etc/nginx/sites-available/freqtrade /etc/nginx/sites-enabled/
    sudo rm -f /etc/nginx/sites-enabled/default
    
    # Tester la configuration
    sudo nginx -t
    
    if [ $? -eq 0 ]; then
        sudo systemctl reload nginx
        print_success "Configuration Nginx créée"
    else
        print_error "Erreur dans la configuration Nginx"
        return 1
    fi
}

# Fonction pour installer Let's Encrypt
setup_ssl() {
    print_message "Configuration SSL avec Let's Encrypt..."
    
    # Vérifier si certbot est installé
    if ! command -v certbot >/dev/null 2>&1; then
        print_message "Installation de Certbot..."
        sudo apt install -y certbot python3-certbot-nginx
    fi
    
    # Obtenir le certificat SSL
    print_message "Obtention du certificat SSL..."
    sudo certbot --nginx -d exemple.site --non-interactive --agree-tos --email admin@exemple.site
    
    # Mettre à jour la configuration Nginx avec SSL
    if [ $? -eq 0 ]; then
        print_message "Mise à jour de la configuration Nginx avec SSL..."
        sudo tee /etc/nginx/sites-available/freqtrade > /dev/null << 'EOF'
server {
    listen 80;
    server_name exemple.site;
    
    # Redirection HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl;
    server_name exemple.site;
    
    # Configuration SSL (Let's Encrypt)
    ssl_certificate /etc/letsencrypt/live/exemple.site/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/exemple.site/privkey.pem;
    
    # Configuration SSL sécurisée
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # Headers de sécurité
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    
    # Proxy vers FreqTrad
    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
EOF
        
        # Recharger Nginx
        sudo nginx -t && sudo systemctl reload nginx
    fi
    
    if [ $? -eq 0 ]; then
        print_success "Certificat SSL installé"
        
        # Configurer le renouvellement automatique
        sudo systemctl enable certbot.timer
        print_message "Renouvellement automatique configuré"
    else
        print_error "Erreur lors de l'installation du certificat SSL"
        return 1
    fi
}

# Fonction pour sécuriser FreqTrad
secure_freqtrade() {
    print_message "Sécurisation de FreqTrad..."
    
    # Changer le mot de passe par défaut
    print_message "Génération d'un mot de passe sécurisé..."
    local new_password=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    
    # Mettre à jour le mot de passe dans config.json
    sed -i "s/\"password\": \".*\"/\"password\": \"$new_password\"/" config.json
    
    print_success "Mot de passe FreqTrad changé: $new_password"
    echo "Nouveau mot de passe: $new_password" > freqtrade_password.txt
    print_warning "Mot de passe sauvegardé dans freqtrade_password.txt"
    
    # Changer le nom d'utilisateur
    local new_username="freqtrade_$(openssl rand -hex 4)"
    sed -i "s/\"username\": \".*\"/\"username\": \"$new_username\"/" config.json
    
    print_success "Nom d'utilisateur changé: $new_username"
    echo "Nom d'utilisateur: $new_username" >> freqtrade_password.txt
}

# Fonction pour afficher l'aide
show_help() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -h, --help           Afficher cette aide"
    echo "  -f, --firewall       Configurer le firewall uniquement"
    echo "  -n, --nginx          Configurer Nginx uniquement"
    echo "  -s, --ssl            Installer SSL uniquement"
    echo "  -t, --freqtrade      Sécuriser FreqTrad uniquement"
    echo "  -a, --all            Configuration complète (défaut)"
    echo ""
    echo "Exemples:"
    echo "  $0                   # Configuration complète"
    echo "  $0 --firewall        # Firewall seulement"
    echo "  $0 --ssl             # SSL seulement"
}

# Fonction principale
main() {
    local firewall=false
    local nginx=false
    local ssl=false
    local freqtrade=false
    local all=true
    
    # Analyser les arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -f|--firewall)
                firewall=true
                all=false
                shift
                ;;
            -n|--nginx)
                nginx=true
                all=false
                shift
                ;;
            -s|--ssl)
                ssl=true
                all=false
                shift
                ;;
            -t|--freqtrade)
                freqtrade=true
                all=false
                shift
                ;;
            -a|--all)
                all=true
                shift
                ;;
            *)
                print_error "Option inconnue: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    print_header
    
    if [ "$all" = true ] || [ "$firewall" = true ]; then
        setup_firewall
        echo ""
    fi
    
    if [ "$all" = true ] || [ "$nginx" = true ]; then
        setup_nginx_proxy
        echo ""
    fi
    
    if [ "$all" = true ] || [ "$ssl" = true ]; then
        setup_ssl
        echo ""
    fi
    
    if [ "$all" = true ] || [ "$freqtrade" = true ]; then
        secure_freqtrade
        echo ""
    fi
    
    if [ "$all" = true ]; then
        print_success "=== Configuration de sécurité terminée ==="
        echo ""
        echo "Accès FreqTrad:"
        echo "  - URL: https://exemple.site"
        echo "  - Credentials: voir freqtrade_password.txt"
        echo ""
        echo "Commandes utiles:"
        echo "  - Status: sudo systemctl status nginx"
        echo "  - Logs: sudo journalctl -u nginx -f"
        echo "  - Test SSL: sudo certbot certificates"
    fi
}

# Exécuter la fonction principale
main "$@"
