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
chmod +x quick-install.sh

# Exécuter l'installation
./quick-install.sh
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
# Binance API
BINANCE_API_KEY=your_api_key_here
BINANCE_SECRET=your_secret_here

# JWT Secret pour l'API
JWT_SECRET=your_jwt_secret_here

# Telegram Bot (optionnel)
TELEGRAM_TOKEN=your_telegram_token
TELEGRAM_CHAT_ID=your_chat_id
```

### 2. Configuration Principale

Le fichier `config.json` est pré-configuré avec :

- **Échange** : Binance
- **Devise de base** : USDC
- **Mode** : Dry Run (simulation)
- **Timeframe** : 5 minutes
- **Paires** : BTC/USDC, ETH/USDC, BNB/USDC, ADA/USDC, SOL/USDC, DOT/USDC, LINK/USDC, MATIC/USDC
- **API Server** : Activé sur le port 8080
- **Interface Web** : FreqUI intégrée

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
./run-full-hyperopt.sh

# Voir les résultats
./show-hyperopt-results.sh

# Appliquer les meilleurs paramètres
./apply-best-params.sh
```

### 2. PowerTowerStrategy

Stratégie avancée avec :

- Indicateurs multiples
- Gestion des risques améliorée
- Support des timeframes informatifs
- Vérifications de sécurité robustes

### 3. MultiMAStrategy

Stratégie multi-timeframe utilisant :

- Moyennes mobiles exponentielles sur plusieurs timeframes
- Analyse de tendance sur 1h, 4h, 1d
- Gestion des risques adaptative

### 4. Autres Stratégies

- **SampleStrategy** : Stratégie d'exemple basique
- **BalancedAdvancedStrategy** : Stratégie équilibrée avec indicateurs avancés
- **BandtasticStrategy** : Basée sur les bandes de Bollinger (corrigée)
- **SimpleTestStrategy** : Stratégie de test simple

## 🚀 Optimisation des Stratégies

### Scripts d'Hyperopt

| Script | Fonction | Epochs | Durée | Usage |
|--------|----------|--------|-------|-------|
| `test-hyperopt.sh` | Test rapide | 10 | ~2 min | Validation |
| `run-hyperopt.sh` | Optimisation standard | 100 | ~20 min | Optimisation |
| `run-full-hyperopt.sh` | Optimisation complète | 500 | ~2h | Optimisation avancée |
| `show-hyperopt-results.sh` | Affichage des résultats | - | - | Analyse |
| `apply-best-params.sh` | Application des paramètres | - | - | Déploiement |

### Exemple d'Optimisation

```bash
# 1. Test rapide
./test-hyperopt.sh

# 2. Voir les résultats
./show-hyperopt-results.sh

# 3. Optimisation complète
./run-full-hyperopt.sh

# 4. Appliquer les meilleurs paramètres
./apply-best-params.sh
```

### Exemple de commande

```bash
freqtrade hyperopt --hyperopt-loss MultiMetricHyperOptLoss \
  --strategy HyperoptWorking \
  --timerange 20240101-20241201 \
  -e 500 \
  --spaces buy sell roi \
  --min-trades 50
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
- **`start-webserver.sh`** : Démarre FreqTrad avec l'interface web
- **`restart-server.sh`** : Redémarre le serveur FreqTrad

#### Scripts d'Optimisation

- **`test-hyperopt.sh`** : Test rapide de l'hyperopt (10 epochs)
- **`run-hyperopt.sh`** : Hyperopt standard (100 epochs)
- **`run-full-hyperopt.sh`** : Hyperopt complet (500 epochs)
- **`show-hyperopt-results.sh`** : Affiche les résultats d'optimisation
- **`apply-best-params.sh`** : Applique les meilleurs paramètres trouvés

#### Scripts de Diagnostic

- **`diagnose-trading.sh`** : Diagnostic complet du système de trading
- **`monitor-trades.sh`** : Surveillance des trades en temps réel

#### Scripts de Configuration

- **`secure-config.sh`** : Sécurise la configuration
- **`quick-install.sh`** : Installation rapide et automatique
- **`generate-password.sh`** : Génère des mots de passe sécurisés
- **`install-hyperopt-server.sh`** : Installation sur serveur Debian

### Utilisation des Scripts

```bash
# Démarrer le bot avec choix interactif
./start-bot.sh

# Démarrer le serveur web
./start-webserver.sh

# Redémarrer le serveur
./restart-server.sh

# Arrêter le bot
./stop-bot.sh

# Sécuriser la configuration
./secure-config.sh

# Voir les logs
tail -f user_data/logs/freqtrade.log
```

## 📊 Utilisation

### Mode Dry Run (Recommandé pour débuter)

```bash
# Démarrer en mode simulation
source venv/bin/activate
freqtrade trade --config config.json --strategy SampleStrategy
```

### Backtesting

```bash
# Tester une stratégie sur des données historiques
freqtrade backtesting \
    --config config.json \
    --strategy SampleStrategy \
    --timerange 20240901-20240910
```

### Hyperopt (Optimisation des paramètres)

#### Utilisation des Scripts (Recommandé)

```bash
# Test rapide (10 epochs)
./test-hyperopt.sh

# Optimisation standard (100 epochs)
./run-hyperopt.sh

# Optimisation complète (500 epochs)
./run-full-hyperopt.sh

# Voir les résultats
./show-hyperopt-results.sh

# Appliquer les meilleurs paramètres
./apply-best-params.sh
```

#### Utilisation Manuelle

```bash
# Optimiser les paramètres d'une stratégie
freqtrade hyperopt \
    --config config-usdt.json \
    --strategy HyperoptWorking \
    --hyperopt-loss SharpeHyperOptLoss \
    --epochs 100 \
    --spaces buy sell protection
```

## 🔒 Sécurité

### Configuration Sécurisée

1. **Changer le mot de passe par défaut** :

   ```bash
   ./generate-password.sh
   # Puis éditer config.json avec le nouveau mot de passe
   ```

2. **Sécuriser l'accès API** :

   ```bash
   ./secure-config.sh
   ```

3. **Variables d'environnement** :
   - Ne jamais commiter le fichier `.env`
   - Utiliser des clés API avec permissions limitées
   - Changer le JWT secret par défaut

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
├── config.json # Configuration principale (USDC)
├── config-usdt.json # Configuration USDT
├── requirements.txt # Dépendances Python
├── .env # Variables d'environnement
├── README.md # Ce fichier
├── start-webserver.sh # Script de démarrage
├── restart-server.sh # Script de redémarrage
├── secure-config.sh # Script de sécurisation
├── quick-install.sh # Installation rapide
├── generate-password.sh # Génération de mots de passe
├── test-hyperopt.sh # Test hyperopt rapide
├── run-hyperopt.sh # Hyperopt standard
├── run-full-hyperopt.sh # Hyperopt complet
├── show-hyperopt-results.sh # Affichage des résultats
├── apply-best-params.sh # Application des paramètres
├── diagnose-trading.sh # Diagnostic du système
├── monitor-trades.sh # Surveillance des trades
├── install-hyperopt-server.sh # Installation serveur
└── user_data/
    ├── logs/ # Logs FreqTrad
    ├── data/ # Données historiques
    ├── hyperopt_results/ # Résultats d'optimisation
    └── strategies/ # Stratégies de trading
        ├── HyperoptWorking.py # ⭐ Stratégie principale
        ├── PowerTowerStrategy.py
        ├── MultiMAStrategy.py
        ├── SampleStrategy.py
        └── ...

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
