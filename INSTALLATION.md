# 🚀 Installation FreqTrad sur Serveur

Ce guide vous explique comment installer FreqTrad sur votre serveur Linux avec un environnement virtuel Python.

## 📋 Prérequis

- Serveur Linux (Ubuntu/Debian recommandé)
- Accès root ou sudo
- Connexion Internet
- Python 3.11+ (installé automatiquement)

## 🎯 Méthodes d'Installation

### 1. Installation Complète (Recommandée)

```bash
# Télécharger et exécuter le script d'installation
wget https://raw.githubusercontent.com/votre-repo/cypTrade/main/install-freqtrade.sh
chmod +x install-freqtrade.sh
./install-freqtrade.sh
```

**Ce script :**

- ✅ Met à jour le système
- ✅ Installe Python 3.11 et les dépendances
- ✅ Crée un utilisateur dédié `freqtrade`
- ✅ Configure l'environnement virtuel
- ✅ Installe FreqTrad et l'interface web
- ✅ Configure le service systemd
- ✅ Configure le pare-feu
- ✅ Crée des scripts de gestion

### 2. Installation Rapide

```bash
# Pour une installation rapide sur votre machine actuelle
./quick-install.sh
```

### 3. Déploiement depuis votre machine locale

```bash
# Déployer vers un serveur distant
./deploy-to-server.sh user@server-ip
```

## ⚙️ Configuration

### 1. Configurer les clés API

Éditez le fichier `.env` :

```bash
nano /home/freqtrade/cypTrade/.env
```

Modifiez les valeurs suivantes :

```env
# Configuration FreqTrad
BINANCE_API_KEY=votre_vraie_clé_api
BINANCE_SECRET=votre_vraie_clé_secrète

# Telegram Bot
TELEGRAM_TOKEN=votre_token_telegram
TELEGRAM_CHAT_ID=votre_chat_id

# API Server (générés automatiquement)
JWT_SECRET=...
API_USERNAME=admin
API_PASSWORD=...
```

### 2. Démarrer FreqTrad

```bash
# Démarrer le service
sudo systemctl start freqtrade

# Vérifier le statut
sudo systemctl status freqtrade

# Voir les logs
sudo journalctl -u freqtrade -f
```

## 🌐 Accès à l'Interface Web

- **URL** : `http://votre-serveur:8080`
- **Identifiants** : `admin` / `mot_de_passe_généré`

## 📊 Scripts de Gestion

Dans le répertoire `/home/freqtrade/cypTrade/` :

```bash
# Démarrer FreqTrad
./start.sh

# Mode trading
./trade.sh

# Arrêter
./stop.sh

# Redémarrer
./restart.sh

# Mettre à jour
./update.sh
```

## 🔧 Commandes Systemd

```bash
# Démarrer
sudo systemctl start freqtrade

# Arrêter
sudo systemctl stop freqtrade

# Redémarrer
sudo systemctl restart freqtrade

# Statut
sudo systemctl status freqtrade

# Activer au démarrage
sudo systemctl enable freqtrade

# Désactiver au démarrage
sudo systemctl disable freqtrade
```

## 📝 Logs et Monitoring

### Voir les logs en temps réel

```bash
sudo journalctl -u freqtrade -f
```

### Logs FreqTrad

```bash
tail -f /home/freqtrade/cypTrade/user_data/logs/freqtrade.log
```

### Vérifier les processus

```bash
ps aux | grep freqtrade
```

## 🔒 Sécurité

### Pare-feu

Le script configure automatiquement le pare-feu pour ouvrir le port 8080.

### Utilisateur dédié

FreqTrad s'exécute avec un utilisateur dédié `freqtrade` (pas root).

### HTTPS (Optionnel)

Pour une sécurité renforcée, configurez un reverse proxy avec SSL :

```bash
# Installer Nginx
sudo apt install nginx

# Configurer le reverse proxy
sudo nano /etc/nginx/sites-available/freqtrade
```

## 🚨 Dépannage

### FreqTrad ne démarre pas

```bash
# Vérifier les logs
sudo journalctl -u freqtrade -n 50

# Vérifier la configuration
sudo -u freqtrade /home/freqtrade/cypTrade/venv/bin/freqtrade --config /home/freqtrade/cypTrade/config-test.json --check-config
```

### Interface web inaccessible

```bash
# Vérifier que le port est ouvert
sudo netstat -tlnp | grep 8080

# Vérifier le pare-feu
sudo ufw status
```

### Problèmes de permissions

```bash
# Corriger les permissions
sudo chown -R freqtrade:freqtrade /home/freqtrade/cypTrade
```

## 📞 Support

- **Documentation FreqTrad** : <https://www.freqtrade.io/>
- **GitHub** : <https://github.com/freqtrade/freqtrade>
- **Discord** : <https://discord.gg/freqtrade>

## 🎉 Félicitations

Votre bot FreqTrad est maintenant installé et configuré sur votre serveur !

**Prochaines étapes :**

1. Configurez vos clés API dans `.env`
2. Démarrez le service : `sudo systemctl start freqtrade`
3. Accédez à l'interface : `http://votre-serveur:8080`
4. Configurez vos stratégies de trading
5. Activez le mode live (attention aux risques !)
