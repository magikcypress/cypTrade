# CypTrade - FreqTrad Configuration

Ce projet configure FreqTrad pour le trading algorithmique avec des stratégies personnalisées et une interface web complète.

## 🚀 Installation Rapide

## 🎯 **NOUVEAU: Trading Multi-Strégies**

Vous pouvez maintenant faire tourner **plusieurs stratégies simultanément** avec des interfaces web séparées !

### **🚀 Démarrage rapide multi-strégies:**

```bash
# 1. Démarrer plusieurs stratégies
./start-multiple-strategies.sh TrendFollowingStrategy,HyperoptWorking,MeanReversionStrategy

# 2. Voir le statut de toutes les stratégies
./start-multiple-strategies.sh status

# 3. Arrêter toutes les stratégies
./start-multiple-strategies.sh stop
```

### **🌐 Accès aux interfaces web:**

Une fois les stratégies démarrées, vous pouvez accéder à chaque interface :

- **TrendFollowingStrategy**: <http://127.0.0.1:8080>
- **HyperoptWorking**: <http://127.0.0.1:8081>  
- **MeanReversionStrategy**: <http://127.0.0.1:8082>

**Identifiants de connexion :**

- **Username**: `freqtrade`
- **Password**: `freqtrade123`

### **📋 Stratégies disponibles:**

- **TrendFollowingStrategy** - Stratégie de suivi de tendance
- **HyperoptWorking** - Stratégie optimisée (recommandée)
- **MeanReversionStrategy** - Stratégie de retour à la moyenne
- **MultiExchangeStrategy** - Stratégie multi-exchange
- **PowerTowerStrategy** - Stratégie avec indicateurs multiples

### **🔧 Méthodes disponibles:**

- **🎯 Multi-Strégies**: `./start-multiple-strategies.sh Strategy1,Strategy2` (contrôle total)
- **🌐 Multi-Exchange**: `./start-multi-exchange.sh both` (Binance + Hyperliquid)
- **🔧 Multi-Configuration**: `./start-multi-config.sh conservative` (stratégies adaptées)
- **⚙️ Gestion avancée**: `./manage-strategies.sh` (hyperopt, backtest, comparaison)

### **✨ Fonctionnalités du système multi-strégies:**

- ✅ **Interfaces séparées** : Chaque stratégie a sa propre interface web
- ✅ **Ports automatiques** : Attribution automatique des ports (8080, 8081, 8082...)
- ✅ **Authentification** : Même identifiants pour toutes les interfaces
- ✅ **Logs séparés** : Chaque stratégie a ses propres logs
- ✅ **Gestion centralisée** : Contrôle de toutes les stratégies via un seul script
- ✅ **Noms de bots** : Format `cypTrade-{StrategyName}`

📖 **Guide complet**: Voir [GUIDE-MULTI-STRATEGIES.md](GUIDE-MULTI-STRATEGIES.md)

---

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

#### Configurations Multi-Strégies

- **`config-simple.json`** : Configuration de base pour le système multi-strégies
  - Authentification : `freqtrade` / `freqtrade123`
  - Conversion fiat désactivée (évite les erreurs CoinGecko)
  - Configuration optimisée pour plusieurs instances

#### Configurations Classiques

- **`config.json`** : Configuration principale avec :
  - **Échange** : Binance
  - **Devise de base** : USDT
  - **Mode** : Dry Run (simulation)
  - **Timeframe** : 5 minutes
  - **Paires** : BTC/USDT, ETH/USDT, BNB/USDT, ADA/USDT, SOL/USDT, DOT/USDT, LINK/USDT, MATIC/USDT
  - **API Server** : Activé sur le port 8080
  - **Interface Web** : FreqUI intégrée

- **`config-usdt.json`** : Configuration étendue avec plus de paires USDT

#### Configurations Multi-Exchange

- **`config-multi-exchange.json`** : Configuration pour Binance (MultiExchangeStrategy)
- **`config-hyperliquid-multi.json`** : Configuration pour Hyperliquid (MultiExchangeStrategy)

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

#### 🎯 Scripts Multi-Strégies (NOUVEAU)

