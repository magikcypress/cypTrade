import numpy as np
import pandas as pd
from pandas import DataFrame
from datetime import datetime
from typing import Optional, Union

from freqtrade.strategy import IStrategy
import talib.abstract as ta

class MultiExchangeStrategy(IStrategy):
    """
    Stratégie multi-exchange qui peut trader sur Binance (USDT) et Hyperliquid (USDC)
    avec des configurations adaptées à chaque exchange
    """
    INTERFACE_VERSION = 3

    # ROI global
    minimal_roi = {
        "0": 0.03,
        "20": 0.02,
        "40": 0.01,
        "80": 0.005
    }

    # Stop loss global
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

    # Configuration par exchange
    exchange_configs = {
        'binance': {
            'stake_currency': 'USDT',
            'pairs': ['BTC/USDT', 'ETH/USDT', 'BNB/USDT', 'ADA/USDT', 'SOL/USDT', 'DOT/USDT', 'LINK/USDT', 'MATIC/USDT'],
            'max_trades': 3,
            'rsi_period': 14,
            'rsi_low': 30,
            'rsi_high': 70,
            'ema_fast': 12,
            'ema_slow': 26,
            'volume_factor': 1.5,
            'stoploss': -0.04,
            'risk_level': 'conservative'
        },
        'hyperliquid': {
            'stake_currency': 'USDC',
            'pairs': ['COPE/USDC', 'PURR/USDC', 'BONK/USDC', 'WIF/USDC', 'PEPE/USDC', 'FLOKI/USDC', 'DOGE/USDC', 'SHIB/USDC'],
            'max_trades': 2,
            'rsi_period': 10,
            'rsi_low': 25,
            'rsi_high': 75,
            'ema_fast': 8,
            'ema_slow': 21,
            'volume_factor': 2.0,
            'stoploss': -0.03,
            'risk_level': 'aggressive'
        }
    }

    def get_exchange_config(self, pair: str) -> dict:
        """Détermine la configuration selon la paire de trading"""
        if '/USDT' in pair:
            return self.exchange_configs['binance']
        elif '/USDC' in pair:
            return self.exchange_configs['hyperliquid']
        else:
            # Configuration par défaut pour Binance
            return self.exchange_configs['binance']

    def populate_indicators(self, dataframe: DataFrame, metadata: dict) -> DataFrame:
        """
        Calcule les indicateurs techniques avec configuration adaptée à l'exchange
        """
        pair = metadata['pair']
        config = self.get_exchange_config(pair)
        
        # RSI avec période adaptée à l'exchange
        dataframe['rsi'] = ta.RSI(dataframe, timeperiod=config['rsi_period'])
        
        # EMA avec périodes adaptées
        dataframe['ema_fast'] = ta.EMA(dataframe, timeperiod=config['ema_fast'])
        dataframe['ema_slow'] = ta.EMA(dataframe, timeperiod=config['ema_slow'])
        
        # Volume avec facteur adapté
        dataframe['volume_ma'] = ta.SMA(dataframe['volume'], timeperiod=20)
        dataframe['volume_threshold'] = dataframe['volume_ma'] * config['volume_factor']
        
        # MACD
        dataframe['macd'], dataframe['macdsignal'], dataframe['macdhist'] = ta.MACD(dataframe['close'])
        
        # Bollinger Bands
        dataframe['bb_upper'], dataframe['bb_middle'], dataframe['bb_lower'] = ta.BBANDS(dataframe['close'])
        
        # Stoch
        dataframe['stoch_k'], dataframe['stoch_d'] = ta.STOCH(dataframe['high'], dataframe['low'], dataframe['close'])
        
        # ATR pour la volatilité
        dataframe['atr'] = ta.ATR(dataframe['high'], dataframe['low'], dataframe['close'], timeperiod=14)
        
        # Williams %R
        dataframe['williams_r'] = ta.WILLR(dataframe['high'], dataframe['low'], dataframe['close'], timeperiod=14)
        
        return dataframe

    def populate_entry_trend(self, dataframe: DataFrame, metadata: dict) -> DataFrame:
        """
        Conditions d'entrée adaptées à l'exchange
        """
        pair = metadata['pair']
        config = self.get_exchange_config(pair)
        
        # Conditions d'entrée pour Binance (conservateur)
        if config['risk_level'] == 'conservative':
            dataframe.loc[
                (
                    # Croisement EMA
                    (dataframe['ema_fast'] > dataframe['ema_slow']) &
                    (dataframe['ema_fast'].shift(1) <= dataframe['ema_slow'].shift(1)) &
                    
                    # RSI dans la zone d'achat
                    (dataframe['rsi'] < config['rsi_high']) &
                    (dataframe['rsi'] > config['rsi_low']) &
                    
                    # Volume suffisant
                    (dataframe['volume'] > dataframe['volume_threshold']) &
                    
                    # MACD positif
                    (dataframe['macd'] > dataframe['macdsignal']) &
                    
                    # Prix au-dessus de la moyenne mobile
                    (dataframe['close'] > dataframe['bb_middle']) &
                    
                    # Williams %R en zone de survente
                    (dataframe['williams_r'] < -20) &
                    (dataframe['williams_r'] > -80) &
                    
                    # Bougie haussière
                    (dataframe['close'] > dataframe['open']) &
                    (dataframe['close'] > dataframe['close'].shift(1)) &
                    
                    # Volume positif
                    (dataframe['volume'] > 0)
                ),
                'enter_long'] = 1
        
        # Conditions d'entrée pour Hyperliquid (agressif)
        elif config['risk_level'] == 'aggressive':
            dataframe.loc[
                (
                    # Croisement EMA plus sensible
                    (dataframe['ema_fast'] > dataframe['ema_slow']) &
                    
                    # RSI dans la zone d'achat (plus large)
                    (dataframe['rsi'] < config['rsi_high']) &
                    (dataframe['rsi'] > config['rsi_low']) &
                    
                    # Volume élevé (marchés volatils)
                    (dataframe['volume'] > dataframe['volume_threshold']) &
                    
                    # MACD positif
                    (dataframe['macd'] > dataframe['macdsignal']) &
                    
                    # Stoch en zone de survente
                    (dataframe['stoch_k'] < 80) &
                    (dataframe['stoch_k'] > 20) &
                    
                    # Williams %R en zone de survente
                    (dataframe['williams_r'] < -10) &
                    (dataframe['williams_r'] > -90) &
                    
                    # Bougie haussière
                    (dataframe['close'] > dataframe['open']) &
                    
                    # Volume positif
                    (dataframe['volume'] > 0)
                ),
                'enter_long'] = 1

        return dataframe

    def populate_exit_trend(self, dataframe: DataFrame, metadata: dict) -> DataFrame:
        """
        Conditions de sortie adaptées à l'exchange
        """
        pair = metadata['pair']
        config = self.get_exchange_config(pair)
        
        # Conditions de sortie pour Binance (conservateur)
        if config['risk_level'] == 'conservative':
            dataframe.loc[
                (
                    # RSI en zone de surachat
                    (dataframe['rsi'] > config['rsi_high']) |
                    
                    # Croisement EMA inverse
                    (dataframe['ema_fast'] < dataframe['ema_slow']) &
                    (dataframe['ema_fast'].shift(1) >= dataframe['ema_slow'].shift(1)) |
                    
                    # MACD négatif
                    (dataframe['macd'] < dataframe['macdsignal']) |
                    
                    # Prix en dessous de la moyenne mobile
                    (dataframe['close'] < dataframe['bb_middle']) |
                    
                    # Williams %R en zone de surachat
                    (dataframe['williams_r'] > -20)
                ),
                'exit_long'] = 1
        
        # Conditions de sortie pour Hyperliquid (agressif)
        elif config['risk_level'] == 'aggressive':
            dataframe.loc[
                (
                    # RSI en zone de surachat
                    (dataframe['rsi'] > config['rsi_high']) |
                    
                    # Croisement EMA inverse
                    (dataframe['ema_fast'] < dataframe['ema_slow']) &
                    (dataframe['ema_fast'].shift(1) >= dataframe['ema_slow'].shift(1)) |
                    
                    # MACD négatif
                    (dataframe['macd'] < dataframe['macdsignal']) |
                    
                    # Stoch en zone de surachat
                    (dataframe['stoch_k'] > 80) |
                    
                    # Williams %R en zone de surachat
                    (dataframe['williams_r'] > -10)
                ),
                'exit_long'] = 1

        return dataframe

    def custom_stoploss(self, pair: str, trade: 'Trade', current_time: datetime,
                        current_rate: float, current_profit: float, **kwargs) -> float:
        """
        Stop loss personnalisé selon l'exchange
        """
        config = self.get_exchange_config(pair)
        return config['stoploss']

    def custom_exit(self, pair: str, trade: 'Trade', current_time: datetime, current_rate: float,
                    current_profit: float, **kwargs) -> Optional[Union[str, bool]]:
        """
        Sortie personnalisée selon l'exchange
        """
        config = self.get_exchange_config(pair)
        
        # Sortie plus rapide pour Hyperliquid (marchés volatils)
        if config['risk_level'] == 'aggressive':
            if current_profit > 0.05:  # 5% de profit
                return "profit_target_aggressive"
        elif config['risk_level'] == 'conservative':
            if current_profit > 0.08:  # 8% de profit
                return "profit_target_conservative"
        
        return None

    def leverage(self, pair: str, current_time: datetime, current_rate: float,
                 proposed_leverage: float, max_leverage: float, entry_tag: Optional[str],
                 side: str, **kwargs) -> float:
        """
        Gestion du levier selon l'exchange
        """
        config = self.get_exchange_config(pair)
        
        # Pas de levier pour les marchés spot
        return 1.0
