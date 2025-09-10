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

# 4. Installer l'interface web
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

### 1. SampleStrategy

Stratégie d'exemple basée sur :

- RSI (Relative Strength Index)
- Bollinger Bands
- MACD
- Conditions d'entrée : RSI < 30 et prix sous la bande inférieure de Bollinger
- Conditions de sortie : RSI > 70 et prix au-dessus de la bande supérieure de Bollinger

### 2. PowerTowerStrategy

Stratégie avancée avec :

- Indicateurs multiples
- Gestion des risques améliorée
- Support des timeframes informatifs
- Vérifications de sécurité robustes

### 3. Autres Stratégies

- **BalancedAdvancedStrategy** : Stratégie équilibrée avec indicateurs avancés
- **BandtasticStrategy** : Basée sur les bandes de Bollinger
- **MultiMAStrategy** : Utilise plusieurs moyennes mobiles
- **SimpleTestStrategy** : Stratégie de test simple

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

## Scripts de Gestion

### Scripts Disponibles

- **`start-webserver.sh`** : Démarre FreqTrad avec l'interface web
- **`restart-server.sh`** : Redémarre le serveur FreqTrad
- **`secure-config.sh`** : Sécurise la configuration
- **`quick-install.sh`** : Installation rapide et automatique
- **`generate-password.sh`** : Génère des mots de passe sécurisés

### Utilisation des Scripts

```bash
# Démarrer le serveur
./start-webserver.sh

# Redémarrer le serveur
./restart-server.sh

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

```bash
# Optimiser les paramètres d'une stratégie
freqtrade hyperopt \
    --config config.json \
    --strategy SampleStrategy \
    --hyperopt-loss SharpeHyperOptLoss \
    --epochs 100
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
├── config.json # Configuration principale
├── requirements.txt # Dépendances Python
├── .env # Variables d'environnement
├── README.md # Ce fichier
├── start-webserver.sh # Script de démarrage
├── restart-server.sh # Script de redémarrage
├── secure-config.sh # Script de sécurisation
├── quick-install.sh # Installation rapide
├── generate-password.sh # Génération de mots de passe
└── user_data/
├── logs/ # Logs FreqTrad
├── data/ # Données historiques
└── strategies/ # Stratégies de trading
├── SampleStrategy.py
├── PowerTowerStrategy.py
└── ...

## 🚨 Avertissements

- **Toujours tester en mode dry run avant le trading live**
- **Ne jamais investir plus que ce que vous pouvez perdre**
- **Les performances passées ne garantissent pas les résultats futurs**
- **Gardez vos clés API sécurisées**
- **Surveillez régulièrement les logs pour détecter les erreurs**

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