- **`start-multiple-strategies.sh`** : Démarre plusieurs stratégies simultanément
- **`manage-strategies.sh`** : Gestionnaire complet (start, stop, status, hyperopt, backtest)
- **`start-multi-exchange.sh`** : Stratégies multi-exchange (Binance + Hyperliquid)
- **`start-multi-config.sh`** : Multi-configuration avec profils de risque
- **`test-multi-strategies.sh`** : Test de tous les scripts multi-strégies
- **`test-strategies-comparison.sh`** : Comparaison de stratégies

#### 🔧 Scripts de Trading Classiques

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

#### Scripts d'Analyse des Résultats

- **`analyze-backtest-results.sh`** : Analyse détaillée des résultats de backtest
- **`analyze-hyperopt-results.sh`** : Analyse des résultats d'hyperoptimisation
- **`demo-analyze-backtest.sh`** : Démonstration de l'analyse de backtest
- **`demo-analyze-hyperopt.sh`** : Démonstration de l'analyse d'hyperopt

## Exemple de backtest

```bash
freqtrade backtesting \
  --config config.json \
  --strategy HyperoptWorking \
  --timeframe 5m
```

### Utilisation des Scripts

#### 🎯 Scripts Multi-Strégies

```bash
# Démarrer plusieurs stratégies
./start-multiple-strategies.sh TrendFollowingStrategy,HyperoptWorking,MeanReversionStrategy

# Voir le statut de toutes les stratégies
./start-multiple-strategies.sh status

# Arrêter toutes les stratégies
./start-multiple-strategies.sh stop

# Gestion avancée avec manage-strategies.sh
./manage-strategies.sh start Strategy1,Strategy2
./manage-strategies.sh stop
./manage-strategies.sh status
./manage-strategies.sh hyperopt MeanReversionStrategy
./manage-strategies.sh backtest TrendFollowingStrategy
./manage-strategies.sh compare Strategy1 Strategy2

# Multi-exchange (Binance + Hyperliquid)
./start-multi-exchange.sh both
./start-multi-exchange.sh binance
./start-multi-exchange.sh hyperliquid
./start-multi-exchange.sh status
./start-multi-exchange.sh stop

# Multi-configuration avec profils de risque
./start-multi-config.sh conservative
./start-multi-config.sh moderate
./start-multi-config.sh aggressive
./start-multi-config.sh multi

# Tests et comparaisons
./test-multi-strategies.sh
./test-strategies-comparison.sh
```

#### 🔧 Scripts Classiques

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

# Analyse des résultats
./analyze-backtest-results.sh latest
./analyze-hyperopt-results.sh latest
```

## 📊 Analyse des Résultats

### Scripts d'Analyse de Backtest

Le script `analyze-backtest-results.sh` analyse les résultats de backtest FreqTrad :

```bash
# Lister tous les fichiers de résultats
./analyze-backtest-results.sh list

# Analyser le dernier résultat
./analyze-backtest-results.sh latest

# Analyser un fichier spécifique
./analyze-backtest-results.sh user_data/backtest_results/backtest-result-2025-01-15.json

# Comparer plusieurs résultats
./analyze-backtest-results.sh compare fichier1.json fichier2.json

# Démonstration complète
./demo-analyze-backtest.sh
```

**Fonctionnalités :**

- 📊 **Métriques détaillées** : Profit, Sharpe, Sortino, Calmar, Drawdown
- 📈 **Analyse par paire** : Performance de chaque paire tradée
- 🔍 **Recommandations** : Suggestions d'amélioration
- 📋 **Comparaison** : Comparaison entre différents backtests

### Scripts d'Analyse d'Hyperopt

Le script `analyze-hyperopt-results.sh` analyse les résultats d'hyperoptimisation :

```bash
# Lister tous les fichiers d'hyperopt
./analyze-hyperopt-results.sh list

# Analyser le dernier résultat
./analyze-hyperopt-results.sh latest

# Analyser un fichier spécifique
./analyze-hyperopt-results.sh user_data/hyperopt_results/strategy_HyperoptWorking_2025-01-15.fthypt

