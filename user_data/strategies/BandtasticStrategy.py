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


class BandtasticStrategy(IStrategy):
    """
    Stratégie Bandtastic - Optimisée pour maximiser le ratio de Sharpe
    Basée sur les bandes de volatilité et les indicateurs de momentum
    """

    INTERFACE_VERSION = 3

    # Configuration ROI optimisée
    minimal_roi = {
        "0": 0.20,    # 20% profit minimum
        "30": 0.10,   # 10% après 30 minutes
        "60": 0.05,   # 5% après 60 minutes
        "120": 0.02   # 2% après 120 minutes
    }

    stoploss = -0.10  # Stop loss à -10%

    # Timeframes
    timeframe = '5m'
    informative_timeframes = ['1h', '4h']

    # Paramètres fixes
    bb_period = 20
    bb_std = 2.0
    rsi_period = 14
    rsi_buy = 30
    rsi_sell = 70
    volume_factor = 1.5
    profit_threshold = 0.05

    def informative_pairs(self):
        pairs = self.dp.current_whitelist()
        informative_pairs = []
        for pair in pairs:
            for timeframe in self.informative_timeframes:
                informative_pairs.append((pair, timeframe))
        return informative_pairs

    def populate_indicators(self, dataframe: DataFrame, metadata: dict) -> DataFrame:
        # Bollinger Bands
        bollinger = qtpylib.bollinger_bands(dataframe['close'], window=self.bb_period, stds=self.bb_std)
        dataframe['bb_lowerband'] = bollinger['lower']
        dataframe['bb_middleband'] = bollinger['mid']
        dataframe['bb_upperband'] = bollinger['upper']
        dataframe['bb_percent'] = (dataframe['close'] - dataframe['bb_lowerband']) / (dataframe['bb_upperband'] - dataframe['bb_lowerband'])
        dataframe['bb_width'] = (dataframe['bb_upperband'] - dataframe['bb_lowerband']) / dataframe['bb_middleband']

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

        # Moyennes mobiles
        dataframe['ema_fast'] = ta.EMA(dataframe, timeperiod=8)
        dataframe['ema_slow'] = ta.EMA(dataframe, timeperiod=21)

        # Momentum
        dataframe['momentum'] = ta.MOM(dataframe, timeperiod=10)

        # Ajout des données informatives
        for timeframe in self.informative_timeframes:
            informative = self.dp.get_pair_dataframe(pair=metadata['pair'], timeframe=timeframe)
            informative[f'rsi_{timeframe}'] = ta.RSI(informative, timeperiod=14)
            informative[f'bb_percent_{timeframe}'] = (informative['close'] - informative['close'].rolling(20).min()) / (informative['close'].rolling(20).max() - informative['close'].rolling(20).min())
            dataframe = merge_informative_pair(dataframe, informative, self.timeframe, timeframe, ffill=True)

        return dataframe

    def populate_entry_trend(self, dataframe: DataFrame, metadata: dict) -> DataFrame:
        dataframe.loc[
            (
                # Prix proche de la bande inférieure
                (dataframe['bb_percent'] < 0.2) &
                
                # RSI en zone de survente
                (dataframe['rsi'] < self.rsi_buy) &
                
                # MACD positif ou en train de se retourner
                (dataframe['macd'] > dataframe['macdsignal']) &
                
                # Volume élevé
                (dataframe['volume_ratio'] > self.volume_factor) &
                
                # Stochastic en zone de survente
                (dataframe['stoch_k'] < 30) &
                (dataframe['stoch_d'] < 30) &
                
                # Williams %R en zone de survente
                (dataframe['williams_r'] < -70) &
                
                # CCI en zone de survente
                (dataframe['cci'] < -100) &
                
                # ADX indique une tendance
                (dataframe['adx'] > 20) &
                
                # Tendance haussière
                (dataframe['ema_fast'] > dataframe['ema_slow']) &
                
                # Momentum positif
                (dataframe['momentum'] > 0) &
                
                # Confirmation sur timeframe supérieur
                (dataframe['rsi_1h'] > 30) &
                (dataframe['bb_percent_1h'] < 0.8) &
                
                # Pas de divergence négative
                (dataframe['close'] > dataframe['close'].shift(1))
            ),
            'enter_long'] = 1

        return dataframe

    def populate_exit_trend(self, dataframe: DataFrame, metadata: dict) -> DataFrame:
        dataframe.loc[
            (
                # Prix proche de la bande supérieure
                (dataframe['bb_percent'] > 0.8) |
                
                # RSI en zone de survente
                (dataframe['rsi'] > self.rsi_sell) |
                
                # MACD négatif
                (dataframe['macd'] < dataframe['macdsignal']) |
                
                # Profit cible atteint
                (dataframe['close'] > dataframe['open'] * (1 + self.profit_threshold)) |
                
                # Stochastic en zone de survente
                (dataframe['stoch_k'] > 70) &
                (dataframe['stoch_d'] > 70) |
                
                # Williams %R en zone de survente
                (dataframe['williams_r'] > -30) |
                
                # CCI en zone de survente
                (dataframe['cci'] > 100) |
                
                # Tendance change
                (dataframe['ema_fast'] < dataframe['ema_slow']) |
                
                # Momentum négatif
                (dataframe['momentum'] < 0) |
                
                # RSI sur timeframe supérieur en survente
                (dataframe['rsi_1h'] > 70) |
                
                # BB sur timeframe supérieur en survente
                (dataframe['bb_percent_1h'] > 0.8)
            ),
            'exit_long'] = 1

        return dataframe
