import numpy as np
import pandas as pd
from pandas import DataFrame
from datetime import datetime
from typing import Optional, Union

from freqtrade.strategy import IStrategy, merge_informative_pair
from freqtrade.strategy.parameters import IntParameter, DecimalParameter, CategoricalParameter
import talib.abstract as ta
import freqtrade.vendor.qtpylib.indicators as qtpylib

class HyperoptSimple(IStrategy):
    """
    Stratégie simple optimisée pour l'hyperopt
    """
    INTERFACE_VERSION = 3

    # ROI optimisé par hyperopt
    minimal_roi = {
        "0": 0.05,
        "20": 0.03,
        "40": 0.02,
        "80": 0.01
    }

    # Stop loss optimisé
    stoploss = -0.05

    # Timeframe
    timeframe = '5m'
    
    # Timeframes informatifs
    informative_timeframes = ['1h']

    # Nombre de bougies de démarrage
    startup_candle_count: int = 50

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
    
    buy_volume_factor = DecimalParameter(1.0, 2.5, default=1.2, space="buy")
    
    # Paramètres de vente
    sell_rsi_high = IntParameter(70, 85, default=75, space="sell")
    sell_ema_cross = CategoricalParameter([True, False], default=True, space="sell")
    
    # Paramètres de protection
    use_stop_loss = CategoricalParameter([True, False], default=True, space="protection")

    def informative_pairs(self):
        """
        Définit les paires et timeframes informatifs
        """
        pairs = self.dp.current_whitelist()
        informative_pairs = []
        for tf in self.informative_timeframes:
            for pair in pairs:
                informative_pairs.append((pair, tf))
        return informative_pairs

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
        
        # Données informatives (timeframes supérieurs)
        for timeframe in self.informative_timeframes:
            informative = self.dp.get_pair_dataframe(pair=metadata['pair'], timeframe=timeframe)
            
            if informative.empty:
                print(f"Warning: No data for {metadata['pair']} on {timeframe}")
                continue
                
            # RSI sur timeframe supérieur
            informative[f'rsi_{timeframe}'] = ta.RSI(informative, timeperiod=14)
            
            # EMA sur timeframe supérieur
            informative[f'ema_fast_{timeframe}'] = ta.EMA(informative, timeperiod=8)
            informative[f'ema_slow_{timeframe}'] = ta.EMA(informative, timeperiod=21)
            
            # Tendance sur timeframe supérieur
            informative[f'trend_{timeframe}'] = np.where(
                informative[f'ema_fast_{timeframe}'] > informative[f'ema_slow_{timeframe}'], 1, -1
            )
            
            # Volume sur timeframe supérieur
            informative[f'volume_{timeframe}'] = informative['volume']
            informative[f'volume_ma_{timeframe}'] = informative['volume'].rolling(window=20).mean()
            
            # Fusion avec le dataframe principal
            dataframe = merge_informative_pair(dataframe, informative, self.timeframe, timeframe, ffill=True)

        return dataframe

    def populate_entry_trend(self, dataframe: DataFrame, metadata: dict) -> DataFrame:
        """
        Conditions d'entrée optimisées
        """
        # Vérifier que les colonnes nécessaires existent
        required_columns = ['rsi', 'ema_fast', 'ema_slow', 'volume_ma']
        for tf in self.informative_timeframes:
            required_columns.extend([f'rsi_{tf}', f'ema_fast_{tf}', f'ema_slow_{tf}', f'trend_{tf}', f'volume_{tf}', f'volume_ma_{tf}'])
        
        missing_columns = [col for col in required_columns if col not in dataframe.columns]
        if missing_columns:
            print(f"Warning: Missing columns {missing_columns} for {metadata['pair']}")
            for col in missing_columns:
                dataframe[col] = 0

        dataframe.loc[
            (
                # Conditions de base
                (dataframe['rsi'] < self.buy_rsi_high.value) &
                (dataframe['rsi'] > self.buy_rsi_low.value) &
                
                # Croisement des moyennes mobiles
                (dataframe['ema_fast'] > dataframe['ema_slow']) &
                (dataframe['ema_fast'].shift(1) <= dataframe['ema_slow'].shift(1)) &
                
                # Volume
                (dataframe['volume'] > dataframe['volume_ma'] * self.buy_volume_factor.value) &
                
                # Conditions sur timeframes supérieurs
                (dataframe['trend_1h'] > 0) &
                (dataframe['rsi_1h'] < 70) &
                (dataframe['volume_1h'] > dataframe['volume_ma_1h'] * 1.1) &
                
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
        # Vérifier que les colonnes nécessaires existent
        required_columns = ['rsi', 'ema_fast', 'ema_slow']
        for tf in self.informative_timeframes:
            required_columns.extend([f'rsi_{tf}', f'ema_fast_{tf}', f'ema_slow_{tf}', f'trend_{tf}'])
        
        missing_columns = [col for col in required_columns if col not in dataframe.columns]
        if missing_columns:
            print(f"Warning: Missing columns {missing_columns} for {metadata['pair']}")
            for col in missing_columns:
                dataframe[col] = 0

        dataframe.loc[
            (
                # RSI élevé
                (dataframe['rsi'] > self.sell_rsi_high.value) |
                
                # Croisement des moyennes mobiles (si activé)
                (self.sell_ema_cross.value & (dataframe['ema_fast'] < dataframe['ema_slow']) & 
                 (dataframe['ema_fast'].shift(1) >= dataframe['ema_slow'].shift(1))) |
                
                # Tendance négative sur timeframes supérieurs
                (dataframe['trend_1h'] < 0) |
                (dataframe['rsi_1h'] > 80) |
                
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
