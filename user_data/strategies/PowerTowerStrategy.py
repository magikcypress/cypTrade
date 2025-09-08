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


class PowerTowerStrategy(IStrategy):
    """
    Stratégie PowerTower - Capture les mouvements explosifs du marché
    Basée sur le momentum et les breakouts
    """

    INTERFACE_VERSION = 3

    # Configuration ROI agressive
    minimal_roi = {
        "0": 0.30,    # 30% profit minimum
        "15": 0.15,   # 15% après 15 minutes
        "30": 0.08,   # 8% après 30 minutes
        "60": 0.04    # 4% après 60 minutes
    }

    stoploss = -0.12  # Stop loss à -12%

    # Timeframes
    timeframe = '5m'
    informative_timeframes = ['1h', '4h', '1d']

    # Paramètres fixes
    momentum_period = 10
    volume_spike = 2.5
    breakout_threshold = 0.05
    rsi_momentum = 50
    profit_target = 0.20

    def informative_pairs(self):
        pairs = self.dp.current_whitelist()
        informative_pairs = []
        for pair in pairs:
            for timeframe in self.informative_timeframes:
                informative_pairs.append((pair, timeframe))
        return informative_pairs

    def populate_indicators(self, dataframe: DataFrame, metadata: dict) -> DataFrame:
        # Momentum
        dataframe['momentum'] = ta.MOM(dataframe, timeperiod=self.momentum_period)
        dataframe['momentum_abs'] = abs(dataframe['momentum'])

        # Volume
        dataframe['volume_mean'] = dataframe['volume'].rolling(window=20).mean()
        dataframe['volume_spike'] = dataframe['volume'] / dataframe['volume_mean']

        # RSI
        dataframe['rsi'] = ta.RSI(dataframe, timeperiod=14)
        dataframe['rsi_fast'] = ta.RSI(dataframe, timeperiod=7)

        # MACD
        macd = ta.MACD(dataframe)
        dataframe['macd'] = macd['macd']
        dataframe['macdsignal'] = macd['macdsignal']
        dataframe['macdhist'] = macd['macdhist']

        # Bollinger Bands
        bollinger = qtpylib.bollinger_bands(dataframe['close'], window=20, stds=2)
        dataframe['bb_lowerband'] = bollinger['lower']
        dataframe['bb_upperband'] = bollinger['upper']
        dataframe['bb_percent'] = (dataframe['close'] - dataframe['bb_lowerband']) / (dataframe['bb_upperband'] - dataframe['bb_lowerband'])

        # ATR
        dataframe['atr'] = ta.ATR(dataframe, timeperiod=14)
        dataframe['atr_percent'] = (dataframe['atr'] / dataframe['close']) * 100

        # Moyennes mobiles
        dataframe['ema_fast'] = ta.EMA(dataframe, timeperiod=8)
        dataframe['ema_slow'] = ta.EMA(dataframe, timeperiod=21)
        dataframe['sma_50'] = ta.SMA(dataframe, timeperiod=50)

        # Support et résistance
        dataframe['resistance'] = dataframe['high'].rolling(window=20).max()
        dataframe['support'] = dataframe['low'].rolling(window=20).min()

        # Breakout detection
        dataframe['breakout_up'] = dataframe['close'] > dataframe['resistance'].shift(1)
        dataframe['breakout_down'] = dataframe['close'] < dataframe['support'].shift(1)

        # Volatilité
        dataframe['volatility'] = dataframe['close'].pct_change().rolling(window=20).std()

        # ADX
        dataframe['adx'] = ta.ADX(dataframe, timeperiod=14)

        # Stochastic
        stoch = ta.STOCH(dataframe)
        dataframe['stoch_k'] = stoch['slowk']
        dataframe['stoch_d'] = stoch['slowd']

        # Williams %R
        dataframe['williams_r'] = ta.WILLR(dataframe, timeperiod=14)

        # CCI
        dataframe['cci'] = ta.CCI(dataframe, timeperiod=20)

        # ROC
        dataframe['roc'] = ta.ROC(dataframe, timeperiod=10)

        # Ajout des données informatives
        for timeframe in self.informative_timeframes:
            informative = self.dp.get_pair_dataframe(pair=metadata['pair'], timeframe=timeframe)
            if not informative.empty:
                informative[f'momentum_{timeframe}'] = ta.MOM(informative, timeperiod=10)
                informative[f'rsi_{timeframe}'] = ta.RSI(informative, timeperiod=14)
                informative[f'trend_{timeframe}'] = np.where(informative['close'] > informative['close'].rolling(20).mean(), 1, -1)
                dataframe = merge_informative_pair(dataframe, informative, self.timeframe, timeframe, ffill=True)

        return dataframe

    def populate_entry_trend(self, dataframe: DataFrame, metadata: dict) -> DataFrame:
        dataframe.loc[
            (
                # Momentum fort
                (dataframe['momentum'] > dataframe['momentum'].rolling(10).quantile(0.8)) &
                (dataframe['momentum_abs'] > dataframe['momentum_abs'].rolling(20).mean() * 1.5) &
                
                # Volume spike
                (dataframe['volume_spike'] > self.volume_spike) &
                
                # RSI dans la zone de momentum
                (dataframe['rsi'] > self.rsi_momentum) &
                (dataframe['rsi'] < 80) &
                
                # MACD positif et croissant
                (dataframe['macd'] > dataframe['macdsignal']) &
                (dataframe['macdhist'] > dataframe['macdhist'].shift(1)) &
                
                # Breakout vers le haut
                (dataframe['breakout_up']) &
                
                # Prix au-dessus des moyennes mobiles
                (dataframe['close'] > dataframe['ema_fast']) &
                (dataframe['close'] > dataframe['ema_slow']) &
                (dataframe['close'] > dataframe['sma_50']) &
                
                # Volatilité acceptable
                (dataframe['volatility'] > 0.01) &
                (dataframe['volatility'] < 0.08) &
                
                # ADX indique une tendance forte
                (dataframe['adx'] > 25) &
                
                # Stochastic en zone de momentum
                (dataframe['stoch_k'] > 50) &
                (dataframe['stoch_d'] > 50) &
                
                # Williams %R en zone de momentum
                (dataframe['williams_r'] > -50) &
                
                # CCI positif
                (dataframe['cci'] > 0) &
                
                # ROC positif
                (dataframe['roc'] > 0) &
                
                # Confirmation sur timeframes supérieurs (si disponibles)
                (dataframe.get('momentum_1h', 0) > 0) &
                (dataframe.get('rsi_1h', 50) > 40) &
                (dataframe.get('trend_1h', 0) > 0) &
                
                # Pas de divergence négative
                (dataframe['close'] > dataframe['close'].shift(1)) &
                (dataframe['volume'] > dataframe['volume'].shift(1))
            ),
            'enter_long'] = 1

        return dataframe

    def populate_exit_trend(self, dataframe: DataFrame, metadata: dict) -> DataFrame:
        dataframe.loc[
            (
                # Profit cible atteint
                (dataframe['close'] > dataframe['open'] * (1 + self.profit_target)) |
                
                # Momentum faiblit
                (dataframe['momentum'] < dataframe['momentum'].rolling(10).quantile(0.3)) |
                
                # RSI en zone de survente
                (dataframe['rsi'] > 80) |
                
                # MACD négatif
                (dataframe['macd'] < dataframe['macdsignal']) |
                
                # Breakout vers le bas
                (dataframe['breakout_down']) |
                
                # Prix en dessous des moyennes mobiles
                (dataframe['close'] < dataframe['ema_fast']) |
                
                # Volatilité trop élevée
                (dataframe['volatility'] > 0.10) |
                
                # ADX faiblit
                (dataframe['adx'] < 20) |
                
                # Stochastic en zone de survente
                (dataframe['stoch_k'] > 80) &
                (dataframe['stoch_d'] > 80) |
                
                # Williams %R en zone de survente
                (dataframe['williams_r'] > -20) |
                
                # CCI négatif
                (dataframe['cci'] < 0) |
                
                # ROC négatif
                (dataframe['roc'] < 0) |
                
                # Momentum sur timeframe supérieur négatif (si disponible)
                (dataframe.get('momentum_1h', 0) < 0) |
                
                # RSI sur timeframe supérieur en survente (si disponible)
                (dataframe.get('rsi_1h', 50) > 80) |
                
                # Tendance sur timeframe supérieur négative (si disponible)
                (dataframe.get('trend_1h', 0) < 0) |
                
                # Divergence négative
                (dataframe['close'] < dataframe['close'].shift(1)) &
                (dataframe['momentum'] > dataframe['momentum'].shift(1))
            ),
            'exit_long'] = 1

        return dataframe
