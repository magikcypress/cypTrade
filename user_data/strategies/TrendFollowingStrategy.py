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


class TrendFollowingStrategy(IStrategy):
    """
    Stratégie de Suivi de Tendance (Trend Following)
    
    Principe : Suivre les mouvements directionnels du marché
    - Achat quand le prix monte (tendance haussière)
    - Vente quand le prix descend (tendance baissière)
    
    Indicateurs utilisés :
    - EMA (Exponential Moving Average) pour identifier la tendance
    - MACD pour confirmer les signaux
    - RSI pour éviter les zones de survente/surachat
    """
    
    # Strategy interface version - allow new iterations of the strategy
    INTERFACE_VERSION = 3

    # Optimal timeframe for the strategy
    timeframe = '5m'

    # Can this strategy go short?
    can_short: bool = False

    # Minimal ROI designed for the strategy.
    minimal_roi = {
        "0": 0.05,    # 5% après 0 minutes
        "20": 0.03,   # 3% après 20 minutes
        "40": 0.02,   # 2% après 40 minutes
        "80": 0.01    # 1% après 80 minutes
    }

    # Optimal stoploss designed for the strategy
    stoploss = -0.04  # -4%

    # Trailing stoploss
    trailing_stop = True
    trailing_stop_positive = 0.02  # 2%
    trailing_stop_positive_offset = 0.03  # 3%

    # Run "populate_indicators" only for new candle
    process_only_new_candles = False

    # These values can be overridden in the config
    use_exit_signal = True
    exit_profit_only = False
    ignore_roi_if_entry_signal = False

    # Number of candles the strategy requires before producing valid signals
    startup_candle_count: int = 30

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
            'ema_short': {'color': 'blue'},
            'ema_long': {'color': 'red'},
            'ema_trend': {'color': 'green'},
        },
        'subplots': {
            "MACD": {
                'macd': {'color': 'blue'},
                'macdsignal': {'color': 'red'},
                'macdhist': {'type': 'bar', 'plotly': {'opacity': 0.9}}
            },
            "RSI": {
                'rsi': {'color': 'red'},
                'rsi_oversold': {'color': 'green'},
                'rsi_overbought': {'color': 'red'}
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

        # === TREND FOLLOWING INDICATORS ===
        
        # EMA pour identifier la tendance
        dataframe['ema_short'] = ta.EMA(dataframe, timeperiod=12)
        dataframe['ema_long'] = ta.EMA(dataframe, timeperiod=26)
        dataframe['ema_trend'] = ta.EMA(dataframe, timeperiod=50)
        
        # MACD pour confirmer les signaux de tendance
        macd = ta.MACD(dataframe)
        dataframe['macd'] = macd['macd']
        dataframe['macdsignal'] = macd['macdsignal']
        dataframe['macdhist'] = macd['macdhist']
        
        # RSI pour éviter les zones extrêmes
        dataframe['rsi'] = ta.RSI(dataframe, timeperiod=14)
        dataframe['rsi_oversold'] = 30
        dataframe['rsi_overbought'] = 70
        
        # Bollinger Bands pour la volatilité
        bollinger = qtpylib.bollinger_bands(dataframe['close'], window=20, stds=2)
        dataframe['bb_lowerband'] = bollinger['lower']
        dataframe['bb_middleband'] = bollinger['mid']
        dataframe['bb_upperband'] = bollinger['upper']
        dataframe['bb_percent'] = (dataframe['close'] - dataframe['bb_lowerband']) / (dataframe['bb_upperband'] - dataframe['bb_lowerband'])
        dataframe['bb_width'] = (dataframe['bb_upperband'] - dataframe['bb_lowerband']) / dataframe['bb_middleband']
        
        # Volume indicators
        dataframe['volume_sma'] = dataframe['volume'].rolling(window=20).mean()
        
        # === TREND FOLLOWING SIGNALS ===
        
        # Signal de tendance haussière : EMA courte > EMA longue > EMA tendance
        dataframe['trend_bullish'] = (
            (dataframe['ema_short'] > dataframe['ema_long']) &
            (dataframe['ema_long'] > dataframe['ema_trend'])
        )
        
        # Signal de tendance baissière : EMA courte < EMA longue < EMA tendance
        dataframe['trend_bearish'] = (
            (dataframe['ema_short'] < dataframe['ema_long']) &
            (dataframe['ema_long'] < dataframe['ema_trend'])
        )
        
        # MACD bullish : MACD > Signal et MACD croissant
        dataframe['macd_bullish'] = (
            (dataframe['macd'] > dataframe['macdsignal']) &
            (dataframe['macd'] > dataframe['macd'].shift(1))
        )
        
        # MACD bearish : MACD < Signal et MACD décroissant
        dataframe['macd_bearish'] = (
            (dataframe['macd'] < dataframe['macdsignal']) &
            (dataframe['macd'] < dataframe['macd'].shift(1))
        )
        
        # Volume confirmation
        dataframe['volume_high'] = dataframe['volume'] > dataframe['volume_sma'] * 1.2
        
        return dataframe

    def populate_entry_trend(self, dataframe: DataFrame, metadata: dict) -> DataFrame:
        """
        Based on TA indicators, populates the entry signal for the given dataframe
        :param dataframe: DataFrame populated with indicators
        :param metadata: Additional information, like the currently traded pair
        :return: DataFrame with entry columns populated
        """
        
        # === CONDITIONS D'ACHAT (TREND FOLLOWING) ===
        
        # Condition principale : Tendance haussière + MACD bullish + Volume élevé
        dataframe.loc[
            (
                dataframe['trend_bullish'] &           # Tendance haussière
                dataframe['macd_bullish'] &            # MACD bullish
                dataframe['volume_high'] &             # Volume élevé
                (dataframe['rsi'] > 40) &              # RSI pas en survente
                (dataframe['rsi'] < 80) &              # RSI pas en surachat
                (dataframe['close'] > dataframe['bb_middleband']) &  # Prix au-dessus de la moyenne
                (dataframe['bb_width'] > 0.02)         # Volatilité suffisante
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
        
        # === CONDITIONS DE VENTE (TREND FOLLOWING) ===
        
        # Vente quand la tendance se retourne ou MACD devient bearish
        dataframe.loc[
            (
                dataframe['trend_bearish'] |           # Tendance baissière
                dataframe['macd_bearish'] |            # MACD bearish
                (dataframe['rsi'] > 85) |              # RSI en surachat extrême
                (dataframe['close'] < dataframe['bb_lowerband'])  # Prix sous Bollinger inférieure
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
