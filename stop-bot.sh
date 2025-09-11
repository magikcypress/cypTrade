#!/bin/bash

# Script d'arrêt FreqTrad
# Usage: ./stop-bot.sh [options]

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
    echo -e "${PURPLE}=== FreqTrad Bot Stopper ===${NC}"
}

# Fonction pour afficher l'aide
show_help() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Afficher cette aide"
    echo "  -f, --force    Arrêt forcé (SIGKILL)"
    echo "  -a, --all      Arrêter tous les processus FreqTrad"
    echo "  -s, --status   Afficher le statut des processus"
    echo "  -l, --logs     Afficher les derniers logs"
    echo ""
    echo "Exemples:"
    echo "  $0              # Arrêt normal"
    echo "  $0 --force      # Arrêt forcé"
    echo "  $0 --status     # Voir le statut"
    echo "  $0 --logs       # Voir les logs"
}

# Fonction pour afficher le statut des processus
show_status() {
    print_message "Statut des processus FreqTrad:"
    
    local pids=$(pgrep -f freqtrade)
    
    if [ -z "$pids" ]; then
        print_success "Aucun processus FreqTrad en cours d'exécution"
        return 0
    fi
    
    echo ""
    echo "PID    | Command"
    echo "-------|--------"
    for pid in $pids; do
        local cmd=$(ps -p "$pid" -o comm= 2>/dev/null)
        if [ -n "$cmd" ]; then
            printf "%-6s | %s\n" "$pid" "$cmd"
        fi
    done
    
    echo ""
    print_message "Total: $(echo $pids | wc -w) processus"
}

# Fonction pour afficher les logs
show_logs() {
    local log_file="user_data/logs/freqtrade.log"
    
    if [ ! -f "$log_file" ]; then
        print_warning "Fichier de log non trouvé: $log_file"
        return 1
    fi
    
    print_message "Derniers logs FreqTrad:"
    echo "----------------------------------------"
    tail -n 20 "$log_file"
    echo "----------------------------------------"
}

# Fonction pour arrêter les processus FreqTrad
stop_freqtrade() {
    local force="$1"
    local signal="TERM"
    
    if [ "$force" = "true" ]; then
        signal="KILL"
        print_warning "Arrêt forcé activé (SIGKILL)"
    fi
    
    # Trouver les processus FreqTrad
    local pids=$(pgrep -f freqtrade)
    
    if [ -z "$pids" ]; then
        print_success "Aucun processus FreqTrad en cours d'exécution"
        return 0
    fi
    
    print_message "Arrêt de $(echo $pids | wc -w) processus FreqTrad..."
    
    # Arrêter les processus
    for pid in $pids; do
        if kill -0 "$pid" 2>/dev/null; then
            print_message "Arrêt du processus $pid..."
            kill -$signal "$pid"
            
            # Attendre l'arrêt si ce n'est pas un arrêt forcé
            if [ "$force" = "false" ]; then
                local count=0
                while kill -0 "$pid" 2>/dev/null && [ $count -lt 10 ]; do
                    sleep 1
                    count=$((count + 1))
                done
                
                # Si le processus est encore en vie, forcer l'arrêt
                if kill -0 "$pid" 2>/dev/null; then
                    print_warning "Processus $pid ne répond pas, arrêt forcé..."
                    kill -KILL "$pid" 2>/dev/null
                fi
            fi
        fi
    done
    
    # Vérifier que tous les processus sont arrêtés
    sleep 2
    local remaining=$(pgrep -f freqtrade)
    
    if [ -z "$remaining" ]; then
        print_success "Tous les processus FreqTrad ont été arrêtés"
    else
        print_warning "Certains processus sont encore en cours:"
        for pid in $remaining; do
            echo "  - PID $pid"
        done
        return 1
    fi
}

# Fonction pour nettoyer les fichiers temporaires
cleanup_temp_files() {
    print_message "Nettoyage des fichiers temporaires..."
    
    # Supprimer les fichiers de configuration temporaires
    local temp_configs=$(ls config-*-*.json 2>/dev/null)
    if [ -n "$temp_configs" ]; then
        print_message "Suppression des configurations temporaires..."
        rm -f config-*-*.json
    fi
    
    # Supprimer les fichiers de verrouillage
    local lock_files=$(find . -name "*.lock" 2>/dev/null)
    if [ -n "$lock_files" ]; then
        print_message "Suppression des fichiers de verrouillage..."
        rm -f *.lock
    fi
    
    print_success "Nettoyage terminé"
}

# Fonction pour afficher un résumé
show_summary() {
    echo ""
    print_message "=== Résumé ==="
    print_message "Processus FreqTrad: $(pgrep -f freqtrade | wc -l)"
    print_message "Configuration active: $(ls config-*.json 2>/dev/null | wc -l) fichier(s)"
    print_message "Logs disponibles: $([ -f "user_data/logs/freqtrade.log" ] && echo "Oui" || echo "Non")"
}

# Fonction principale
main() {
    local force="false"
    local show_status_only="false"
    local show_logs_only="false"
    local cleanup="true"
    
    # Analyser les arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -f|--force)
                force="true"
                shift
                ;;
            -a|--all)
                # Arrêter tous les processus (déjà le comportement par défaut)
                shift
                ;;
            -s|--status)
                show_status_only="true"
                shift
                ;;
            -l|--logs)
                show_logs_only="true"
                shift
                ;;
            --no-cleanup)
                cleanup="false"
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
    
    # Afficher le statut seulement
    if [ "$show_status_only" = "true" ]; then
        show_status
        exit 0
    fi
    
    # Afficher les logs seulement
    if [ "$show_logs_only" = "true" ]; then
        show_logs
        exit 0
    fi
    
    # Afficher le statut initial
    show_status
    
    # Arrêter FreqTrad
    if ! stop_freqtrade "$force"; then
        print_error "Erreur lors de l'arrêt de FreqTrad"
        exit 1
    fi
    
    # Nettoyer si demandé
    if [ "$cleanup" = "true" ]; then
        cleanup_temp_files
    fi
    
    # Afficher le résumé
    show_summary
    
    print_success "=== FreqTrad arrêté avec succès ==="
}

# Exécuter la fonction principale
main "$@"