# Comparer plusieurs résultats
./analyze-hyperopt-results.sh compare fichier1.fthypt fichier2.fthypt

# Extraire les meilleurs paramètres
./analyze-hyperopt-results.sh extract fichier.fthypt

# Démonstration complète
./demo-analyze-hyperopt.sh
```

**Fonctionnalités :**

- 🏆 **Meilleure époque** : Analyse de la configuration optimale
- ⚙️ **Paramètres optimisés** : Extraction des meilleurs paramètres
- 📈 **Évolution** : Progression des performances au fil des époques
- 🔄 **Comparaison** : Comparaison entre différentes optimisations

### Prérequis pour les Scripts d'Analyse

Les scripts d'analyse nécessitent les outils suivants :

```bash
# Installer jq (processeur JSON)
# macOS
brew install jq

# Ubuntu/Debian
sudo apt-get install jq

# CentOS/RHEL
sudo yum install jq
```

**Formats supportés :**

- **Backtest** : `.json`, `.zip` (archives FreqTrad)
- **Hyperopt** : `.json`, `.fthypt` (format FreqTrad hyperopt)

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

### 2. Stratégies Multi-Exchange

- **MultiExchangeStrategy** : Stratégie qui peut trader sur Binance (USDT) et Hyperliquid (USDC) avec des configurations adaptées à chaque exchange
- **MultiConfigStrategy** : Stratégie multi-configuration pour différentes paires sur le même exchange

### 3. Autres Stratégies Disponibles

- **HyperoptOptimized** : Stratégie avec paramètres optimisés (générée automatiquement par `apply-best-params.sh`)
- **HyperoptSimple** : Stratégie simplifiée pour hyperopt
- **HyperoptStrategy** : Stratégie de base pour hyperopt
- **PowerTowerStrategy** : Stratégie alternative avec indicateurs multiples

**Utilisation des stratégies multi-exchange :**

```bash
# Démarrer les deux exchanges (Binance + Hyperliquid)
./start-multi-exchange.sh both

# Démarrer Binance uniquement
./start-multi-exchange.sh binance

# Démarrer Hyperliquid uniquement
./start-multi-exchange.sh hyperliquid

# Voir le statut des exchanges
./start-multi-exchange.sh status

# Arrêter tous les exchanges
./start-multi-exchange.sh stop

# Tester la stratégie multi-exchange
-s h    
```

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
├── 📚 CONFIGURATIONS
├── config.json                 # Configuration principale (USDT)
├── config-usdt.json           # Configuration USDT étendue
├── config-simple.json         # Configuration de base multi-strégies
├── config-multi-exchange.json # Configuration multi-exchange Binance
├── config-hyperliquid-multi.json # Configuration multi-exchange Hyperliquid
├── .env.example               # Variables d'environnement (template)
├── requirements.txt           # Dépendances Python
├── README.md                  # Documentation du projet
├── 🚀 SCRIPTS MULTI-STRÉGIES (NOUVEAU)
├── manage-strategies.sh       # Gestionnaire complet multi-strégies
├── start-multiple-strategies.sh # Démarrage de stratégies spécifiques
├── start-multi-exchange.sh    # Multi-exchange (Binance + Hyperliquid)
├── start-multi-config.sh      # Multi-configuration
├── test-multi-strategies.sh   # Test des scripts multi-strégies
├── test-strategies-comparison.sh # Comparaison de stratégies
├── GUIDE-MULTI-STRATEGIES.md  # Guide complet multi-strégies
├── 🔧 SCRIPTS CLASSIQUES
├── start-bot.sh              # Démarrer le bot
├── stop-bot.sh               # Arrêter le bot
├── diagnose-trading.sh       # Diagnostic des trades
├── run-hyperopt.sh           # Hyperoptimisation
├── test-hyperopt.sh          # Test hyperopt rapide
├── show-hyperopt-results.sh  # Afficher résultats
├── apply-best-params.sh      # Appliquer meilleurs paramètres
├── test-backtest.sh          # Backtest rapide
├── run-backtest.sh           # Backtest standard
├── analyze-backtest-results.sh    # Analyse des résultats de backtest
├── analyze-hyperopt-results.sh    # Analyse des résultats d'hyperopt
├── demo-analyze-backtest.sh       # Démonstration analyse backtest
├── demo-analyze-hyperopt.sh       # Démonstration analyse hyperopt
└── user_data/
    ├── strategies/           # Stratégies de trading
    │   ├── HyperoptWorking.py    # ⭐ Stratégie principale (recommandée)
    │   ├── HyperoptWorking.json  # Paramètres optimisés
    │   ├── TrendFollowingStrategy.py # Stratégie de suivi de tendance
    │   ├── MeanReversionStrategy.py  # Stratégie de retour à la moyenne
    │   ├── MultiExchangeStrategy.py  # Stratégie multi-exchange
    │   ├── HyperoptOptimized.py  # Stratégie optimisée
    │   ├── HyperoptSimple.py     # Stratégie simple
    │   ├── HyperoptStrategy.py   # Stratégie de base
    │   └── PowerTowerStrategy.py # Stratégie alternative
    ├── data/                 # Données historiques
    │   └── binance/          # Données Binance (USDT/USDC)
    ├── backtest_results/     # Résultats backtest
    └── hyperopt_results/     # Résultats hyperopt

## 🔧 Dépannage

### 🎯 Problèmes Multi-Strégies

#### Erreur "declare: -A: invalid option"

```bash
# Problème : Associative arrays non supportés sur macOS
# Solution : Le script a été corrigé pour utiliser des fonctions

