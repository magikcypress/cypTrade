# pragma pylint: disable=missing-docstring, invalid-name, pointless-string-statement
# flake8: noqa: F401
# isort: skip_file
# --- Do not remove these libs ---
import numpy as np
import pandas as pd
from pandas import DataFrame
from datetime import datetime
from typing import Optional, Union

from freqtrade.strategy import (BooleanParameter, CategoricalParameter, DecimalParameter,
                                IntParameter, IStrategy, merge_informative_pair)

# --------------------------------
# Add your lib to import here
import talib.abstract as ta
import freqtrade.vendor.qtpylib.indicators as qtpylib


class MeanReversionStrategy(IStrategy):
    """
    Stratégie de Retour à la Moyenne (Mean Reversion)
    
    Principe : Les prix finissent par revenir vers leur moyenne historique
    - Achat quand le prix est "trop bas" par rapport à la moyenne
    - Vente quand le prix est "trop haut" par rapport à la moyenne
    
    Indicateurs utilisés :
    - Bollinger Bands pour identifier les zones de survente/surachat
    - RSI pour confirmer les signaux
    - Z-Score pour mesurer l'écart par rapport à la moyenne
    - Support/Résistance dynamiques
    """
    
    # Strategy interface version - allow new iterations of the strategy
    INTERFACE_VERSION = 3

    # Optimal timeframe for the strategy
    timeframe = '5m'

    # Can this strategy go short?
    can_short: bool = False

    # Minimal ROI designed for the strategy.
    minimal_roi = {
        "0": 0.03,    # 3% après 0 minutes
        "15": 0.02,   # 2% après 15 minutes
        "30": 0.015,  # 1.5% après 30 minutes
        "60": 0.01    # 1% après 60 minutes
    }

    # Optimal stoploss designed for the strategy
    stoploss = -0.03  # -3% (plus serré car mean reversion)

    # Trailing stoploss
    trailing_stop = True
    trailing_stop_positive = 0.015  # 1.5%
    trailing_stop_positive_offset = 0.02  # 2%

    # === PARAMÈTRES D'OPTIMISATION ===
    
    # Paramètres pour les Bollinger Bands (assouplis)
    bb_period = IntParameter(10, 30, default=20, space="buy")
    bb_std = DecimalParameter(1.5, 3.0, default=2.0, space="buy")
    bb_oversold_threshold = DecimalParameter(0.05, 0.25, default=0.2, space="buy")  # Plus permissif
    bb_overbought_threshold = DecimalParameter(0.75, 0.95, default=0.8, space="sell")  # Plus permissif
    
    # Paramètres pour le RSI (assouplis)
    rsi_period = IntParameter(10, 20, default=14, space="buy")
    rsi_oversold = IntParameter(20, 35, default=40, space="buy")  # Plus permissif
    rsi_overbought = IntParameter(65, 80, default=60, space="sell")  # Plus permissif
    
    # Paramètres pour le Z-Score (assouplis)
    zscore_period = IntParameter(15, 30, default=20, space="buy")
    zscore_oversold = DecimalParameter(-2.5, -1.5, default=-1.5, space="buy")  # Plus permissif
    zscore_overbought = DecimalParameter(1.5, 2.5, default=1.5, space="sell")  # Plus permissif
    
    # Paramètres pour Williams %R (assouplis)
    williams_period = IntParameter(10, 20, default=14, space="buy")
    williams_oversold = IntParameter(-90, -70, default=-70, space="buy")  # Plus permissif
    williams_overbought = IntParameter(-30, -10, default=-30, space="sell")  # Plus permissif
    
    # Paramètres pour les moyennes mobiles
    sma_short_period = IntParameter(15, 25, default=20, space="buy")
    sma_long_period = IntParameter(40, 60, default=50, space="buy")
    
    # Paramètres pour le volume
    volume_factor = DecimalParameter(1.0, 2.0, default=1.2, space="buy")
    
    # Paramètres pour la volatilité
    min_volatility = DecimalParameter(0.01, 0.05, default=0.02, space="buy")

    # Run "populate_indicators" only for new candle
    process_only_new_candles = False

    # These values can be overridden in the config
    use_exit_signal = True
    exit_profit_only = False
    ignore_roi_if_entry_signal = False

    # Number of candles the strategy requires before producing valid signals
    startup_candle_count: int = 50

    # Optional order type mapping
    order_types = {
        'entry': 'limit',
        'exit': 'limit',
        'stoploss': 'market',
        'stoploss_on_exchange': False
    }

    # Optional order time in force
    order_time_in_force = {
        'entry': 'gtc',
        'exit': 'gtc'
    }

    plot_config = {
        'main_plot': {
            'bb_upperband': {'color': 'red'},
            'bb_middleband': {'color': 'blue'},
            'bb_lowerband': {'color': 'green'},
            'sma_20': {'color': 'orange'},
            'sma_50': {'color': 'purple'},
        },
        'subplots': {
            "RSI": {
                'rsi': {'color': 'red'},
                'rsi_oversold': {'color': 'green'},
                'rsi_overbought': {'color': 'red'}
            },
            "Z-Score": {
                'zscore': {'color': 'blue'},
                'zscore_oversold': {'color': 'green'},
                'zscore_overbought': {'color': 'red'}
            },
            "BB Percent": {
                'bb_percent': {'color': 'purple'},
                'bb_percent_oversold': {'color': 'green'},
                'bb_percent_overbought': {'color': 'red'}
            }
        }
    }

    def informative_pairs(self):
        """
        Define additional, informative pair/interval combinations to be cached from the exchange.
        These pairs will automatically be available for use in the `populate_indicators` method.
        """
        return []

    def populate_indicators(self, dataframe: DataFrame, metadata: dict) -> DataFrame:
        """
        Adds several different TA indicators to the given DataFrame

        Performance Note: For the best performance be frugal on the number of indicators
        you are using. Let uncomment only the indicator you are using in your strategies
        or your hyperopt configuration, otherwise you will waste your memory and CPU usage.
        :param dataframe: Dataframe with data from the exchange
        :param metadata: Additional information, like the currently traded pair
        :return: a Dataframe with all mandatory indicators for the strategies
        """

        # === MEAN REVERSION INDICATORS ===
        
        # Bollinger Bands - indicateur principal pour mean reversion (avec paramètres optimisables)
        bollinger = qtpylib.bollinger_bands(dataframe['close'], window=self.bb_period.value, stds=self.bb_std.value)
        dataframe['bb_upperband'] = bollinger['upper']
        dataframe['bb_middleband'] = bollinger['mid']
        dataframe['bb_lowerband'] = bollinger['lower']
        dataframe['bb_percent'] = (dataframe['close'] - dataframe['bb_lowerband']) / (dataframe['bb_upperband'] - dataframe['bb_lowerband'])
        dataframe['bb_width'] = (dataframe['bb_upperband'] - dataframe['bb_lowerband']) / dataframe['bb_middleband']
        
        # Moyennes mobiles pour la tendance générale (avec paramètres optimisables)
        dataframe['sma_short'] = ta.SMA(dataframe, timeperiod=self.sma_short_period.value)
        dataframe['sma_long'] = ta.SMA(dataframe, timeperiod=self.sma_long_period.value)
        dataframe['ema_20'] = ta.EMA(dataframe, timeperiod=20)
        
        # RSI pour confirmer les signaux (avec paramètres optimisables)
        dataframe['rsi'] = ta.RSI(dataframe, timeperiod=self.rsi_period.value)
        dataframe['rsi_oversold'] = self.rsi_oversold.value
        dataframe['rsi_overbought'] = self.rsi_overbought.value
        
        # Z-Score pour mesurer l'écart par rapport à la moyenne (avec paramètres optimisables)
        rolling_mean = dataframe['close'].rolling(window=self.zscore_period.value).mean()
        rolling_std = dataframe['close'].rolling(window=self.zscore_period.value).std()
        dataframe['zscore'] = (dataframe['close'] - rolling_mean) / rolling_std
        dataframe['zscore_oversold'] = self.zscore_oversold.value
        dataframe['zscore_overbought'] = self.zscore_overbought.value
        
        # Williams %R pour une autre mesure de survente/surachat (avec paramètres optimisables)
        dataframe['williams_r'] = ta.WILLR(dataframe, timeperiod=self.williams_period.value)
        
        # Stochastic pour confirmer les signaux
        stoch = ta.STOCH(dataframe)
        dataframe['stoch_k'] = stoch['slowk']
        dataframe['stoch_d'] = stoch['slowd']
        
        # Volume indicators (avec paramètres optimisables)
        dataframe['volume_sma'] = dataframe['volume'].rolling(window=20).mean()
        dataframe['volume_ratio'] = dataframe['volume'] / dataframe['volume_sma']
        
        # === MEAN REVERSION SIGNALS ===
        
        # Signal de survente : Prix sous Bollinger inférieure + RSI < seuil + Z-Score < seuil
        dataframe['oversold'] = (
            (dataframe['close'] < dataframe['bb_lowerband']) &
            (dataframe['rsi'] < self.rsi_oversold.value) &
            (dataframe['zscore'] < self.zscore_oversold.value) &
            (dataframe['bb_percent'] < self.bb_oversold_threshold.value) &  # Prix dans la zone inférieure des BB
            (dataframe['williams_r'] < self.williams_oversold.value) &      # Williams %R en survente
            (dataframe['volume_ratio'] > self.volume_factor.value)          # Volume élevé
        )
        
        # Signal de surachat : Prix au-dessus Bollinger supérieure + RSI > seuil + Z-Score > seuil
        dataframe['overbought'] = (
            (dataframe['close'] > dataframe['bb_upperband']) &
            (dataframe['rsi'] > self.rsi_overbought.value) &
            (dataframe['zscore'] > self.zscore_overbought.value) &
            (dataframe['bb_percent'] > self.bb_overbought_threshold.value) &  # Prix dans la zone supérieure des BB
            (dataframe['williams_r'] > self.williams_overbought.value)        # Williams %R en surachat
        )
        
        # Confirmation de retour à la moyenne
        dataframe['reversion_signal'] = (
            (dataframe['close'] > dataframe['bb_lowerband'].shift(1)) &  # Prix remonte
            (dataframe['rsi'] > dataframe['rsi'].shift(1)) &              # RSI remonte
            (dataframe['zscore'] > dataframe['zscore'].shift(1))          # Z-Score remonte
        )
        
        # Tendance générale (pour éviter les trades contre-tendance)
        dataframe['uptrend'] = (
            (dataframe['sma_short'] > dataframe['sma_long']) &
            (dataframe['close'] > dataframe['sma_short'])
        )
        
        dataframe['downtrend'] = (
            (dataframe['sma_short'] < dataframe['sma_long']) &
            (dataframe['close'] < dataframe['sma_short'])
        )
        
        # Volatilité (éviter les périodes de faible volatilité)
        dataframe['high_volatility'] = dataframe['bb_width'] > self.min_volatility.value
        
        return dataframe

    def populate_entry_trend(self, dataframe: DataFrame, metadata: dict) -> DataFrame:
        """
        Based on TA indicators, populates the entry signal for the given dataframe
        :param dataframe: DataFrame populated with indicators
        :param metadata: Additional information, like the currently traded pair
        :return: DataFrame with entry columns populated
        """
        
        # === CONDITIONS D'ACHAT (MEAN REVERSION) - SIMPLIFIÉES ===
        
        # Achat en survente avec conditions simplifiées
        dataframe.loc[
            (
                dataframe['oversold'] &                 # Signal de survente (RSI < 40, Williams %R < -70, etc.)
                dataframe['high_volatility'] &          # Volatilité suffisante
                (dataframe['volume_ratio'] > 1.0)       # Volume normal (assoupli)
            ),
            'enter_long'] = 1

        return dataframe

    def populate_exit_trend(self, dataframe: DataFrame, metadata: dict) -> DataFrame:
        """
        Based on TA indicators, populates the exit signal for the given dataframe
        :param dataframe: DataFrame populated with indicators
        :param metadata: Additional information, like the currently traded pair
        :return: DataFrame with exit columns populated
        """
        
        # === CONDITIONS DE VENTE (MEAN REVERSION) ===
        
        # Vente en surachat ou retour vers la moyenne
        dataframe.loc[
            (
                dataframe['overbought'] |               # Signal de surachat
                (dataframe['bb_percent'] > 0.8) |      # Prix proche de la bande supérieure
                (dataframe['rsi'] > 75) |              # RSI en surachat
                (dataframe['zscore'] > 1.5) |          # Z-Score élevé
                (dataframe['close'] < dataframe['bb_middleband'])  # Prix sous la moyenne
            ),
            'exit_long'] = 1

        return dataframe

    def leverage(self, pair: str, current_time: datetime, current_rate: float,
                 proposed_leverage: float, max_leverage: float, entry_tag: Optional[str], 
                 side: str, **kwargs) -> float:
        """
        Customize leverage for each new trade. This method is only called in futures mode.
        :param pair: Pair that's currently analyzed
        :param current_time: datetime object, containing the current datetime
        :param current_rate: Rate, calculated based on pricing settings in exit_pricing.
        :param proposed_leverage: A leverage proposed by the bot.
        :param max_leverage: Max leverage allowed on this pair
        :param entry_tag: Optional entry_tag (if any)
        :param side: 'long' or 'short' - indicating the direction of the proposed trade
        :return: A leverage amount (defaults to 1.0)
        """
        return 1.0
