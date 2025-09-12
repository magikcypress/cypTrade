# 🚀 Guide Multi-Strégies FreqTrad

Ce guide vous explique comment faire tourner plusieurs stratégies simultanément avec votre configuration FreqTrad.

## 📋 **Vue d'ensemble des approches**

Vous avez **3 méthodes principales** pour faire tourner plusieurs stratégies :

### 1. **Multi-Exchange** (Même stratégie, différents exchanges)

### 2. **Multi-Configuration** (Différentes stratégies, même exchange)  

### 3. **Multi-Strégies** (Contrôle complet et flexible)

---

## 🌐 **1. Approche Multi-Exchange**

### Script: `start-multi-exchange.sh`

Cette approche utilise la stratégie `MultiExchangeStrategy` qui s'adapte automatiquement aux différents exchanges.

```bash
# Démarrer les deux exchanges (Binance + Hyperliquid)
./start-multi-exchange.sh both

# Démarrer seulement Binance
./start-multi-exchange.sh binance

# Démarrer seulement Hyperliquid  
./start-multi-exchange.sh hyperliquid

# Voir le statut
./start-multi-exchange.sh status

# Arrêter tout
./start-multi-exchange.sh stop
```

**Interfaces web:**

- Binance: <http://127.0.0.1:8080>
- Hyperliquid: <http://127.0.0.1:8081>

**Avantages:**

- ✅ Une seule stratégie à maintenir
- ✅ Configuration automatique selon l'exchange
- ✅ Gestion centralisée

---

## 🔧 **2. Approche Multi-Configuration**

### Script: `start-multi-config.sh`

Cette approche lance différentes stratégies avec des configurations adaptées.

```bash
# Stratégies conservatrices (BTC, ETH, BNB)
./start-multi-config.sh conservative

# Stratégies modérées (ADA, SOL, DOT, LINK)
./start-multi-config.sh moderate

# Stratégies agressives (DOGE, SHIB, PEPE)
./start-multi-config.sh aggressive

# Configuration multi-stratégie
./start-multi-config.sh multi
```

**Avantages:**

- ✅ Stratégies optimisées par type de marché
- ✅ Gestion du risque différenciée
- ✅ Portefeuille diversifié

---

## 🎯 **3. Approche Multi-Strégies (Recommandée)**

### Script: `start-multiple-strategies.sh`

Cette approche vous donne un contrôle total sur les stratégies à lancer.

```bash
# Démarrer des stratégies spécifiques
./start-multiple-strategies.sh HyperoptWorking,TrendFollowingStrategy

# Démarrer plusieurs stratégies
./start-multiple-strategies.sh MultiExchangeStrategy,MeanReversionStrategy,PowerTowerStrategy

# Voir le statut
./start-multiple-strategies.sh status

# Arrêter tout
./start-multiple-strategies.sh stop
```

**Stratégies disponibles:**

- `HyperoptWorking` - Stratégie optimisée par hyperopt
- `MultiExchangeStrategy` - Stratégie multi-exchange
- `TrendFollowingStrategy` - Suivi de tendance
- `MeanReversionStrategy` - Retour à la moyenne
- `PowerTowerStrategy` - Stratégie PowerTower

---

## 🛠️ **4. Gestionnaire Complet**

### Script: `manage-strategies.sh`

Ce script vous donne un contrôle complet sur toutes vos stratégies.

### **Commandes de base:**

```bash
# Afficher l'aide
./manage-strategies.sh help

# Voir le statut de toutes les stratégies
./manage-strategies.sh status

# Démarrer des stratégies spécifiques
./manage-strategies.sh start HyperoptWorking,TrendFollowingStrategy

# Démarrer toutes les stratégies
./manage-strategies.sh start all

# Arrêter des stratégies spécifiques
./manage-strategies.sh stop MultiExchangeStrategy

# Arrêter toutes les stratégies
./manage-strategies.sh stop all

# Redémarrer une stratégie
./manage-strategies.sh restart HyperoptWorking
```

### **Monitoring et logs:**

```bash
# Voir les logs d'une stratégie
./manage-strategies.sh logs HyperoptWorking

# Voir les performances de toutes les stratégies
./manage-strategies.sh performance

# Voir les trades d'une stratégie
./manage-strategies.sh trades TrendFollowingStrategy
```

### **Testing et optimisation:**

```bash
# Tester une stratégie
./manage-strategies.sh test HyperoptWorking 20241201-20241210

# Tester toutes les stratégies
./manage-strategies.sh test-all 20241201-20241210

# Optimiser une stratégie
./manage-strategies.sh hyperopt TrendFollowingStrategy 100
```

### **Maintenance:**

```bash
# Nettoyer les fichiers temporaires
./manage-strategies.sh clean

# Sauvegarder les configurations
./manage-strategies.sh backup

# Mettre à jour les données
./manage-strategies.sh update
```

