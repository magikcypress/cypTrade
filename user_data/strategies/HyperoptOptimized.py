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
    buy_rsi_period = 15
    buy_rsi_low = 21
    buy_rsi_high = 60
    
    buy_ema_fast = 13
    buy_ema_slow = 32
    
    buy_volume_factor = 1.967
    
    # Paramètres de vente optimisés
    sell_rsi_high = 83
    sell_ema_cross = True
    
    # Paramètres de protection
    use_stop_loss = False

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
