# CypTrade - FreqTrad Configuration

Ce projet configure FreqTrad pour le trading algorithmique avec des stratégies personnalisées et une interface web complète.

## 🚀 Installation Rapide

### Installation Locale (macOS/Linux)

```bash
# 1. Cloner le projet
git clone <repository-url>
cd cypTrade

# 2. Créer l'environnement virtuel
python3 -m venv venv
source venv/bin/activate

# 3. Installer FreqTrad (sans utiliser /tmp)
mkdir -p ~/.pip-temp
export TMPDIR="$HOME/.pip-temp"
export TEMP="$HOME/.pip-temp"
export TMP="$HOME/.pip-temp"

pip install freqtrade --no-cache-dir

# 4. Installer l'interface web (OBLIGATOIRE)
freqtrade install-ui

# 5. Configurer les variables d'environnement
cp .env.example .env
# Éditer .env avec vos clés API
```

### Installation Automatique

```bash
# Rendre le script exécutable
chmod +x start-bot.sh

# Démarrer le bot
./start-bot.sh
```

## ⚠️ IMPORTANT - Ordre d'Installation

**L'interface web FreqUI DOIT être installée avant d'utiliser les scripts de trading !**

1. **D'abord** : Installer l'interface web avec `freqtrade install-ui`
2. **Ensuite** : Utiliser `start-bot.sh` ou `stop-bot.sh` pour trader
3. **Optionnel** : Utiliser `start-webserver.sh` pour l'interface web uniquement

## ⚙️ Configuration

### 1. Variables d'Environnement

Créez un fichier `.env` avec vos clés API :

```env
# FreqTrad Configuration
# Copy this file to .env and fill in your actual values

# Exchange API Keys
BINANCE_API_KEY=your_exchange_api_key_here
BINANCE_SECRET=your_exchange_secret_here

# Telegram Bot Configuration
TELEGRAM_TOKEN=your_telegram_bot_token_here
TELEGRAM_CHAT_ID=your_telegram_chat_id_here

# API Server Configuration (optional)
API_USERNAME=your_api_username_here
API_PASSWORD=your_api_password_here
JWT_SECRET=your_jwt_secret_here

# Database
DATABASE_URL=sqlite:///tradesv3.sqlite

# Other settings
DRY_RUN=true

DOMAINE_NAME=example.com
```

### 2. Configuration Principale

Le fichier `config.json` est pré-configuré avec :

- **Échange** : Binance
- **Devise de base** : USDT
- **Mode** : Dry Run (simulation)
- **Timeframe** : 5 minutes
- **Paires** : BTC/USDT, ETH/USDT, BNB/USDT, ADA/USDT, SOL/USDT, DOT/USDT, LINK/USDT, MATIC/USDT
- **API Server** : Activé sur le port 8080
- **Interface Web** : FreqUI intégrée

Le fichier `config-usdt.json` contient une configuration étendue avec plus de paires USDT.

## Download data

```bash
freqtrade download-data --exchange binance --config config.json --timerange 20180101-20250131 --timeframe 1m 5m 1d 4h 1h
```

## 🎯 Stratégies Disponibles

### 1. HyperoptWorking ⭐ (Recommandée)

**Stratégie optimisée pour l'hyperopt** - La plus performante du projet :

- **Paramètres optimisables** : RSI, EMA, Volume, MACD
- **Hyperopt intégré** : Optimisation automatique des paramètres
- **Performance** : 175 trades en 60 jours, Win Rate 31.4%
- **Génère des trades** : Contrairement aux autres stratégies simples
- **Facile à utiliser** : Scripts d'optimisation prêts à l'emploi

**Utilisation :**

```bash
# Test rapide (10 epochs)
./test-hyperopt.sh

# Hyperopt standard (100 epochs)
./run-hyperopt.sh

# Hyperopt complet (500 epochs)
./run-hyperopt.sh --epochs 500

# Voir les résultats
./show-hyperopt-results.sh

# Appliquer les meilleurs paramètres
./apply-best-params.sh
```

