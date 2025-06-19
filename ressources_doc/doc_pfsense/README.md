# PfSense

## C'est quoi ?

PfSense est un système d'exploitation open source basé sur FreeBSD, spécialement conçu pour fonctionner comme un pare-feu et un routeur. Il offre une solution complète de sécurité réseau avec des fonctionnalités avancées telles que :

- Pare-feu avec état (Stateful Firewall)
- Routage et NAT
- VPN (IPSec, OpenVPN, WireGuard)
- Filtrage de contenu
- Équilibrage de charge
- Surveillance du trafic
- Authentification des utilisateurs
- Protection contre les attaques DDoS

Sa popularité vient de sa stabilité, sa sécurité et sa facilité d'utilisation grâce à son interface web intuitive.

## Création de l'image PfSense

1. Télécharger l'image officielle de [PfSense](https://www.pfsense.org/download/)
2. Utiliser un outil de virtualisation (ex: VirtualBox)
   ```
   ATTENTION: Le disque dur virtuel créé doit être :
        - au format VHD
        - de taille fixe
   ```
3. Démarrer sur l'image précédemment téléchargée pour installer l'OS
4. Effectuer un premier démarrage de la machine pour l'initialiser, en veillant à retirer correctement l'ISO d'installation
5. Réaliser les premiers paramétrages de base
6. Rendez-vous dans le répertoire de la VM puis copiez le VHD, cela est l'image qui sera utilisée pour Azure

## Paramétrage

### Configuration de la VM

Une fois la première initialisation de la VM effectuée, il est nécessaire d'effectuer quelques opérations pour que l'image utilisée sur l'architecture Azure soit pleinement fonctionnelle.

#### Configuration du démarrage

Avant de continuer, il faudra créer un fichier nommé `loader.conf.local` afin de virtualiser un port physique pour communiquer avec la machine en entrée série.

```sh
# Configuration de la console série pour Azure
boot.config="-S115200 -h"
comconsole_speed="115200"
comconsole_port="0x3F8"  # Adresse du port COM1
console="comconsole,vidconsole"
boot_multicons="YES"
boot_serial="YES"

# Forcer la sortie du noyau vers la console série
kern.cam.boot_delay=10000  # Donner plus de temps pour la détection des disques
kern.hz="100"  # Recommandé pour les environnements virtuels

# Paramètres spécifiques à Azure/Hyper-V
hw.pci.enable_msix="0"  # Désactiver MSI-X qui peut causer des problèmes dans Hyper-V
hw.pci.enable_msi="0"   # Désactiver MSI qui peut causer des problèmes dans Hyper-V
```

Cette configuration sera très utile pour continuer la configuration de la machine une fois qu'elle sera déployée sur l'architecture Azure.

### Configuration du SSH

Pour ajouter une clé publique SSH dans l'interface graphique de pfSense, voici la procédure à suivre :

1. Connectez-vous à l'interface web de pfSense avec votre identifiant et mot de passe
2. Allez dans le menu "System"
3. Sélectionnez "User Manager"
4. Recherchez l'utilisateur pour lequel vous souhaitez ajouter une clé SSH et cliquez sur l'icône de modification (crayon)
5. Faites défiler vers le bas jusqu'à la section "Keys"
6. Dans le champ "Authorized keys", collez votre clé publique SSH
7. Cliquez sur "Save" pour valider les modifications

Assurez-vous que votre clé publique SSH est au format correct (commence généralement par "ssh-rsa" ou "ssh-ed25519" suivi d'une longue chaîne de caractères).

N'oubliez pas de vérifier également que le service SSH est activé dans "System" > "Advanced" > onglet "Admin Access" et que les règles de pare-feu permettent l'accès SSH. Vérifier également que le protocole web utilisé est HTTPS. Cliquez sur Save pour valider les modifications

Veillez a désactiver l'IPv6 pour l'interface LAN dans "Interfaces" > "LAN" puis valider.

Ajouter une règle pour le traffic entrant, pour cela allez dans Firewall > Rules puis sélectionnez l'onglet WAN. Cliquez sur Add pour ajouter une nouvelle règle :

```
* Action : Pass
* Interface : WAN
* Address Family : IPv4
* Protocol : Any
* Source : any
* Destination : This Firewall (self)
* Description : ""
```

Cliquez sur Save
Cliquez à nouveau sur Add

```
* Action : Block
* Interface : WAN
* Address Family : IPv4
* Protocol : TCP
* Source : any
* Destination : Any
* Description : "Block all on WAN"
```

Cliquez sur Save

Ajouter une règle de redirection des ports dans le menu "Firewall" > "NAT" > "Port Forward" :

Port forward HTTP / HTTPS :
```
* Interface : WAN
* Protocol : TCP
* Redirect target IP : 10.0.1.20
* Redirect target port : 80
* Destination port range : 80
* Description : "Port forward HTTP to GLPI"
```
```
* Interface : WAN
* Protocol : TCP
* Redirect target IP : 10.0.1.20
* Redirect target port : 443
* Destination port range : 443
* Description : "Port forward HTTPS to GLPI"
```
Laisse sur Add associated filter rule (ça va créer automatiquement la règle firewall qui va avec).

### Déploiement sur Azure

Lorsque la VM PfSense est déployée dans le cloud :
1. Accédez à son interface de monitoring via Azure
2. Rendez-vous dans le menu `Diagnostics de démarrage`
3. allez dans les paramètres :
   - Sélectionnez le bon compte de stockage
   - Sauvegardez les modifications

À partir de maintenant, vous aurez accès à un terminal de votre VM via la console série. Vous en aurez besoin pour configurer les interfaces **WAN** et **LAN**.
