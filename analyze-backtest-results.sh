#!/bin/bash

# Script d'analyse des résultats de backtest FreqTrad
# Auteur: Assistant IA
# Description: Analyse les fichiers JSON de résultats de backtest et affiche les métriques importantes

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Fonction pour afficher les messages
print_header() {
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================================${NC}"
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
    echo -e "${CYAN}ℹ️  $1${NC}"
}

# Fonction pour analyser un fichier de backtest (JSON ou ZIP)
analyze_backtest_file() {
    local file="$1"
    local filename=$(basename "$file")
    local temp_dir=""
    local json_file="$file"
    
    print_header "📊 Analyse: $filename"
    
    # Vérifier si jq est installé
    if ! command -v jq &> /dev/null; then
        print_error "jq n'est pas installé. Installation nécessaire pour analyser les JSON."
        echo "Installation: brew install jq (macOS) ou apt-get install jq (Ubuntu)"
        return 1
    fi
    
    # Vérifier si le fichier existe
    if [ ! -f "$file" ]; then
        print_error "Fichier non trouvé: $file"
        return 1
    fi
    
    # Si c'est un fichier ZIP, l'extraire temporairement
    if [[ "$file" == *.zip ]]; then
        temp_dir=$(mktemp -d)
        if ! unzip -q "$file" -d "$temp_dir" 2>/dev/null; then
            print_error "Impossible d'extraire le fichier ZIP: $file"
            rm -rf "$temp_dir"
            return 1
        fi
        
        # Chercher le fichier JSON principal dans l'archive (pas les config ou meta)
        json_file=$(find "$temp_dir" -name "*.json" -type f | grep -v "_config.json" | grep -v "_meta.json" | head -1)
        if [ -z "$json_file" ]; then
            print_error "Aucun fichier JSON trouvé dans l'archive: $file"
            rm -rf "$temp_dir"
            return 1
        fi
    fi
    
    # Vérifier si le fichier JSON est valide
    if ! jq empty "$json_file" 2>/dev/null; then
        print_error "Fichier JSON invalide: $json_file"
        [ -n "$temp_dir" ] && rm -rf "$temp_dir"
        return 1
    fi
    
    # Extraire les informations de base
    local strategy=$(jq -r '.strategy | keys[0] // "N/A"' "$json_file")
    local exchange=$(jq -r '.strategy | .[] | .exchange.name // "N/A"' "$json_file" 2>/dev/null)
    local timeframe=$(jq -r '.strategy | .[] | .timeframe // "N/A"' "$json_file" 2>/dev/null)
    local timerange=$(jq -r '.strategy | .[] | .timerange // "N/A"' "$json_file" 2>/dev/null)
    
    echo -e "${PURPLE}📋 Informations Générales:${NC}"
    echo "  • Stratégie: $strategy"
    echo "  • Exchange: $exchange"
    echo "  • Timeframe: $timeframe"
    echo "  • Période: $timerange"
    echo ""
    
    # Extraire les métriques de performance
    local total_trades=$(jq -r '.strategy | .[] | .total_trades // 0' "$json_file" 2>/dev/null)
    local starting_balance=$(jq -r '.strategy | .[] | .starting_balance // 0' "$json_file" 2>/dev/null)
    local final_balance=$(jq -r '.strategy | .[] | .final_balance // 0' "$json_file" 2>/dev/null)
    local profit_abs=$(jq -r '.strategy | .[] | .profit_total_abs // 0' "$json_file" 2>/dev/null)
    local profit_pct=$(jq -r '.strategy | .[] | .profit_total_pct // 0' "$json_file" 2>/dev/null | head -1)
    local win_rate=$(jq -r '.strategy | .[] | .wins // 0' "$json_file" 2>/dev/null)
    local loss_rate=$(jq -r '.strategy | .[] | .losses // 0' "$json_file" 2>/dev/null)
    
    if [ "$total_trades" != "0" ] && [ "$total_trades" != "null" ]; then
        win_rate_pct=$(echo "scale=2; $win_rate * 100 / $total_trades" | bc -l 2>/dev/null || echo "N/A")
    else
        win_rate_pct="N/A"
    fi
    
    echo -e "${PURPLE}💰 Performance:${NC}"
    echo "  • Trades totaux: $total_trades"
    echo "  • Balance initiale: $starting_balance"
    echo "  • Balance finale: $final_balance"
    echo "  • Profit absolu: $profit_abs"
    echo "  • Profit %: $profit_pct%"
    echo "  • Trades gagnants: $win_rate"
    echo "  • Trades perdants: $loss_rate"
    echo "  • Taux de réussite: $win_rate_pct%"
    echo ""
    
    # Extraire les métriques avancées
    local sharpe=$(jq -r '.strategy | .[] | .sharpe // "N/A"' "$json_file" 2>/dev/null)
    local sortino=$(jq -r '.strategy | .[] | .sortino // "N/A"' "$json_file" 2>/dev/null)
    local calmar=$(jq -r '.strategy | .[] | .calmar // "N/A"' "$json_file" 2>/dev/null)
    local max_drawdown=$(jq -r '.strategy | .[] | .max_drawdown_abs // "N/A"' "$json_file" 2>/dev/null)
    local max_drawdown_pct=$(jq -r '.strategy | .[] | .max_relative_drawdown // "N/A"' "$json_file" 2>/dev/null)
    local profit_factor=$(jq -r '.strategy | .[] | .profit_factor // "N/A"' "$json_file" 2>/dev/null)
    
    echo -e "${PURPLE}📈 Métriques Avancées:${NC}"
    echo "  • Sharpe Ratio: $sharpe"
    echo "  • Sortino Ratio: $sortino"
    echo "  • Calmar Ratio: $calmar"
    echo "  • Drawdown max: $max_drawdown ($max_drawdown_pct%)"
    echo "  • Profit Factor: $profit_factor"
    echo ""
    
    # Analyser les paires
    echo -e "${PURPLE}🔍 Analyse par Paire:${NC}"
    jq -r '.strategy | .[] | .results_per_pair[]? | "  • \(.key): \(.trades // 0) trades, \(.profit_total_pct // 0)%"' "$json_file" 2>/dev/null || echo "  • Données par paire non disponibles"
    echo ""
    
    # Nettoyer le répertoire temporaire si nécessaire
    [ -n "$temp_dir" ] && rm -rf "$temp_dir"
    
    # Recommandations basées sur les résultats
    echo -e "${PURPLE}💡 Recommandations:${NC}"
    
    if [ "$profit_pct" != "null" ] && [ "$profit_pct" != "N/A" ]; then
        profit_num=$(echo "$profit_pct" | sed 's/%//')
        if (( $(echo "$profit_num > 0" | bc -l 2>/dev/null || echo "0") )); then
            print_success "Stratégie rentable (+$profit_pct)"
        else
            print_warning "Stratégie non rentable ($profit_pct)"
        fi
    fi
    
    if [ "$sharpe" != "null" ] && [ "$sharpe" != "N/A" ]; then
        sharpe_num=$(echo "$sharpe" | sed 's/[^0-9.-]//g')
        if (( $(echo "$sharpe_num > 1" | bc -l 2>/dev/null || echo "0") )); then
            print_success "Bon ratio de Sharpe ($sharpe)"
        elif (( $(echo "$sharpe_num > 0" | bc -l 2>/dev/null || echo "0") )); then
            print_warning "Ratio de Sharpe acceptable ($sharpe)"
        else
            print_error "Mauvais ratio de Sharpe ($sharpe)"
        fi
    fi
    
    if [ "$total_trades" != "0" ] && [ "$total_trades" != "null" ]; then
        if (( total_trades < 10 )); then
            print_warning "Peu de trades ($total_trades) - période d'analyse peut-être trop courte"
        else
            print_success "Nombre de trades suffisant ($total_trades)"
        fi
    fi
    
    echo ""
}

