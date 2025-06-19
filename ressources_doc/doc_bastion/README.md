# Bastion

## Introduction

Le bastion est une machine intermédiaire, placée dans un sous-réseau sécurisé, qui sert de point d’accès unique pour administrer les autres machines de l’infrastructure.
Il permet de renforcer la sécurité en évitant d’exposer directement les VMs internes (GLPI, Wazuh, etc.) à Internet.

## Rôle dans l’infrastructure

- Point d’entrée sécurisé : Seule l’IP publique du bastion est exposée sur Internet.
- Accès aux VMs internes : On se connecte d’abord au bastion, puis on rebondit vers les autres VMs (qui n’acceptent que des connexions SSH venant du bastion).
- Filtrage réseau : Les règles de sécurité (NSG, pfSense) n’autorisent le SSH vers les VMs internes que depuis le bastion.

## Connexion au bastion

1. Connexion directe en SSH
Pour te connecter directement au bastion depuis ta machine locale :

```sh
ssh -i ~/.ssh/azure-ssh adminuser@<IP_PUBLIQUE_BASTION>
```
2. Utilisation du script connect.sh
Ce script (si présent dans ton projet) permet de simplifier la connexion SSH au bastion.
Exemple d’utilisation :

```sh
./connect.sh
```
ou

```sh
./connect.sh ~/.ssh/azure-ssh
```

Le script utilise la clé SSH spécifiée (ou celle par défaut) pour ouvrir une session sur le bastion.

3. Utilisation du script ssh-connect.sh

Ce script permet de se connecter facilement à n’importe quelle VM interne via le bastion, ou d’exécuter une commande à distance.

- Connexion à pfSense via le bastion :
```sh
./ssh-connect.sh pfsense ~/.ssh/azure-ssh
```

- Connexion à Wazuh via le bastion :
```sh
./ssh-connect.sh wazuh ~/.ssh/azure-ssh
```

- Connexion à GLPI web via le bastion :
```sh
./ssh-connect.sh glpi-web ~/.ssh/azure-ssh
```

- Exécution d’une commande sur une VM via le bastion :
```sh
./ssh-connect.sh glpi-web ~/.ssh/azure-ssh "cat /var/log/nginx/error.log"
```

```text
[Votre PC] --(SSH)--> [Bastion] --(SSH interne)--> [VM interne (GLPI, Wazuh, etc.)]
```