FROM python:3.11-slim

# Installer les dépendances système
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    make \
    libffi-dev \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Créer le répertoire de travail
WORKDIR /app

# Copier les fichiers de configuration
COPY requirements.txt .
COPY config.json .
COPY freqtrade_hyperopt.json .
COPY .env .

# Installer les dépendances Python
RUN pip install --no-cache-dir -r requirements.txt

# Copier le code source
COPY user_data/ ./user_data/
COPY scripts/ ./scripts/

# Créer les répertoires nécessaires
RUN mkdir -p /app/user_data/data
RUN mkdir -p /app/user_data/logs
RUN mkdir -p /app/user_data/backtest_results

# Exposer le port pour l'API
EXPOSE 8080

# Commande par défaut
CMD ["freqtrade", "trade", "--config", "config.json", "--strategy", "SampleStrategy"]
