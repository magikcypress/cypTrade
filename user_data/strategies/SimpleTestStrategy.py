# pragma pylint: disable=missing-docstring, invalid-name, pointless-string-statement
# flake8: noqa: F401
# isort: skip_file
# --- Do not remove these libs ---
import numpy as np
import pandas as pd
from pandas import DataFrame
from datetime import datetime
from typing import Optional, Union

from freqtrade.strategy import IStrategy
import talib.abstract as ta


class SimpleTestStrategy(IStrategy):
    """
    Stratégie de test simple pour vérifier que tout fonctionne
    """

    INTERFACE_VERSION = 3

    # Configuration ROI simple
    minimal_roi = {
        "0": 0.10,    # 10% profit minimum
        "60": 0.05,   # 5% après 60 minutes
        "120": 0.02   # 2% après 120 minutes
    }

    stoploss = -0.05  # Stop loss à -5%

    # Timeframes
    timeframe = '5m'

    def populate_indicators(self, dataframe: DataFrame, metadata: dict) -> DataFrame:
        # RSI simple
        dataframe['rsi'] = ta.RSI(dataframe, timeperiod=14)
        
        # Moyennes mobiles simples
        dataframe['ema_fast'] = ta.EMA(dataframe, timeperiod=8)
        dataframe['ema_slow'] = ta.EMA(dataframe, timeperiod=21)
        
        return dataframe

    def populate_entry_trend(self, dataframe: DataFrame, metadata: dict) -> DataFrame:
        dataframe.loc[
            (
                # RSI en zone de survente
                (dataframe['rsi'] < 30) &
                
                # Tendance haussière
                (dataframe['ema_fast'] > dataframe['ema_slow']) &
                
                # Prix au-dessus de la moyenne rapide
                (dataframe['close'] > dataframe['ema_fast'])
            ),
            'enter_long'] = 1

        return dataframe

    def populate_exit_trend(self, dataframe: DataFrame, metadata: dict) -> DataFrame:
        dataframe.loc[
            (
                # RSI en zone de survente
                (dataframe['rsi'] > 70) |
                
                # Tendance change
                (dataframe['ema_fast'] < dataframe['ema_slow'])
            ),
            'exit_long'] = 1

        return dataframe
