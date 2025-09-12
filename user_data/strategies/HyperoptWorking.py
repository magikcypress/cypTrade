import numpy as np
import pandas as pd
from pandas import DataFrame
from datetime import datetime
from typing import Optional, Union

from freqtrade.strategy import IStrategy
from freqtrade.strategy.parameters import IntParameter, DecimalParameter, CategoricalParameter
from freqtrade.persistence import Trade
import talib.abstract as ta

class HyperoptWorking(IStrategy):
    """
    Stratégie simple qui fonctionne pour l'hyperopt
    """
    INTERFACE_VERSION = 3

    # ROI optimisé par hyperopt
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

    # Paramètres optimisables par hyperopt
    buy_rsi_period = IntParameter(10, 20, default=14, space="buy")
    buy_rsi_low = IntParameter(20, 40, default=30, space="buy")
    buy_rsi_high = IntParameter(60, 80, default=70, space="buy")
    
    buy_ema_fast = IntParameter(5, 15, default=8, space="buy")
    buy_ema_slow = IntParameter(20, 35, default=21, space="buy")
    
    buy_volume_factor = DecimalParameter(1.0, 2.0, default=1.1, space="buy")
    
    # Paramètres de vente
    sell_rsi_high = IntParameter(70, 85, default=75, space="sell")
    sell_ema_cross = CategoricalParameter([True, False], default=True, space="sell")
    
    # Paramètres de protection
    use_stop_loss = CategoricalParameter([True, False], default=True, space="protection")

    def populate_indicators(self, dataframe: DataFrame, metadata: dict) -> DataFrame:
        """
        Calcule les indicateurs techniques
        """
        # RSI
        dataframe['rsi'] = ta.RSI(dataframe, timeperiod=self.buy_rsi_period.value)
        
        # Moyennes mobiles exponentielles
        dataframe['ema_fast'] = ta.EMA(dataframe, timeperiod=self.buy_ema_fast.value)
        dataframe['ema_slow'] = ta.EMA(dataframe, timeperiod=self.buy_ema_slow.value)
        
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
                (dataframe['rsi'] < self.buy_rsi_high.value) &
                (dataframe['rsi'] > self.buy_rsi_low.value) &
                
                # Croisement des moyennes mobiles
                (dataframe['ema_fast'] > dataframe['ema_slow']) &
                (dataframe['ema_fast'].shift(1) <= dataframe['ema_slow'].shift(1)) &
                
                # Volume suffisant
                (dataframe['volume'] > dataframe['volume_ma'] * self.buy_volume_factor.value) &
                
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
                (dataframe['rsi'] > self.sell_rsi_high.value) |
                
                # Croisement des moyennes mobiles (si activé)
                (self.sell_ema_cross.value & (dataframe['ema_fast'] < dataframe['ema_slow']) & 
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
        if not self.use_stop_loss.value:
            return self.stoploss
            
        return self.stoploss