#### Exemple de commande

```bash
freqtrade hyperopt \
  --config config.json \
  --hyperopt-loss MultiMetricHyperOptLoss \
  --strategy HyperoptWorking \
  --timerange 20240101-20241201 \
  -e 500 \
  --spaces buy sell roi \
  --min-trades 50
```

ou

```bash
freqtrade hyperopt \ 
  --config config.json \
  --hyperopt-loss MultiMetricHyperOptLoss \
  --strategy HyperoptWorking   \
  -e 100  \
  --spaces buy sel roi
```

## 🖥️ Interface Web

### Démarrage de l'Interface

```bash
# Démarrer FreqTrad avec l'interface web
./start-webserver.sh

# Ou manuellement
source venv/bin/activate
freqtrade trade --config config.json --strategy SampleStrategy
```

### Accès à l'Interface

- **URL** : <http://localhost:8080>
- **Identifiants** :
  - Utilisateur : `admin`
  - Mot de passe : `NouveauMotDePasse2025!`

### Fonctionnalités de l'Interface

- 📊 **Dashboard** : Vue d'ensemble du trading
- 📈 **Graphiques** : Analyse technique en temps réel
- 🔄 **Backtesting** : Test des stratégies sur données historiques
- ⚙️ **Configuration** : Gestion des paramètres
- 📱 **Notifications** : Alertes et rapports

## 🤖 Gestion du Bot

### ⚠️ PRÉREQUIS OBLIGATOIRE

**Avant d'utiliser les scripts de trading, vous DEVEZ installer l'interface web :**

```bash
# 1. Activer l'environnement virtuel
source venv/bin/activate

# 2. Installer l'interface web FreqUI (OBLIGATOIRE)
freqtrade install-ui

# 3. Maintenant vous pouvez utiliser les scripts de trading
```

### Scripts de Contrôle du Bot

#### Démarrage du Bot

```bash
# Mode interactif (recommandé)
./start-bot.sh

# Mode avec arguments
./start-bot.sh SampleStrategy dry-run
./start-bot.sh PowerTowerStrategy live

# Aide
./start-bot.sh --help
```

**Fonctionnalités du script `start-bot.sh` :**

- 🎯 **Choix de stratégie** : Liste automatiquement toutes les stratégies disponibles
- 🔄 **Choix de mode** : Dry-run (simulation) ou Live (trading réel)
- ⚙️ **Configuration dynamique** : Crée une config spécifique pour chaque combinaison
- 🛡️ **Sécurité** : Avertissements pour le mode live
- 🔍 **Vérifications** : Contrôles complets avant démarrage

#### Arrêt du Bot

```bash
# Arrêt normal
./stop-bot.sh

# Arrêt forcé
./stop-bot.sh --force

# Voir le statut
./stop-bot.sh --status

# Voir les logs
./stop-bot.sh --logs

# Aide
./stop-bot.sh --help
```

**Fonctionnalités du script `stop-bot.sh` :**

- 🛑 **Arrêt propre** : Utilise SIGTERM par défaut, SIGKILL si forcé
- 📊 **Statut** : Affiche les processus FreqTrad en cours
- 📋 **Logs** : Affiche les derniers logs
- 🧹 **Nettoyage** : Supprime les fichiers temporaires et de verrouillage
- 📈 **Résumé** : Affiche un résumé de l'état du système

### Exemples d'Utilisation

```bash
# 1. D'ABORD : Installer l'interface web
source venv/bin/activate
freqtrade install-ui

# 2. ENSUITE : Utiliser les scripts de trading
./start-bot.sh
# Choisir la stratégie et le mode via l'interface

# Ou démarrage direct
./start-bot.sh SampleStrategy dry-run
./start-bot.sh PowerTowerStrategy live

# Vérifier le statut
./stop-bot.sh --status

# Arrêter le bot
./stop-bot.sh

# Voir les logs
./stop-bot.sh --logs
```

