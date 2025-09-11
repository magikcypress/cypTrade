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
from freqtrade.strategy import (BooleanParameter, CategoricalParameter, DecimalParameter,
                                IntParameter, IStrategy, merge_informative_pair)

# --------------------------------
# Add your lib to import here
import talib.abstract as ta
from freqtrade.strategy import IStrategy, merge_informative_pair
from freqtrade.strategy import (BooleanParameter, CategoricalParameter, DecimalParameter,
                                IntParameter, IStrategy, merge_informative_pair)
import freqtrade.vendor.qtpylib.indicators as qtpylib


class BalancedAdvancedStrategy(IStrategy):
    """
    Stratégie avancée équilibrée pour Freqtrade
    Optimisée pour le trading sur paires USDC avec gestion des risques
    """

    INTERFACE_VERSION = 3

    # Configuration de base
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

    # Paramètres de trading
    max_open_trades = 3
    stake_currency = 'USDC'
    stake_amount = 'unlimited'

    # Paramètres de la stratégie
    fast_ma_length = IntParameter(5, 15, default=8, space="buy")
    slow_ma_length = IntParameter(20, 50, default=21, space="buy")
    rsi_buy_threshold = IntParameter(20, 40, default=30, space="buy")
    rsi_sell_threshold = IntParameter(60, 80, default=70, space="sell")
    volume_factor = DecimalParameter(1.0, 3.0, default=1.5, space="buy")
    profit_threshold = DecimalParameter(0.02, 0.10, default=0.05, space="sell")

    # Paramètres de gestion des risques
    use_stop_loss = BooleanParameter(default=True, space="protection")
    use_trailing_stop = BooleanParameter(default=True, space="protection")
    
    # Paramètres de trailing stop (utiliser des attributs de classe pour éviter les problèmes de validation)
    trailing_stop_positive_value = 0.02
    trailing_stop_positive_offset_value = 0.04

    def informative_pairs(self):
        """
        Définit les paires informatives supplémentaires
        """
        pairs = self.dp.current_whitelist()
        informative_pairs = []
        for pair in pairs:
            for timeframe in self.informative_timeframes:
                informative_pairs.append((pair, timeframe))
        return informative_pairs

    def populate_indicators(self, dataframe: DataFrame, metadata: dict) -> DataFrame:
        """
        Ajoute les indicateurs techniques à la dataframe
        """
        # Moyennes mobiles
        dataframe['ema_fast'] = ta.EMA(dataframe, timeperiod=self.fast_ma_length.value)
        dataframe['ema_slow'] = ta.EMA(dataframe, timeperiod=self.slow_ma_length.value)
        dataframe['sma_20'] = ta.SMA(dataframe, timeperiod=20)
        dataframe['sma_50'] = ta.SMA(dataframe, timeperiod=50)

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
        dataframe['bb_middleband'] = bollinger['mid']
        dataframe['bb_upperband'] = bollinger['upper']
        dataframe['bb_percent'] = (dataframe['close'] - dataframe['bb_lowerband']) / (dataframe['bb_upperband'] - dataframe['bb_lowerband'])
        dataframe['bb_width'] = (dataframe['bb_upperband'] - dataframe['bb_lowerband']) / dataframe['bb_middleband']

        # Volume
        dataframe['volume_mean'] = dataframe['volume'].rolling(window=20).mean()
        dataframe['volume_ratio'] = dataframe['volume'] / dataframe['volume_mean']

        # ATR pour le stop loss dynamique
        dataframe['atr'] = ta.ATR(dataframe, timeperiod=14)
        dataframe['atr_percent'] = (dataframe['atr'] / dataframe['close']) * 100

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

        # Indicateurs de momentum
        dataframe['momentum'] = ta.MOM(dataframe, timeperiod=10)
        dataframe['roc'] = ta.ROC(dataframe, timeperiod=10)

        # Support et résistance
        dataframe['support'] = dataframe['low'].rolling(window=20).min()
        dataframe['resistance'] = dataframe['high'].rolling(window=20).max()

        # Tendance
        dataframe['trend'] = np.where(dataframe['ema_fast'] > dataframe['ema_slow'], 1, -1)
        dataframe['trend_strength'] = abs(dataframe['ema_fast'] - dataframe['ema_slow']) / dataframe['ema_slow']

        # Volatilité
        dataframe['volatility'] = dataframe['close'].pct_change().rolling(window=20).std()

        # Indicateurs de volume
        dataframe['obv'] = ta.OBV(dataframe)
        dataframe['mfi'] = ta.MFI(dataframe, timeperiod=14)

        # Ajout des données informatives
        for timeframe in self.informative_timeframes:
            try:
                informative = self.dp.get_pair_dataframe(pair=metadata['pair'], timeframe=timeframe)
                
                if informative is not None and len(informative) > 0:
                    # RSI sur timeframe supérieur
                    informative[f'rsi_{timeframe}'] = ta.RSI(informative, timeperiod=14)
                    
                    # Moyennes mobiles sur timeframe supérieur
                    informative[f'ema_fast_{timeframe}'] = ta.EMA(informative, timeperiod=8)
                    informative[f'ema_slow_{timeframe}'] = ta.EMA(informative, timeperiod=21)
                    
                    # Tendance sur timeframe supérieur
                    informative[f'trend_{timeframe}'] = np.where(
                        informative[f'ema_fast_{timeframe}'] > informative[f'ema_slow_{timeframe}'], 1, -1
                    )
                    
                    # Merge des données informatives
                    dataframe = merge_informative_pair(dataframe, informative, self.timeframe, timeframe, ffill=True)
                else:
                    # Créer des colonnes par défaut si les données ne sont pas disponibles
                    dataframe[f'rsi_{timeframe}'] = 50  # Valeur neutre
                    dataframe[f'ema_fast_{timeframe}'] = dataframe['close']
                    dataframe[f'ema_slow_{timeframe}'] = dataframe['close']
                    dataframe[f'trend_{timeframe}'] = 0  # Valeur neutre
            except Exception as e:
                # En cas d'erreur, créer des colonnes par défaut
                dataframe[f'rsi_{timeframe}'] = 50  # Valeur neutre
                dataframe[f'ema_fast_{timeframe}'] = dataframe['close']
                dataframe[f'ema_slow_{timeframe}'] = dataframe['close']
                dataframe[f'trend_{timeframe}'] = 0  # Valeur neutre

        return dataframe

    def populate_entry_trend(self, dataframe: DataFrame, metadata: dict) -> DataFrame:
        """
        Définit les conditions d'entrée
        """
        # Conditions de base
        dataframe.loc[
            (
                # Tendance haussière
                (dataframe['ema_fast'] > dataframe['ema_slow']) &
                (dataframe['close'] > dataframe['ema_fast']) &
                
                # RSI dans la zone de survente
                (dataframe['rsi'] < self.rsi_buy_threshold.value) &
                (dataframe['rsi'] > 20) &
                
                # MACD positif
                (dataframe['macd'] > dataframe['macdsignal']) &
                (dataframe['macdhist'] > 0) &
                
                # Prix proche de la bande inférieure de Bollinger
                (dataframe['close'] < dataframe['bb_middleband']) &
                (dataframe['bb_percent'] < 0.3) &
                
                # Volume élevé
                (dataframe['volume_ratio'] > self.volume_factor.value) &
                
                # Momentum positif
                (dataframe['momentum'] > 0) &
                (dataframe['roc'] > 0) &
                
                # Stochastic dans la zone de survente
                (dataframe['stoch_k'] < 30) &
                (dataframe['stoch_d'] < 30) &
                
                # Williams %R dans la zone de survente
                (dataframe['williams_r'] < -70) &
                
                # CCI dans la zone de survente
                (dataframe['cci'] < -100) &
                
                # ADX indique une tendance forte
                (dataframe['adx'] > 25) &
                
                # Prix au-dessus du support
                (dataframe['close'] > dataframe['support']) &
                
                # Tendance sur timeframe supérieur positive (avec vérification de sécurité)
                (dataframe.get('trend_1h', 0) > 0) &
                (dataframe.get('trend_4h', 0) > 0) &
                
                # RSI sur timeframe supérieur pas en survente extrême (avec vérification de sécurité)
                (dataframe.get('rsi_1h', 50) > 30) &
                (dataframe.get('rsi_4h', 50) > 30) &
                
                # Volatilité acceptable
                (dataframe['volatility'] < 0.05) &
                
                # MFI dans la zone de survente
                (dataframe['mfi'] < 30) &
                
                # Pas de divergence négative
                (dataframe['close'] > dataframe['close'].shift(1)) &
                
                # Confirmation de volume
                (dataframe['obv'] > dataframe['obv'].shift(1))
            ),
            'enter_long'] = 1

        return dataframe

    def populate_exit_trend(self, dataframe: DataFrame, metadata: dict) -> DataFrame:
        """
        Définit les conditions de sortie
        """
        # Sortie sur profit
        dataframe.loc[
            (
                # RSI en survente
                (dataframe['rsi'] > self.rsi_sell_threshold.value) |
                
                # Prix proche de la bande supérieure de Bollinger
                (dataframe['bb_percent'] > 0.8) |
                
                # MACD négatif
                (dataframe['macd'] < dataframe['macdsignal']) |
                
                # Prix proche de la résistance
                (dataframe['close'] > dataframe['resistance'] * 0.98) |
                
                # Profit atteint
                (dataframe['close'] > dataframe['open'] * (1 + self.profit_threshold.value)) |
                
                # Tendance change
                (dataframe['ema_fast'] < dataframe['ema_slow']) |
                
                # Volume faible
                (dataframe['volume_ratio'] < 0.5) |
                
                # Stochastic en survente
                (dataframe['stoch_k'] > 70) &
                (dataframe['stoch_d'] > 70) |
                
                # Williams %R en survente
                (dataframe['williams_r'] > -30) |
                
                # CCI en survente
                (dataframe['cci'] > 100) |
                
                # Tendance sur timeframe supérieur négative (avec vérification de sécurité)
                (dataframe.get('trend_1h', 0) < 0) |
                
                # RSI sur timeframe supérieur en survente (avec vérification de sécurité)
                (dataframe.get('rsi_1h', 50) > 70) |
                
                # Volatilité élevée
                (dataframe['volatility'] > 0.08) |
                
                # MFI en survente
                (dataframe['mfi'] > 70) |
                
                # Divergence négative
                (dataframe['close'] < dataframe['close'].shift(1)) &
                (dataframe['rsi'] > dataframe['rsi'].shift(1))
            ),
            'exit_long'] = 1

        return dataframe

    def custom_stoploss(self, pair: str, trade: 'Trade', current_time: datetime,
                        current_rate: float, current_profit: float, **kwargs) -> float:
        """
        Stop loss personnalisé avec trailing stop
        """
        # Vérifier si les paramètres sont initialisés
        try:
            use_stop_loss = self.use_stop_loss.value
            use_trailing_stop = self.use_trailing_stop.value
        except (AttributeError, TypeError):
            # Utiliser les valeurs par défaut si les paramètres ne sont pas initialisés
            use_stop_loss = True
            use_trailing_stop = True

        if not use_stop_loss:
            return self.stoploss

        # Stop loss de base
        stop_loss = self.stoploss

        # Trailing stop si activé
        if use_trailing_stop and current_profit > self.trailing_stop_positive_value:
            stop_loss = -self.trailing_stop_positive_offset_value

        return stop_loss

    def custom_exit(self, pair: str, trade: 'Trade', current_time: datetime, current_rate: float,
                    current_profit: float, **kwargs) -> Optional[Union[str, bool]]:
        """
        Sortie personnalisée
        """
        # Sortie sur profit élevé
        if current_profit > 0.15:  # 15% de profit
            return "profit_target"

        # Sortie sur perte limitée
        if current_profit < -0.05:  # -5% de perte
            return "stop_loss"

        # Sortie sur temps (éviter les positions trop longues)
        if trade.open_date_utc and (current_time - trade.open_date_utc).days > 7:
            return "time_exit"

        return None

    def leverage(self, pair: str, current_time: datetime, current_rate: float,
                 proposed_leverage: float, max_leverage: float, entry_tag: Optional[str], 
                 side: str, **kwargs) -> float:
        """
        Gestion du levier (pour le trading sur marge)
        """
        return 1.0  # Pas de levier pour le spot trading

    def confirm_trade_entry(self, pair: str, order_type: str, amount: float, rate: float,
                           time_in_force: str, current_time: datetime, entry_tag: Optional[str],
                           side: str, **kwargs) -> bool:
        """
        Confirmation finale avant l'entrée
        """
        # Vérifier que le volume est suffisant
        dataframe, _ = self.dp.get_analyzed_dataframe(pair, self.timeframe)
        if len(dataframe) < 1:
            return False

        last_candle = dataframe.iloc[-1]
        
        # Volume minimum requis
        if last_candle['volume'] < 1000:  # Volume minimum
            return False

        # Spread maximum acceptable
        if hasattr(last_candle, 'spread') and last_candle['spread'] > 0.001:  # 0.1% de spread max
            return False

        return True

    def confirm_trade_exit(self, pair: str, trade: 'Trade', order_type: str, amount: float,
                          rate: float, time_in_force: str, exit_reason: str,
                          current_time: datetime, **kwargs) -> bool:
        """
        Confirmation finale avant la sortie
        """
        # Toujours confirmer la sortie
        return True
