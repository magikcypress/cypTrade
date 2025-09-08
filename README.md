# CypTrade - FreqTrad Configuration

Ce projet configure FreqTrad pour le trading algorithmique avec des stratégies personnalisées.

## 🚀 Installation

### Prérequis

- Python 3.8 ou supérieur
- pip (gestionnaire de paquets Python)

### Installation des dépendances

```bash
# Cloner le projet (si nécessaire)
cd /Users/cyp/Documents/work/blockchain/cypTrade

# Créer un environnement virtuel (recommandé)
python -m venv venv
source venv/bin/activate  # Sur macOS/Linux
# ou
venv\Scripts\activate  # Sur Windows

# Installer les dépendances
pip install -r requirements.txt
```

### Installation de TA-Lib

TA-Lib nécessite une installation spéciale :

**Sur macOS (avec Homebrew):**

```bash
brew install ta-lib
pip install TA-Lib
```

**Sur Ubuntu/Debian:**

```bash
sudo apt-get install libta-lib-dev
pip install TA-Lib
```

**Sur Windows:**
Téléchargez le wheel approprié depuis [https://www.lfd.uci.edu/~gohlke/pythonlibs/#ta-lib](https://www.lfd.uci.edu/~gohlke/pythonlibs/#ta-lib)

## ⚙️ Configuration

1. **Copier le fichier d'environnement :**

```bash
cp env.example .env
```

2. **Configurer vos clés API :**
Éditez le fichier `.env` et ajoutez vos clés d'échange :

```env
EXCHANGE_KEY=your_exchange_api_key_here
EXCHANGE_SECRET=your_exchange_secret_here
JWT_SECRET=your_jwt_secret_here
```

3. **Configurer l'échange :**
Éditez `config.json` pour configurer votre échange préféré (Binance par défaut).

## 📊 Utilisation

### Mode Dry Run (Test)

```bash
freqtrade trade --config config.json --strategy SampleStrategy
```

### Mode Live (Attention !)

```bash
freqtrade trade --config config.json --strategy SampleStrategy
```

### Backtesting

```bash
freqtrade backtesting --config config.json --strategy SampleStrategy --timerange 20231201-20231231
```

### Hyperopt (Optimisation des paramètres)

```bash
freqtrade hyperopt --config config.json --strategy SampleStrategy --hyperopt-loss SharpeHyperOptLoss --epochs 100
```

### Interface Web

```bash
freqtrade trade --config config.json --strategy SampleStrategy --api-server
```

Puis ouvrez <http://localhost:8080> dans votre navigateur.

### Bot Telegram

```bash
freqtrade trade --config config.json --strategy SampleStrategy
```

Configurez votre bot Telegram pour recevoir des notifications de trading. Voir [TELEGRAM_SETUP.md](TELEGRAM_SETUP.md) pour la configuration détaillée.

## 📁 Structure du Projet

```
cypTrade/
├── config.json                 # Configuration principale
├── freqtrade_hyperopt.json    # Configuration hyperopt
├── requirements.txt            # Dépendances Python
├── env.example                 # Variables d'environnement (exemple)
├── TELEGRAM_SETUP.md          # Guide configuration Telegram
├── README.md                   # Ce fichier
├── docker-compose.yml          # Configuration Docker
├── scripts/
│   └── install.sh             # Script d'installation
└── user_data/
    └── strategies/
        └── SampleStrategy.py   # Stratégie d'exemple
```

## 🎯 Stratégies

### SampleStrategy

Stratégie d'exemple basée sur :

- RSI (Relative Strength Index)
- Bollinger Bands
- MACD
- Conditions d'entrée : RSI < 30 et prix sous la bande inférieure de Bollinger
- Conditions de sortie : RSI > 70 et prix au-dessus de la bande supérieure de Bollinger

### Créer une nouvelle stratégie

1. Copiez `SampleStrategy.py` vers un nouveau fichier
2. Renommez la classe
3. Modifiez les paramètres selon vos besoins
4. Testez avec le mode dry run

## 🔧 Commandes Utiles

### Voir les paires disponibles

```bash
freqtrade list-pairs --config config.json --exchange binance
```

### Tester une stratégie

```bash
freqtrade test-pairlist --config config.json --strategy SampleStrategy
```

### Voir les trades

```bash
freqtrade show-trades --config config.json
```

### Voir les performances

```bash
freqtrade show-trades --config config.json --show-trades
```

## 📱 Notifications Telegram

Le bot est configuré pour envoyer des notifications sur :

- **Entrées de position** : Signaux d'achat et exécution
- **Sorties de position** : Signaux de vente et exécution
- **Gestion des risques** : Stop-loss et protections
- **Statut du bot** : Démarrage, arrêt, erreurs

### Commandes Telegram disponibles

- `/daily` - Performance du jour
- `/profit` - Profits actuels
- `/balance` - Solde du portefeuille
- `/trades` - Liste des trades récents
- `/stats` - Statistiques de trading
- `/whitelist` - Paires tradées
- `/blacklist` - Paires bloquées
- `/status` - Statut du bot
- `/performance` - Performance détaillée

Voir [TELEGRAM_SETUP.md](TELEGRAM_SETUP.md) pour la configuration complète.

## ⚠️ Avertissements

- **Toujours tester en mode dry run avant le trading live**
- **Ne jamais investir plus que ce que vous pouvez perdre**
- **Les performances passées ne garantissent pas les résultats futurs**
- **Gardez vos clés API sécurisées**

## 📚 Documentation

- [Documentation FreqTrad](https://www.freqtrade.io/)
- [Guide des stratégies](https://www.freqtrade.io/en/latest/strategy-customization/)
- [Indicateurs techniques](https://www.freqtrade.io/en/latest/strategy-customization/#technical-indicators)

## 🤝 Contribution

1. Fork le projet
2. Créez une branche pour votre fonctionnalité
3. Committez vos changements
4. Poussez vers la branche
5. Ouvrez une Pull Request

## 📄 Licence

Ce projet est sous licence MIT. Voir le fichier LICENSE pour plus de détails.