## Scripts de Gestion

### Scripts Disponibles

#### Scripts de Trading

- **`start-bot.sh`** : Démarre FreqTrad avec choix de stratégie et mode
- **`stop-bot.sh`** : Arrête FreqTrad proprement
- **`diagnose-trading.sh`** : Diagnostic des trades et logs

#### Scripts d'Optimisation

- **`test-hyperopt.sh`** : Test rapide de l'hyperopt (10 epochs)
- **`run-hyperopt.sh`** : Hyperopt standard (100 epochs)
- **`show-hyperopt-results.sh`** : Affiche les résultats d'optimisation
- **`apply-best-params.sh`** : Applique les meilleurs paramètres trouvés

#### Scripts de Backtesting

- **`test-backtest.sh`** : Test rapide de backtesting (10 jours)
- **`run-backtest.sh`** : Backtesting standard (1 mois)

## Exemple de backtest

```bash
freqtrade backtesting \
  --config config.json \
  --strategy HyperoptWorking \
  --timeframe 5m
```

### Utilisation des Scripts

```bash
# Démarrer le bot avec choix interactif
./start-bot.sh

# Arrêter le bot
./stop-bot.sh

# Diagnostic des trades
./diagnose-trading.sh

# Hyperoptimisation
./test-hyperopt.sh
./run-hyperopt.sh
./show-hyperopt-results.sh
./apply-best-params.sh

# Backtesting
./test-backtest.sh
./run-backtest.sh
```

## 📊 Utilisation

### Mode Dry Run (Recommandé pour débuter)

```bash
# Démarrer en mode simulation
source venv/bin/activate
freqtrade trade --config config.json --strategy SampleStrategy
```

### Backtesting

#### Utilisation des Scripts (Recommandé)

```bash
# Test rapide (10 jours)
./test-backtest.sh

# Backtesting standard (1 mois)
./run-backtest.sh

#### Utilisation Manuelle

```bash
# Tester une stratégie sur des données historiques
freqtrade backtesting \
    --config config.json \
    --strategy HyperoptWorking \
    --timerange 20240901-20240910
```

### 2. Autres Stratégies Disponibles

- **HyperoptOptimized** : Stratégie avec paramètres optimisés (générée automatiquement par `apply-best-params.sh`)
- **HyperoptSimple** : Stratégie simplifiée pour hyperopt
- **HyperoptStrategy** : Stratégie de base pour hyperopt
- **PowerTowerStrategy** : Stratégie alternative avec indicateurs multiples

**Utilisation des autres stratégies :**

```bash
# Tester une stratégie spécifique
./test-backtest.sh PowerTowerStrategy

# Backtesting avec une stratégie
./run-backtest.sh HyperoptOptimized

