#!/bin/bash
# Script pour créer un utilisateur sous Linux

if [ "$EUID" -ne 0 ]; then
  echo "Ce script doit être exécuté en tant que root."
  exit 1
fi

if [ -z "$1" ]; then
  echo "Usage: $0 nom_utilisateur"
  exit 1
fi

USERNAME="$1"

# Créer l'utilisateur
useradd -m "$USERNAME"
if [ $? -eq 0 ]; then
  echo "Utilisateur $USERNAME créé avec succès."
else
  echo "Erreur lors de la création de l'utilisateur $USERNAME."
  exit 1
fi

# Définir le mot de passe
passwd "$USERNAME"

# Ajouter l'utilisateur au groupe sudo
usermod -aG sudo "$USERNAME"
if [ $? -eq 0 ]; then
  echo "Utilisateur $USERNAME ajouté au groupe sudo."
else
  echo "Erreur lors de l'ajout de $USERNAME au groupe sudo."
  exit 1
fi

# Vérifier le statut du firewall et autoriser l'accès SSH si nécessaire
echo "\nVérification du statut du firewall (ufw)..."
if command -v ufw >/dev/null 2>&1; then
  STATUS=$(ufw status | grep -i "Status: active")
  if [ -n "$STATUS" ]; then
    echo "Le firewall ufw est actif. Vérification de l'accès SSH..."
    SSH_ALLOWED=$(ufw status | grep -i "ssh")
    if [ -z "$SSH_ALLOWED" ]; then
      echo "Le port SSH n'est pas autorisé. Autorisation en cours..."
      ufw allow ssh
      if [ $? -eq 0 ]; then
        echo "Accès SSH autorisé dans le firewall."
      else
        echo "Erreur lors de l'autorisation SSH dans le firewall."
        exit 1
      fi
    else
      echo "Le port SSH est déjà autorisé dans le firewall."
    fi
  else
    echo "Le firewall ufw n'est pas actif."
  fi
else
  echo "ufw n'est pas installé sur ce système."
fi

echo "\nGénére la paire de clé pour la connexion au VPS"
read -p "Entrez le nom du fichier de la clé SSH (exemple: github-deploy-key-mysite): " KEY_NAME
echo "\nCopie la commande ci-dessous et exécute la sur ta machine local ou codespaces"
echo "\nssh-keygen -t rsa -b 4096 -C $KEY_NAME -f ~/.ssh/$KEY_NAME"
echo "\nPuis copie le contenu de $KEY_NAME.pub dans le fichier ~/.ssh/authorized_keys de ton VPS"
echo "cat $KEY_NAME.pub | ssh $USERNAME@votre_ip 'mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && chmod 700 ~/.ssh'"