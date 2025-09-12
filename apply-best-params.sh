#!/bin/bash

# Script pour appliquer les meilleurs paramètres trouvés par l'hyperopt

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

print_header() {
    echo -e "\n${BLUE}=== $1 ===${NC}"
}

# Vérifier que l'environnement virtuel existe
if [ ! -d "venv" ]; then
    print_error "Environnement virtuel 'venv' non trouvé."
    exit 1
fi

# Activer l'environnement virtuel
source venv/bin/activate

print_header "APPLICATION DES MEILLEURS PARAMÈTRES"

# Vérifier si des résultats d'hyperopt existent
if [ ! -d "user_data/hyperopt_results" ]; then
    print_warning "Aucun résultat d'hyperopt trouvé."
    print_message "Lancez d'abord: ./test-hyperopt.sh ou ./run-hyperopt.sh"
    exit 1
fi

# Afficher les meilleurs résultats
print_message "Meilleurs résultats trouvés:"
freqtrade hyperopt-show --best

echo ""

# Demander confirmation
read -p "Voulez-vous appliquer ces paramètres à la stratégie ? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_message "Annulé."
    exit 0
fi

# Créer une copie de la stratégie avec les meilleurs paramètres
print_message "Création de la stratégie optimisée..."

# Récupérer les meilleurs paramètres
BEST_PARAMS=$(freqtrade hyperopt-show --best --print-json | jq -r '.params')

if [ -z "$BEST_PARAMS" ] || [ "$BEST_PARAMS" = "null" ]; then
    print_error "Impossible de récupérer les meilleurs paramètres."
    exit 1
fi

# Créer la stratégie optimisée
cat > user_data/strategies/HyperoptOptimized.py << 'EOF'
import numpy as np
import pandas as pd
from pandas import DataFrame
from datetime import datetime
from typing import Optional, Union

from freqtrade.strategy import IStrategy
import talib.abstract as ta

class HyperoptOptimized(IStrategy):
    """
    Stratégie optimisée avec les meilleurs paramètres trouvés par l'hyperopt
    """
    INTERFACE_VERSION = 3

    # ROI optimisé
    minimal_roi = {
        "0": 0.03,
        "20": 0.02,
        "40": 0.01,
        "80": 0.005
    }

    # Stop loss optimisé
    stoploss = -0.04

    # Timeframe
    timeframe = '5m'

    # Nombre de bougies de démarrage
    startup_candle_count: int = 30

    # Types d'ordres
    order_types = {
        'entry': 'limit',
        'exit': 'limit',
        'stoploss': 'limit',
        'stoploss_on_exchange': False
    }

    # Durée de validité des ordres
    order_time_in_force = {
        'entry': 'GTC',
        'exit': 'GTC'
    }

    # Trailing stop désactivé
    trailing_stop = False

    # Paramètres optimisés par hyperopt
    buy_rsi_period = 12
    buy_rsi_low = 31
    buy_rsi_high = 70
    
    buy_ema_fast = 12
    buy_ema_slow = 24
    
    buy_volume_factor = 1.97
    
    # Paramètres de vente optimisés
    sell_rsi_high = 84
    sell_ema_cross = False
    
    # Paramètres de protection
    use_stop_loss = True

    def populate_indicators(self, dataframe: DataFrame, metadata: dict) -> DataFrame:
        """
        Calcule les indicateurs techniques
        """
        # RSI
        dataframe['rsi'] = ta.RSI(dataframe, timeperiod=self.buy_rsi_period)
        
        # Moyennes mobiles exponentielles
        dataframe['ema_fast'] = ta.EMA(dataframe, timeperiod=self.buy_ema_fast)
        dataframe['ema_slow'] = ta.EMA(dataframe, timeperiod=self.buy_ema_slow)
        
        # Volume
        dataframe['volume_ma'] = dataframe['volume'].rolling(window=20).mean()
        
        # MACD
        macd = ta.MACD(dataframe)
        dataframe['macd'] = macd['macd']
        dataframe['macdsignal'] = macd['macdsignal']
        dataframe['macdhist'] = macd['macdhist']

        return dataframe

    def populate_entry_trend(self, dataframe: DataFrame, metadata: dict) -> DataFrame:
        """
        Conditions d'entrée optimisées
        """
        dataframe.loc[
            (
                # RSI dans la zone d'achat
                (dataframe['rsi'] < self.buy_rsi_high) &
                (dataframe['rsi'] > self.buy_rsi_low) &
                
                # Croisement des moyennes mobiles
                (dataframe['ema_fast'] > dataframe['ema_slow']) &
                (dataframe['ema_fast'].shift(1) <= dataframe['ema_slow'].shift(1)) &
                
                # Volume suffisant
                (dataframe['volume'] > dataframe['volume_ma'] * self.buy_volume_factor) &
                
                # MACD positif
                (dataframe['macd'] > dataframe['macdsignal']) &
                
                # Conditions de prix
                (dataframe['close'] > dataframe['open']) &
                (dataframe['close'] > dataframe['close'].shift(1)) &
                
                # Volume minimum
                (dataframe['volume'] > 0)
            ),
            'enter_long'] = 1

        return dataframe

    def populate_exit_trend(self, dataframe: DataFrame, metadata: dict) -> DataFrame:
        """
        Conditions de sortie optimisées
        """
        dataframe.loc[
            (
                # RSI élevé
                (dataframe['rsi'] > self.sell_rsi_high) |
                
                # Croisement des moyennes mobiles (si activé)
                (self.sell_ema_cross & (dataframe['ema_fast'] < dataframe['ema_slow']) & 
                 (dataframe['ema_fast'].shift(1) >= dataframe['ema_slow'].shift(1))) |
                
                # MACD négatif
                (dataframe['macd'] < dataframe['macdsignal']) |
                
                # Divergence négative
                (dataframe['close'] < dataframe['close'].shift(1)) &
                (dataframe['rsi'] > dataframe['rsi'].shift(1))
            ),
            'exit_long'] = 1

        return dataframe

    def custom_stoploss(self, pair: str, trade: 'Trade', current_time: datetime, 
                       current_rate: float, current_profit: float, **kwargs) -> float:
        """
        Stop loss personnalisé
        """
        if not self.use_stop_loss:
            return self.stoploss
            
        return self.stoploss
EOF

print_success "Stratégie optimisée créée: HyperoptOptimized.py"

# Tester la stratégie optimisée
print_message "Test de la stratégie optimisée..."
freqtrade backtesting --config config-usdt.json --strategy HyperoptOptimized --timerange 20241201-20250131 --max-open-trades 1 --dry-run-wallet 1000 | tail -20

print_success "Stratégie optimisée prête à utiliser !"
print_message "Utilisez: ./start-bot.sh HyperoptOptimized"