# Démarrer le bot avec une stratégie
./start-bot.sh PowerTowerStrategy
```

### Accès Restreint

- **Local uniquement** : Changer `listen_ip_address` à `"127.0.0.1"` dans `config.json`
- **Authentification** : Toujours activée avec nom d'utilisateur et mot de passe
- **HTTPS** : Recommandé pour la production

## 📱 Notifications Telegram

### Configuration

1. Créer un bot Telegram avec @BotFather
2. Ajouter le token dans `.env`
3. Activer Telegram dans `config.json` :

```json
"telegram": {
    "enabled": true,
    "token": "${TELEGRAM_TOKEN}",
    "chat_id": "${TELEGRAM_CHAT_ID}"
}
```

### Commandes Disponibles

- `/daily` - Performance du jour
- `/profit` - Profits actuels
- `/balance` - Solde du portefeuille
- `/trades` - Liste des trades récents
- `/stats` - Statistiques de trading
- `/status` - Statut du bot

## 🛠️ Développement

### Créer une Nouvelle Stratégie

1. Copier `SampleStrategy.py` vers un nouveau fichier
2. Renommer la classe
3. Modifier les paramètres selon vos besoins
4. Tester avec le mode dry run

### Structure du Projet

cypTrade/
├── config.json                 # Configuration principale (USDT)
├── config-usdt.json           # Configuration USDT étendue
├── .env.example               # Variables d'environnement (template)
├── requirements.txt           # Dépendances Python
├── README.md                  # Documentation du projet
├── start-bot.sh              # Démarrer le bot
├── stop-bot.sh               # Arrêter le bot
├── diagnose-trading.sh       # Diagnostic des trades
├── run-hyperopt.sh           # Hyperoptimisation
├── test-hyperopt.sh          # Test hyperopt rapide
├── show-hyperopt-results.sh  # Afficher résultats
├── apply-best-params.sh      # Appliquer meilleurs paramètres
├── test-backtest.sh          # Backtest rapide
├── run-backtest.sh           # Backtest standard
└── user_data/
    ├── strategies/           # Stratégies de trading
    │   ├── HyperoptWorking.py    # ⭐ Stratégie principale
    │   ├── HyperoptWorking.json  # Paramètres optimisés
    │   ├── HyperoptOptimized.py  # Stratégie optimisée
    │   ├── HyperoptSimple.py     # Stratégie simple
    │   ├── HyperoptStrategy.py   # Stratégie de base
    │   └── PowerTowerStrategy.py # Stratégie alternative
    ├── data/                 # Données historiques
    │   └── binance/          # Données Binance (USDT/USDC)
    ├── backtest_results/     # Résultats backtest
    └── hyperopt_results/     # Résultats hyperopt

## 🔧 Dépannage

### Erreur Telegram Bot

Si vous voyez l'erreur `ExtBot is not properly initialized` :

```bash
# 1. Vérifier que Telegram est désactivé dans config.json
grep -A 5 '"telegram"' config.json

# 2. Si activé, le désactiver
sed -i 's/"enabled": true/"enabled": false/' config.json

# 3. Redémarrer FreqTrad
./stop-bot.sh
./start-bot.sh
```

### Interface Web Non Installée

Si vous voyez des erreurs liées à l'interface web :

```bash
# Installer l'interface web
source venv/bin/activate
freqtrade install-ui

# Puis redémarrer
./start-bot.sh
```

### Problèmes de Configuration

```bash
# Vérifier la configuration
freqtrade --config config.json --strategy SampleStrategy --dry-run

# Tester une stratégie spécifique
freqtrade --config config.json --strategy PowerTowerStrategy --dry-run
```

## 🚨 Avertissements

- **Toujours tester en mode dry run avant le trading live**
- **Ne jamais investir plus que ce que vous pouvez perdre**
- **Les performances passées ne garantissent pas les résultats futurs**
- **Gardez vos clés API sécurisées**
- **Surveillez régulièrement les logs pour détecter les erreurs**
- **Installez TOUJOURS l'interface web avant d'utiliser les scripts de trading**
- **Utilisez HyperoptWorking pour de meilleures performances**
- **Optimisez régulièrement vos stratégies avec l'hyperopt**
- **Les stratégies actuelles ne sont pas rentables - testez avant utilisation**
- **Utilisez `apply-best-params.sh` pour appliquer les paramètres optimisés**

## �� Documentation

- [Documentation FreqTrad](https://www.freqtrade.io/)
- [Guide des stratégies](https://www.freqtrade.io/en/latest/strategy-customization/)
- [Indicateurs techniques](https://www.freqtrade.io/en/latest/strategy-customization/#technical-indicators)
- [Interface Web FreqUI](https://github.com/freqtrade/freqtrade-ui)

## 🤝 Contribution

1. Fork le projet
2. Créez une branche pour votre fonctionnalité
3. Committez vos changements
4. Poussez vers la branche
5. Ouvrez une Pull Request

## �� Licence

Ce projet est sous licence MIT. Voir le fichier LICENSE pour plus de détails.

---

**Développé avec ❤️ pour le trading algorithmique**
