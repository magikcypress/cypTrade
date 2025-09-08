


# pragma pylint: disable=missing-docstring, invalid-name, pointless-string-statement
# flake8: noqa: F401
# isort: skip_file
# --- Do not remove these libs ---
import numpy as np
import pandas as pd
from pandas import DataFrame
from datetime import datetime
from typing import Optional, Union

from freqtrade.strategy import IStrategy, merge_informative_pair
import talib.abstract as ta
import freqtrade.vendor.qtpylib.indicators as qtpylib


class MultiMAStrategy(IStrategy):
    """
    Stratégie Multi-MA - Combinaison de plusieurs moyennes mobiles
    Approche robuste avec filtres multiples
    """

    INTERFACE_VERSION = 3

    # Configuration ROI équilibrée
    minimal_roi = {
        "0": 0.15,    # 15% profit minimum
        "40": 0.08,   # 8% après 40 minutes
        "80": 0.04,   # 4% après 80 minutes
        "200": 0.02   # 2% après 200 minutes
    }

    stoploss = -0.08  # Stop loss à -8%

    # Timeframes
    timeframe = '5m'
    informative_timeframes = ['1h', '4h', '1d']

    # Paramètres fixes
    ema_fast = 8
    ema_slow = 21
    sma_long = 50
    rsi_period = 14
    rsi_buy = 30
    rsi_sell = 70
    volume_factor = 1.5

    def informative_pairs(self):
        pairs = self.dp.current_whitelist()
        informative_pairs = []
        for pair in pairs:
            for timeframe in self.informative_timeframes:
                informative_pairs.append((pair, timeframe))
        return informative_pairs

    def populate_indicators(self, dataframe: DataFrame, metadata: dict) -> DataFrame:
        # Moyennes mobiles
        dataframe['ema_fast'] = ta.EMA(dataframe, timeperiod=self.ema_fast)
        dataframe['ema_slow'] = ta.EMA(dataframe, timeperiod=self.ema_slow)
        dataframe['sma_long'] = ta.SMA(dataframe, timeperiod=self.sma_long)
        dataframe['sma_20'] = ta.SMA(dataframe, timeperiod=20)
        dataframe['sma_50'] = ta.SMA(dataframe, timeperiod=50)

        # RSI
        dataframe['rsi'] = ta.RSI(dataframe, timeperiod=self.rsi_period)

        # MACD
        macd = ta.MACD(dataframe)
        dataframe['macd'] = macd['macd']
        dataframe['macdsignal'] = macd['macdsignal']
        dataframe['macdhist'] = macd['macdhist']

        # Volume
        dataframe['volume_mean'] = dataframe['volume'].rolling(window=20).mean()
        dataframe['volume_ratio'] = dataframe['volume'] / dataframe['volume_mean']

        # Bollinger Bands
        bollinger = qtpylib.bollinger_bands(dataframe['close'], window=20, stds=2)
        dataframe['bb_lowerband'] = bollinger['lower']
        dataframe['bb_middleband'] = bollinger['mid']
        dataframe['bb_upperband'] = bollinger['upper']
        dataframe['bb_percent'] = (dataframe['close'] - dataframe['bb_lowerband']) / (dataframe['bb_upperband'] - dataframe['bb_lowerband'])

        # ATR
        dataframe['atr'] = ta.ATR(dataframe, timeperiod=14)

        # Stochastic
        stoch = ta.STOCH(dataframe)
        dataframe['stoch_k'] = stoch['slowk']
        dataframe['stoch_d'] = stoch['slowd']

        # Williams %R
        dataframe['williams_r'] = ta.WILLR(dataframe, timeperiod=14)

        # CCI
        dataframe['cci'] = ta.CCI(dataframe, timeperiod=20)

        # ADX
        dataframe['adx'] = ta.ADX(dataframe, timeperiod=14)

        # Tendance
        dataframe['trend'] = np.where(dataframe['ema_fast'] > dataframe['ema_slow'], 1, -1)
        dataframe['trend_strength'] = abs(dataframe['ema_fast'] - dataframe['ema_slow']) / dataframe['ema_slow']

        # Support et résistance
        dataframe['support'] = dataframe['low'].rolling(window=20).min()
        dataframe['resistance'] = dataframe['high'].rolling(window=20).max()

        # Ajout des données informatives
        for timeframe in self.informative_timeframes:
            informative = self.dp.get_pair_dataframe(pair=metadata['pair'], timeframe=timeframe)
            informative[f'ema_fast_{timeframe}'] = ta.EMA(informative, timeperiod=8)
            informative[f'ema_slow_{timeframe}'] = ta.EMA(informative, timeperiod=21)
            informative[f'sma_long_{timeframe}'] = ta.SMA(informative, timeperiod=50)
            informative[f'rsi_{timeframe}'] = ta.RSI(informative, timeperiod=14)
            informative[f'trend_{timeframe}'] = np.where(
                informative[f'ema_fast_{timeframe}'] > informative[f'ema_slow_{timeframe}'], 1, -1
            )
            dataframe = merge_informative_pair(dataframe, informative, self.timeframe, timeframe, ffill=True)

        return dataframe

    def populate_entry_trend(self, dataframe: DataFrame, metadata: dict) -> DataFrame:
        dataframe.loc[
            (
                # Alignement des moyennes mobiles (tendance haussière)
                (dataframe['ema_fast'] > dataframe['ema_slow']) &
                (dataframe['ema_slow'] > dataframe['sma_long']) &
                (dataframe['close'] > dataframe['ema_fast']) &
                
                # RSI en zone de survente
                (dataframe['rsi'] < self.rsi_buy) &
                (dataframe['rsi'] > 20) &
                
                # MACD positif
                (dataframe['macd'] > dataframe['macdsignal']) &
                (dataframe['macdhist'] > 0) &
                
                # Volume élevé
                (dataframe['volume_ratio'] > self.volume_factor) &
                
                # Prix proche de la bande inférieure de Bollinger
                (dataframe['bb_percent'] < 0.3) &
                
                # Stochastic en zone de survente
                (dataframe['stoch_k'] < 30) &
                (dataframe['stoch_d'] < 30) &
                
                # Williams %R en zone de survente
                (dataframe['williams_r'] < -70) &
                
                # CCI en zone de survente
                (dataframe['cci'] < -100) &
                
                # ADX indique une tendance
                (dataframe['adx'] > 20) &
                
                # Prix au-dessus du support
                (dataframe['close'] > dataframe['support']) &
                
                # Confirmation sur timeframes supérieurs
                (dataframe['trend_1h'] > 0) &
                (dataframe['trend_4h'] > 0) &
                (dataframe['trend_1d'] > 0) &
                
                # RSI sur timeframes supérieurs pas en survente extrême
                (dataframe['rsi_1h'] > 30) &
                (dataframe['rsi_4h'] > 30) &
                
                # Alignement des moyennes sur timeframes supérieurs
                (dataframe[f'ema_fast_1h'] > dataframe[f'ema_slow_1h']) &
                (dataframe[f'ema_fast_4h'] > dataframe[f'ema_slow_4h']) &
                
                # Pas de divergence négative
                (dataframe['close'] > dataframe['close'].shift(1))
            ),
            'enter_long'] = 1

        return dataframe

    def populate_exit_trend(self, dataframe: DataFrame, metadata: dict) -> DataFrame:
        dataframe.loc[
            (
                # Désalignement des moyennes mobiles
                (dataframe['ema_fast'] < dataframe['ema_slow']) |
                
                # RSI en zone de survente
                (dataframe['rsi'] > self.rsi_sell) |
                
                # MACD négatif
                (dataframe['macd'] < dataframe['macdsignal']) |
                
                # Prix proche de la bande supérieure de Bollinger
                (dataframe['bb_percent'] > 0.8) |
                
                # Prix proche de la résistance
                (dataframe['close'] > dataframe['resistance'] * 0.98) |
                
                # Stochastic en zone de survente
                (dataframe['stoch_k'] > 70) &
                (dataframe['stoch_d'] > 70) |
                
                # Williams %R en zone de survente
                (dataframe['williams_r'] > -30) |
                
                # CCI en zone de survente
                (dataframe['cci'] > 100) |
                
                # ADX faiblit
                (dataframe['adx'] < 15) |
                
                # Tendance sur timeframe supérieur négative
                (dataframe['trend_1h'] < 0) |
                
                # RSI sur timeframe supérieur en survente
                (dataframe['rsi_1h'] > 70) |
                
                # Désalignement sur timeframes supérieurs
                (dataframe[f'ema_fast_1h'] < dataframe[f'ema_slow_1h']) |
                
                # Divergence négative
                (dataframe['close'] < dataframe['close'].shift(1)) &
                (dataframe['rsi'] > dataframe['rsi'].shift(1))
            ),
            'exit_long'] = 1

        return dataframe