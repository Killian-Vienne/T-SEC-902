# Architecture Réseau Azure avec Terraform

Ce projet implémente l'architecture réseau décrite dans le schéma fourni, en utilisant Terraform pour déployer l'infrastructure sur Azure.

## Architecture

L'architecture est composée des éléments suivants :

- Un réseau virtuel Azure (10.0.0.0/16)
- 4 sous-réseaux :
  - Subnet Public/DMZ (10.0.1.0/24)
  - Subnet Sécurité (10.0.2.0/24)
  - Subnet Application (10.0.3.0/24)
  - Subnet Base de Données (10.0.4.0/24)
- Un service Azure Bastion
- Une VM pfSense (Firewall)
- Une VM Wazuh (SIEM)
- Une VM GLPI (Application Métier)
- Une VM de base de données (MySQL/PostgreSQL)

## Prérequis

- Terraform v1.0 ou plus récent
- Abonnement Azure actif
- Azure CLI

## Étapes de déploiement

### 1. Initialisation

```bash
cd terraform
terraform init
```

Cette commande initialise le backend Terraform Cloud et télécharge les providers nécessaires.

### 2. Planification

```bash
terraform plan -out=tfplan
```

Cette commande crée un plan d'exécution pour visualiser les ressources qui seront créées.

### 3. Déploiement

```bash
terraform apply tfplan
```

Cette commande déploie l'infrastructure selon le plan établi.

## Installation et configuration de GLPI

Après le déploiement de l'infrastructure, connectez-vous à la VM GLPI via Azure Bastion pour installer et configurer GLPI :

1. Se connecter à la VM via Bastion
2. Mettre à jour le système :
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```
3. Installer les dépendances nécessaires :
   ```bash
   sudo apt install -y apache2 mariadb-server php php-mysql php-curl php-gd php-intl php-pear php-imagick php-imap php-memcache php-pspell php-tidy php-xmlrpc php-mbstring php-ldap php-zip php-bz2 php-apcu
   ```
4. Configurer MySQL pour GLPI :
   ```bash
   sudo mysql -u root -p
   CREATE DATABASE glpi;
   CREATE USER 'glpi'@'localhost' IDENTIFIED BY 'LeMotDePasse';
   GRANT ALL PRIVILEGES ON glpi.* TO 'glpi'@'localhost';
   FLUSH PRIVILEGES;
   EXIT;
   ```
5. Télécharger et installer GLPI :
   ```bash
   cd /tmp
   wget https://github.com/glpi-project/glpi/releases/download/10.0.5/glpi-10.0.5.tgz
   sudo tar xvf glpi-10.0.5.tgz -C /var/www/html/
   sudo chown -R www-data:www-data /var/www/html/glpi/
   ```
6. Configurer Apache :
   ```bash
   sudo nano /etc/apache2/sites-available/glpi.conf
   ```
   Ajouter la configuration :
   ```
   <VirtualHost *:80>
     ServerName glpi.example.com
     DocumentRoot /var/www/html/glpi
     <Directory /var/www/html/glpi>
       Options Indexes FollowSymLinks
       AllowOverride All
       Require all granted
     </Directory>
     ErrorLog ${APACHE_LOG_DIR}/glpi-error.log
     CustomLog ${APACHE_LOG_DIR}/glpi-access.log combined
   </VirtualHost>
   ```
7. Activer le site et redémarrer Apache :
   ```bash
   sudo a2ensite glpi.conf
   sudo a2enmod rewrite
   sudo systemctl restart apache2
   ```
8. Accéder à l'interface web de GLPI pour terminer l'installation via l'IP de la VM GLPI ou le nom de domaine configuré.

## Configuration de Wazuh SIEM

1. Se connecter à la VM Wazuh via Bastion
2. Installer Wazuh Server :
   ```bash
   curl -sO https://packages.wazuh.com/4.3/wazuh-install.sh
   sudo bash wazuh-install.sh -a
   ```
3. Configurer les agents Wazuh sur les autres VMs pour collecter les journaux et surveiller la sécurité.

## Maintenance et mise à jour

Pour mettre à jour l'infrastructure :

```bash
terraform plan -out=tfplan
terraform apply tfplan
```

Pour détruire l'infrastructure :

```bash
terraform destroy
```

## Sécurité

- Les mots de passe sont générés aléatoirement avec `random_password`
- Les groupes de sécurité réseau contrôlent strictement le trafic entre les différents sous-réseaux
- Le service Azure Bastion sécurise l'accès aux machines virtuelles

## Adressage IP

| Réseau/Ressource | Plage CIDR | Description |
|------------------|------------|-------------|
| Azure Virtual Network | 10.0.0.0/16 | Réseau virtuel principal |
| Subnet Public (DMZ) | 10.0.1.0/24 | Sous-réseau pour le Bastion et pfSense |
| Subnet Sécurité | 10.0.2.0/24 | Sous-réseau pour Wazuh SIEM |
| Subnet Application | 10.0.3.0/24 | Sous-réseau pour l'application GLPI |
| Subnet Base de Données | 10.0.4.0/24 | Sous-réseau pour MySQL/PostgreSQL |
| Subnet Azure Bastion | 10.0.5.0/24 | Sous-réseau pour le service Azure Bastion |