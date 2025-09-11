# pragma pylint: disable=missing-docstring, invalid-name, pointless-string-statement
# flake8: noqa: F401
# isort: skip_file
# --- Do not remove these libs ---
import numpy as np
import pandas as pd
from pandas import DataFrame
from freqtrade.strategy import IStrategy, merge_informative_pair
import talib.abstract as ta
from freqtrade.strategy import (BooleanParameter, CategoricalParameter, DecimalParameter,
                                IntParameter, RealParameter, timeframe_to_minutes)
import freqtrade.vendor.qtpylib.indicators as qtpylib


class PowerTowerStrategy(IStrategy):
    """
    Stratégie PowerTower corrigée - Stratégie de trading basée sur les tours de puissance
    """

    INTERFACE_VERSION = 3

    # Configuration de la stratégie
    can_short: bool = False
    timeframe = '5m'
    informative_timeframes = ['1h', '4h', '1d']
    
    # Paramètres optimisables
    buy_rsi = IntParameter(20, 40, default=30, space="buy")
    sell_rsi = IntParameter(60, 80, default=70, space="sell")
    buy_bb_percent = DecimalParameter(0.001, 0.02, default=0.01, space="buy")
    sell_bb_percent = DecimalParameter(0.001, 0.02, default=0.01, space="sell")
    
    # ROI table
    minimal_roi = {
        "60": 0.01,
        "30": 0.02,
        "0": 0.04
    }

    # Stoploss
    stoploss = -0.10

    # Trailing stop
    trailing_stop = False
    trailing_stop_positive = 0.01
    trailing_stop_positive_offset = 0.02
    trailing_only_offset_is_reached = False

    # Ordres
    order_types = {
        'entry': 'limit',
        'exit': 'limit',
        'stoploss': 'market',
        'stoploss_on_exchange': False
    }

    order_time_in_force = {
        'entry': 'GTC',
        'exit': 'GTC'
    }

    # Nombre de bougies nécessaires au démarrage
    startup_candle_count: int = 30

    def informative_pairs(self):
        """
        Définit les paires informatives supplémentaires
        """
        pairs = self.dp.current_whitelist()
        informative_pairs = [(pair, inf_timeframe) for pair in pairs for inf_timeframe in self.informative_timeframes]
        return informative_pairs

    def populate_indicators(self, dataframe: DataFrame, metadata: dict) -> DataFrame:
        """
        Ajoute les indicateurs techniques au DataFrame
        """
        # Vérifier que le DataFrame n'est pas vide
        if dataframe.empty:
            return dataframe
            
        # Vérifier que les colonnes nécessaires existent
        required_columns = ['open', 'high', 'low', 'close', 'volume']
        for col in required_columns:
            if col not in dataframe.columns:
                return dataframe

        # RSI
        dataframe['rsi'] = ta.RSI(dataframe, timeperiod=14)

        # Bollinger Bands
        bollinger = qtpylib.bollinger_bands(dataframe['close'], window=20, stds=2)
        dataframe['bb_lowerband'] = bollinger['lower']
        dataframe['bb_middleband'] = bollinger['mid']
        dataframe['bb_upperband'] = bollinger['upper']
        dataframe['bb_percent'] = (dataframe['close'] - dataframe['bb_lowerband']) / (dataframe['bb_upperband'] - dataframe['bb_lowerband'])
        dataframe['bb_width'] = (dataframe['bb_upperband'] - dataframe['bb_lowerband']) / dataframe['bb_middleband']

        # MACD
        macd = ta.MACD(dataframe)
        dataframe['macd'] = macd['macd']
        dataframe['macdsignal'] = macd['macdsignal']
        dataframe['macdhist'] = macd['macdhist']

        # EMA
        dataframe['ema_12'] = ta.EMA(dataframe, timeperiod=12)
        dataframe['ema_26'] = ta.EMA(dataframe, timeperiod=26)

        # ADX
        dataframe['adx'] = ta.ADX(dataframe, timeperiod=14)

        # CCI
        dataframe['cci'] = ta.CCI(dataframe, timeperiod=20)

        # ROC
        dataframe['roc'] = ta.ROC(dataframe, timeperiod=10)

        # Ajout des données informatives avec gestion d'erreur
        for timeframe in self.informative_timeframes:
            try:
                informative = self.dp.get_pair_dataframe(pair=metadata['pair'], timeframe=timeframe)
                if not informative.empty and len(informative) > 0:
                    # Vérifier que les colonnes nécessaires existent
                    if all(col in informative.columns for col in required_columns):
                        informative[f'momentum_{timeframe}'] = ta.MOM(informative, timeperiod=10)
                        informative[f'rsi_{timeframe}'] = ta.RSI(informative, timeperiod=14)
                        informative[f'trend_{timeframe}'] = np.where(
                            informative['close'] > informative['close'].rolling(20).mean(), 1, -1
                        )
                        dataframe = merge_informative_pair(dataframe, informative, self.timeframe, timeframe, ffill=True)
            except Exception as e:
                # En cas d'erreur, continuer sans les données informatives
                continue

        # S'assurer que le DataFrame a un index valide
        if dataframe.index.empty:
            dataframe = dataframe.reset_index(drop=True)

        return dataframe

    def populate_entry_trend(self, dataframe: DataFrame, metadata: dict) -> DataFrame:
        """
        Définit les conditions d'entrée
        """
        # Vérifier que le DataFrame n'est pas vide
        if dataframe.empty:
            return dataframe

        # S'assurer que les colonnes nécessaires existent
        required_columns = ['rsi', 'bb_percent', 'macd', 'macdsignal']
        for col in required_columns:
            if col not in dataframe.columns:
                return dataframe

        # Conditions d'entrée avec valeurs par défaut
        dataframe.loc[
            (
                # RSI bas (survente)
                (dataframe['rsi'] < self.buy_rsi.value) &
                # Prix sous la bande inférieure de Bollinger
                (dataframe['bb_percent'] < self.buy_bb_percent.value) &
                # MACD positif
                (dataframe['macd'] > dataframe['macdsignal']) &
                # Volume suffisant
                (dataframe['volume'] > 0)
            ),
            'enter_long'] = 1

        return dataframe

    def populate_exit_trend(self, dataframe: DataFrame, metadata: dict) -> DataFrame:
        """
        Définit les conditions de sortie
        """
        # Vérifier que le DataFrame n'est pas vide
        if dataframe.empty:
            return dataframe

        # S'assurer que les colonnes nécessaires existent
        required_columns = ['rsi', 'bb_percent', 'macd', 'macdsignal']
        for col in required_columns:
            if col not in dataframe.columns:
                return dataframe

        # Conditions de sortie avec valeurs par défaut
        dataframe.loc[
            (
                # RSI haut (surachat)
                (dataframe['rsi'] > self.sell_rsi.value) |
                # Prix au-dessus de la bande supérieure de Bollinger
                (dataframe['bb_percent'] > self.sell_bb_percent.value) |
                # MACD négatif
                (dataframe['macd'] < dataframe['macdsignal'])
            ),
            'exit_long'] = 1

        return dataframe
