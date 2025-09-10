# CypTrade - FreqTrad Configuration

Ce projet configure FreqTrad pour le trading algorithmique avec des stratégies personnalisées.

## 🚀 Installation

### Prérequis

- Python 3.8 ou supérieur
- pip (gestionnaire de paquets Python)

### Installation Automatique (Recommandé)

#### Pour Debian/Ubuntu avec Python 3.13

```bash
# Rendre le script exécutable
chmod +x install-freqtrade-python313-optimized.sh

# Exécuter l'installation complète
./install-freqtrade-python313-optimized.sh
```

Ce script automatise :

- Installation de Python 3.13
- Installation des dépendances système
- Création de l'utilisateur FreqTrad
- Configuration de l'environnement virtuel
- Installation de FreqTrad et de l'interface web
- Configuration du service systemd
- Configuration du pare-feu

#### Installation Manuelle

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

#### Installation Automatique

L'interface web est automatiquement installée et configurée avec le script d'installation.

#### Installation Manuelle

```bash
freqtrade trade --config config.json --strategy SampleStrategy --api-server
```

#### Accès à l'Interface

- **URL** : <http://127.0.0.1:8080> (accès local sécurisé)
- **Identifiants** : `admin` / `NouveauMotDePasse2025!` (par défaut)
- **Changer le mot de passe** : `./change-password.sh "VotreMotDePasse"`

### Bot Telegram

```bash
freqtrade trade --config config.json --strategy SampleStrategy
```

Configurez votre bot Telegram pour recevoir des notifications de trading. Voir [TELEGRAM_SETUP.md](TELEGRAM_SETUP.md) pour la configuration détaillée.

## 📁 Structure du Projet

```
cypTrade/
├── config.json                 # Configuration principale
├── config-test.json           # Configuration de test
├── freqtrade_hyperopt.json    # Configuration hyperopt
├── requirements.txt            # Dépendances Python
├── .env                        # Variables d'environnement
├── README.md                   # Ce fichier
├── INSTALLATION.md             # Guide d'installation détaillé
├── DEPLOYMENT.md               # Guide de déploiement
├── docker-compose.yml          # Configuration Docker
├── install-freqtrade-python313-optimized.sh  # Script d'installation Debian
├── install-freqtrade-simple.sh               # Script d'installation simple
├── change-password.sh          # Script de changement de mot de passe
├── secure-config.sh            # Script de sécurisation
├── logs.sh                     # Script de visualisation des logs
└── user_data/
    └── strategies/
        ├── SampleStrategy.py   # Stratégie d'exemple
        └── PowerTowerStrategy.py # Stratégie avancée
```

## 🛠️ Scripts de Gestion

### Scripts d'Installation

- **`install-freqtrade-python313-optimized.sh`** : Installation complète pour Debian/Ubuntu avec Python 3.13
- **`install-freqtrade-simple.sh`** : Installation simple et rapide
- **`check-python.sh`** : Vérification de la compatibilité Python

### Scripts de Configuration

- **`change-password.sh`** : Changement du mot de passe FreqTrad
- **`secure-config.sh`** : Sécurisation de la configuration
- **`logs.sh`** : Visualisation des logs en temps réel

### Scripts de Déploiement

- **`deploy.sh`** : Déploiement Docker
- **`deploy-to-server.sh`** : Déploiement sur serveur distant

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

### Gestion du Service (après installation automatique)

```bash
# Démarrer FreqTrad
sudo systemctl start freqtrade

# Arrêter FreqTrad
sudo systemctl stop freqtrade

# Redémarrer FreqTrad
sudo systemctl restart freqtrade

# Voir le statut
sudo systemctl status freqtrade

# Voir les logs
sudo journalctl -u freqtrade -f
```

### Commandes FreqTrad

```bash
# Voir les paires disponibles
freqtrade list-pairs --config config.json --exchange binance

# Tester une stratégie
freqtrade test-pairlist --config config.json --strategy SampleStrategy

# Voir les trades
freqtrade show-trades --config config.json

# Voir les performances
freqtrade show-trades --config config.json --show-trades

# Voir les logs en temps réel
./logs.sh
```

### Scripts de Gestion

```bash
# Changer le mot de passe
./change-password.sh "NouveauMotDePasse"

# Sécuriser la configuration
./secure-config.sh

# Voir les logs
./logs.sh
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