# Fonction pour lister tous les fichiers de résultats
list_backtest_files() {
    local results_dir="user_data/backtest_results"
    
    if [ ! -d "$results_dir" ]; then
        print_error "Répertoire de résultats non trouvé: $results_dir"
        return 1
    fi
    
    # Trouver tous les fichiers de backtest (JSON et ZIP)
    local json_files=($(find "$results_dir" -name "*.json" -type f | grep -E "(backtest|result)" | sort -r))
    local zip_files=($(find "$results_dir" -name "*.zip" -type f | grep -E "(backtest|result)" | sort -r))
    local files=("${json_files[@]}" "${zip_files[@]}")
    
    if [ ${#files[@]} -eq 0 ]; then
        print_warning "Aucun fichier de résultats de backtest trouvé dans $results_dir"
        return 1
    fi
    
    echo -e "${GREEN}📁 Fichiers de résultats trouvés (${#files[@]}):${NC}"
    for i in "${!files[@]}"; do
        local file="${files[$i]}"
        local filename=$(basename "$file")
        local size=$(du -h "$file" | cut -f1)
        local date=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$file" 2>/dev/null || stat -c "%y" "$file" 2>/dev/null | cut -d' ' -f1-2)
        echo "  $((i+1)). $filename ($size) - $date"
    done
    echo ""
    
    return 0
}

# Fonction pour comparer plusieurs résultats
compare_results() {
    local files=("$@")
    
    if [ ${#files[@]} -lt 2 ]; then
        print_error "Au moins 2 fichiers nécessaires pour la comparaison"
        return 1
    fi
    
    print_header "🔄 Comparaison des Résultats"
    
    echo -e "${PURPLE}📊 Tableau Comparatif:${NC}"
    printf "%-20s %-10s %-12s %-8s %-8s %-8s %-8s\n" "Fichier" "Trades" "Profit%" "Sharpe" "Sortino" "Drawdown%" "Win%"
    printf "%-20s %-10s %-12s %-8s %-8s %-8s %-8s\n" "--------------------" "----------" "------------" "--------" "--------" "--------" "--------"
    
    for file in "${files[@]}"; do
        local filename=$(basename "$file" | cut -d'.' -f1)
        local temp_dir=""
        local json_file="$file"
        
        # Si c'est un fichier ZIP, l'extraire temporairement
        if [[ "$file" == *.zip ]]; then
            temp_dir=$(mktemp -d)
            if unzip -q "$file" -d "$temp_dir" 2>/dev/null; then
                json_file=$(find "$temp_dir" -name "*.json" -type f | head -1)
            fi
        fi
        
        local total_trades=$(jq -r '.strategy | .[] | .total_trades // 0' "$json_file" 2>/dev/null | head -1)
        local profit_pct=$(jq -r '.strategy | .[] | .profit_total_pct // 0' "$json_file" 2>/dev/null | head -1)
        local sharpe=$(jq -r '.strategy | .[] | .sharpe // "N/A"' "$json_file" 2>/dev/null | head -1)
        local sortino=$(jq -r '.strategy | .[] | .sortino // "N/A"' "$json_file" 2>/dev/null | head -1)
        local max_drawdown_pct=$(jq -r '.strategy | .[] | .max_relative_drawdown // "N/A"' "$json_file" 2>/dev/null | head -1)
        local wins=$(jq -r '.strategy | .[] | .wins // 0' "$json_file" 2>/dev/null | head -1)
        local win_pct="N/A"
        
        if [ "$total_trades" != "0" ] && [ "$total_trades" != "null" ]; then
            win_pct=$(echo "scale=1; $wins * 100 / $total_trades" | bc -l 2>/dev/null || echo "N/A")
        fi
        
        printf "%-20s %-10s %-12s %-8s %-8s %-8s %-8s\n" "$filename" "$total_trades" "$profit_pct%" "$sharpe" "$sortino" "$max_drawdown_pct%" "$win_pct%"
        
        # Nettoyer le répertoire temporaire si nécessaire
        [ -n "$temp_dir" ] && rm -rf "$temp_dir"
    done
    echo ""
}

# Fonction principale
main() {
    print_header "🔍 Analyseur de Résultats de Backtest FreqTrad"
    
    # Vérifier les arguments
    case "${1:-all}" in
        "list"|"l")
            list_backtest_files
            ;;
        "compare"|"c")
            shift
            if [ $# -lt 2 ]; then
                print_error "Usage: $0 compare <fichier1> <fichier2> [fichier3...]"
                exit 1
            fi
            compare_results "$@"
            ;;
        "latest"|"last")
            local latest_file=$(find user_data/backtest_results -name "*.json" -type f | grep -E "(backtest|result)" | sort -r | head -1)
            if [ -n "$latest_file" ]; then
                analyze_backtest_file "$latest_file"
            else
                print_error "Aucun fichier de résultats trouvé"
                exit 1
            fi
            ;;
        "all"|"")
            list_backtest_files
            if [ $? -eq 0 ]; then
                local files=($(find user_data/backtest_results -name "*.json" -type f | grep -E "(backtest|result)" | sort -r))
                for file in "${files[@]}"; do
                    analyze_backtest_file "$file"
                    echo ""
                done
            fi
            ;;
        *)
            if [ -f "$1" ]; then
                analyze_backtest_file "$1"
            else
                print_error "Fichier non trouvé: $1"
                print_info "Usage: $0 [list|compare|latest|all|<fichier>]"
                exit 1
            fi
            ;;
    esac
}

# Exécuter le script
main "$@"
