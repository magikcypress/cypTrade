# 🚀 Guide de Déploiement FreqTrad

## 📋 Prérequis

- Docker et Docker Compose installés
- Fichier `.env` configuré avec vos clés API
- Accès à un VPS ou service cloud

## 🌐 Options d'Hébergement

### 1. **DigitalOcean (Recommandé)**

```bash
# Créer un droplet Ubuntu 22.04
# Taille: $5-10/mois (1-2GB RAM)
# Région: Choisir la plus proche de vous

# Se connecter au serveur
ssh root@YOUR_SERVER_IP

# Cloner le projet
git clone https://github.com/magikcypress/cypTrade.git
cd cypTrade

# Configurer les variables d'environnement
cp env.example .env
nano .env  # Éditer avec vos clés

# Déployer
chmod +x deploy.sh
./deploy.sh digitalocean
```

### 2. **Vultr**

```bash
# Créer une instance Ubuntu 22.04
# Taille: $2.50-6/mois
# Même procédure que DigitalOcean
./deploy.sh vultr
```

### 3. **Hetzner (Europe)**

```bash
# Créer un Cloud Server
# Taille: €3-5/mois
# Même procédure
./deploy.sh hetzner
```

### 4. **AWS EC2**

```bash
# Créer une instance t3.micro ou t3.small
# Ubuntu 22.04 LTS
# Même procédure
./deploy.sh aws
```

## 🔧 Configuration du Serveur

### Installation des dépendances

```bash
# Mettre à jour le système
sudo apt update && sudo apt upgrade -y

# Installer Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
sudo usermod -aG docker $USER

# Installer Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Redémarrer la session
exit
ssh root@YOUR_SERVER_IP
```

### Configuration du Firewall

```bash
# Ouvrir les ports nécessaires
sudo ufw allow 22    # SSH
sudo ufw allow 8080  # API FreqTrad
sudo ufw allow 9090  # Monitoring (optionnel)
sudo ufw enable
```

## 📱 Configuration Telegram

1. **Créer un bot** :
   - Aller sur @BotFather sur Telegram
   - Envoyer `/newbot`
   - Suivre les instructions
   - Copier le token

2. **Obtenir le Chat ID** :
   - Envoyer un message à votre bot
   - Aller sur `https://api.telegram.org/bot<TOKEN>/getUpdates`
   - Copier le `chat.id`

3. **Configurer le fichier .env** :

```env
TELEGRAM_TOKEN=votre_token_ici
TELEGRAM_CHAT_ID=votre_chat_id_ici
BINANCE_API_KEY=votre_api_key_ici
BINANCE_SECRET=votre_secret_ici
JWT_SECRET=votre_jwt_secret_ici
API_USERNAME=votre_username
API_PASSWORD=votre_password
```

## 🚀 Déploiement

### Méthode 1: Script automatique

```bash
./deploy.sh
```

### Méthode 2: Manuel

```bash
# Construire l'image
docker-compose -f docker-compose.prod.yml build

# Démarrer les services
docker-compose -f docker-compose.prod.yml up -d

# Vérifier les logs
docker-compose -f docker-compose.prod.yml logs -f
```

## 📊 Monitoring

### Interface Web

- **URL** : `http://YOUR_SERVER_IP:8080`
- **Login** : Utilisez les credentials du fichier `.env`

### Commandes utiles

```bash
# Voir les logs
docker-compose -f docker-compose.prod.yml logs -f

# Redémarrer le bot
docker-compose -f docker-compose.prod.yml restart

# Arrêter le bot
docker-compose -f docker-compose.prod.yml down

# Mettre à jour
git pull
docker-compose -f docker-compose.prod.yml build
docker-compose -f docker-compose.prod.yml up -d
```

## 🔒 Sécurité

### Variables d'environnement

- Ne jamais commiter le fichier `.env`
- Utiliser des clés API avec permissions limitées
- Changer les mots de passe par défaut

### Firewall

- Limiter l'accès SSH par IP
- Utiliser des clés SSH au lieu de mots de passe
- Configurer fail2ban

### Sauvegarde

```bash
# Sauvegarder la configuration
tar -czf freqtrade-backup-$(date +%Y%m%d).tar.gz user_data/ .env

# Restaurer
tar -xzf freqtrade-backup-YYYYMMDD.tar.gz
```

## 🆘 Dépannage

### Problèmes courants

1. **Erreur de permissions Docker** :

```bash
sudo usermod -aG docker $USER
# Redémarrer la session
```

2. **Port déjà utilisé** :

```bash
sudo netstat -tulpn | grep :8080
sudo kill -9 PID
```

3. **Problème de mémoire** :

```bash
# Augmenter la taille du VPS
# Ou optimiser la configuration
```

4. **Logs d'erreur** :

```bash
docker-compose -f docker-compose.prod.yml logs --tail=100
```

## 📞 Support

- **Documentation FreqTrad** : <https://www.freqtrade.io/>
- **Discord FreqTrad** : <https://discord.gg/freqtrade>
- **GitHub Issues** : <https://github.com/freqtrade/freqtrade/issues>
