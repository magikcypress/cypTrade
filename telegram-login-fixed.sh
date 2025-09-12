#!/bin/bash

# Script corrigé pour les notifications de connexion Telegram

# Configuration Telegram (à adapter)
CHATID="YOUR_CHAT_ID"
BOTKEY="YOUR_BOT_TOKEN"

# get hostname
HOSTNM=$(hostname)

# get external IP address
IP="185.209.230.194"

# Vérifier si la commande last existe
if command -v last >/dev/null 2>&1; then
    # find IP address of person last logged in
    LOGININFO=$(last -1 -i | head -n 1)
    
    # Vérifier si LOGININFO n'est pas vide
    if [ -n "$LOGININFO" ]; then
        # parse into nice format avec vérification
        LOGININFO1=$(python3 -c "
import sys
login = '$LOGININFO'.split('   ')
# Nettoyer les éléments vides
login = [x.strip() for x in login if x.strip()]
# Vérifier qu'on a au moins 2 éléments
if len(login) >= 2:
    # Garder seulement les 2 premiers éléments
    result = login[:2]
    print('   '.join(result))
else:
    print('Unknown login')
")
    else
        LOGININFO1="No recent login found"
    fi
else
    LOGININFO1="Last command not available"
fi

# Alternative: utiliser who ou w si last n'est pas disponible
if [ "$LOGININFO1" = "Last command not available" ]; then
    # Utiliser who pour obtenir les connexions actuelles
    CURRENT_USERS=$(who | head -1)
    if [ -n "$CURRENT_USERS" ]; then
        LOGININFO1="Current users: $CURRENT_USERS"
    else
        LOGININFO1="No current users"
    fi
fi

# send information to telegram notification bot
curl -X POST -H 'Content-Type: application/json' \
     -d "{\"chat_id\": \"$CHATID\", \"text\": \"🔐 Log in to: $HOSTNM\n🌐 IP: $IP\n👤 From: $LOGININFO1\", \"disable_notification\": false}" \
     https://api.telegram.org/bot$BOTKEY/sendMessage \
     --silent > /dev/null

echo "Notification sent to Telegram"