# Vérifier que les scripts fonctionnent
./test-multi-strategies.sh
```

#### Conflits de ports

```bash
# Vérifier les ports utilisés
lsof -i :8080 -i :8081 -i :8082

# Arrêter tous les processus FreqTrade
pkill -f freqtrade

# Redémarrer proprement
./start-multiple-strategies.sh stop
./start-multiple-strategies.sh TrendFollowingStrategy,HyperoptWorking
```

#### Erreur d'authentification

```bash
# Vérifier la configuration
grep -A 5 "username" config-simple.json

# Identifiants par défaut : freqtrade / freqtrade123
# Redémarrer avec la bonne configuration
./start-multiple-strategies.sh stop
./start-multiple-strategies.sh TrendFollowingStrategy
```

#### Erreur CoinGecko (Rate Limit)

```bash
# Erreur : "You've exceeded the Rate Limit"
# Solution : Conversion fiat désactivée dans config-simple.json
# Redémarrer les stratégies
./start-multiple-strategies.sh stop
./start-multiple-strategies.sh TrendFollowingStrategy,HyperoptWorking,MeanReversionStrategy
```

### 🔧 Problèmes Classiques

#### Erreur Telegram Bot

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

#### Interface Web Non Installée

Si vous voyez des erreurs liées à l'interface web :

```bash
# Installer l'interface web
source venv/bin/activate
freqtrade install-ui

# Puis redémarrer
./start-bot.sh
```

#### Problèmes de Configuration

```bash
# Vérifier la configuration
freqtrade --config config.json --strategy SampleStrategy --dry-run

# Tester une stratégie spécifique
freqtrade --config config.json --strategy PowerTowerStrategy --dry-run
```

## 🚨 Avertissements

### 🎯 Avertissements Multi-Strégies

- **Ressources système** : Chaque stratégie consomme de la RAM et CPU
- **Limitation des ports** : Maximum ~10 stratégies simultanées (ports 8080-8089)
- **Gestion des conflits** : Arrêtez toujours les stratégies avant de redémarrer
- **Authentification** : Même identifiants pour toutes les interfaces (sécurité)
- **Logs séparés** : Surveillez les logs de chaque stratégie individuellement
- **Configuration** : Utilisez `config-simple.json` comme base pour éviter les erreurs

### 🔧 Avertissements Généraux

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
- **Analysez vos résultats avec `analyze-backtest-results.sh` et `analyze-hyperopt-results.sh`**
- **Installez `jq` pour utiliser les scripts d'analyse**

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

## Développé avec ❤️ pour le trading algorithmique