---

## 🔥 **Exemples d'utilisation pratiques**

### **Scénario 1: Trading conservateur**

```bash
# Démarrer seulement les stratégies conservatrices
./manage-strategies.sh start HyperoptWorking,MeanReversionStrategy

# Vérifier le statut
./manage-strategies.sh status

# Voir les performances
./manage-strategies.sh performance
```

### **Scénario 2: Trading agressif multi-exchange**

```bash
# Démarrer la stratégie multi-exchange sur les deux exchanges
./start-multi-exchange.sh both

# Vérifier le statut
./start-multi-exchange.sh status
```

### **Scénario 3: Testing complet**

```bash
# Tester toutes les stratégies
./manage-strategies.sh test-all 20241201-20241210

# Comparer les résultats
./manage-strategies.sh compare HyperoptWorking,TrendFollowingStrategy
```

### **Scénario 4: Gestion quotidienne**

```bash
# Vérifier le statut au matin
./manage-strategies.sh status

# Voir les logs en cas de problème
./manage-strategies.sh logs MultiExchangeStrategy

# Nettoyer les fichiers si nécessaire
./manage-strategies.sh clean
```

---

## 🌐 **Interfaces Web**

Chaque stratégie démarre avec sa propre interface web sur un port différent :

| Stratégie | Port | Interface |
|-----------|------|-----------|
| HyperoptWorking | 8080 | <http://127.0.0.1:8080> |
| MultiExchangeStrategy | 8081 | <http://127.0.0.1:8081> |
| TrendFollowingStrategy | 8082 | <http://127.0.0.1:8082> |
| MeanReversionStrategy | 8083 | <http://127.0.0.1:8083> |
| PowerTowerStrategy | 8084 | <http://127.0.0.1:8084> |

---

## 📊 **Monitoring et Logs**

### **Fichiers de logs:**

- `user_data/logs/freqtrade-HyperoptWorking.log`
- `user_data/logs/freqtrade-MultiExchangeStrategy.log`
- `user_data/logs/freqtrade-TrendFollowingStrategy.log`
- `user_data/logs/freqtrade-MeanReversionStrategy.log`
- `user_data/logs/freqtrade-PowerTowerStrategy.log`

### **Suivi en temps réel:**

```bash
# Voir tous les logs en temps réel
tail -f user_data/logs/freqtrade-*.log

# Voir les logs d'une stratégie spécifique
tail -f user_data/logs/freqtrade-HyperoptWorking.log
```

### **Fichiers PID:**

- `user_data/logs/HyperoptWorking.pid`
- `user_data/logs/MultiExchangeStrategy.pid`
- etc.

---

## ⚠️ **Bonnes pratiques**

### **1. Ressources système**

- Surveillez l'utilisation CPU et mémoire
- Ne lancez pas trop de stratégies simultanément
- Utilisez des timeframes différents pour éviter les conflits

### **2. Gestion des trades**

- Chaque stratégie a son propre `max_open_trades`
- Configurez des stop-loss adaptés à chaque stratégie
- Surveillez la corrélation entre les stratégies

### **3. Maintenance**

- Nettoyez régulièrement les logs anciens
- Sauvegardez vos configurations
- Testez avant de déployer en live

### **4. Sécurité**

- Utilisez des clés API séparées si possible
- Limitez les permissions des clés API
- Surveillez les trades suspects

---

## 🆘 **Dépannage**

### **Problème: Stratégie ne démarre pas**

```bash
# Vérifier les logs
./manage-strategies.sh logs [STRATEGY_NAME]

# Vérifier la configuration
cat config-[STRATEGY_NAME].json

# Redémarrer
./manage-strategies.sh restart [STRATEGY_NAME]
```

### **Problème: Conflit de ports**

```bash
# Vérifier les ports utilisés
netstat -tulpn | grep :808

# Arrêter toutes les stratégies
./manage-strategies.sh stop all

# Redémarrer
./manage-strategies.sh start [STRATEGIES]
```

### **Problème: Performance dégradée**

```bash
# Voir le statut système
./manage-strategies.sh status

# Nettoyer les fichiers
./manage-strategies.sh clean

# Réduire le nombre de stratégies actives
```

---

## 🎉 **Résumé des commandes essentielles**

```bash
# Démarrage rapide
./manage-strategies.sh start HyperoptWorking,TrendFollowingStrategy

# Vérification
./manage-strategies.sh status

# Monitoring
./manage-strategies.sh logs HyperoptWorking

# Arrêt
./manage-strategies.sh stop all

# Nettoyage
./manage-strategies.sh clean
```

---

**🚀 Vous êtes maintenant prêt à faire tourner plusieurs stratégies simultanément !**

Choisissez l'approche qui correspond le mieux à vos besoins et commencez par tester en mode dry-run avant de passer en live.
