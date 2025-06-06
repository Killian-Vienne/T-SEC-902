# T-SEC-902

## Set up Azure CLI

### Prérequis

To have a Debian12 installed.

### Install Debian 12 (Oracle VB)

## Introduction

nous allons effectuer une installation pas-à-pas de GLPI 10 sur une machine Debian 12, en mettant en place Apache2, PHP 8.2 (PHP-FPM) et MariaDB Server.

## Set up GLPI

Premièrement, on met à jour notre debian12 :

``` bash
    sudo apt-get update && sudo apt-get upgrade
```

### Installer LAMP

installer les paquets du socle LAMP : ( Linux Apache2 MariaDB PHP )

``` bash
    sudo apt-get install apache2 php mariadb-server
```

ensuite toutes les extensions nécessaires au bon fonctionnement du glpi :

``` bash
    sudo apt-get install php-xml php-common php-json php-mysql php-mbstring php-curl php-gd php-intl php-zip php-bz2 php-imap php-apcu
```

### Préparer une base de données pour GLPI

``` bash
sudo mysql_secure_installation
```

vérifions si l'installation s'est bien passé :

```bash
sudo mysql -u root -p
```

on créait notre db, pour ce test on utilisera :

``` MYSQL
CREATE DATABASE db_glpi;
GRANT ALL PRIVILEGES ON db_glpi.* TO glpi_adm@localhost IDENTIFIED BY "MotDePasseRobuste";
FLUSH PRIVILEGES;
EXIT
```

Maintenant notre basse de donnée est prête.

### Télécharger GLPI et préparer son installation

GitHub de GLPI : https://github.com/glpi-project/glpi/releases/download/10.0.10/glpi-10.0.10.tgz

```bash
cd /tmp
wget https://github.com/glpi-project/glpi/releases/download/10.0.10/glpi-10.0.10.tgz
```

Puis, nous allons exécuter la commande ci-dessous pour décompresser l'archive .tgz dans le répertoire "/var/www/", ce qui donnera le chemin d'accès "/var/www/glpi" pour GLPI.

```bash
sudo tar -xzvf glpi-10.0.10.tgz -C /var/www/
```

Nous allons définir l'utilisateur "www-data" correspondant à Apache2, en tant que propriétaire sur les fichiers GLPI.

```bash
sudo chown www-data /var/www/glpi/ -R
```

On suit les recommendations de l'éditeur pour l'installation sécurisé de GLPI => cela nécessite de créer des dossiers.

- Le Dossier /etc/glpi : 
Commencez par créer le répertoire "/etc/glpi" qui va recevoir les fichiers de configuration de GLPI. Nous donnons des autorisations à www-data sur ce répertoire car il a besoin de pouvoir y accéder.

```bash
sudo mkdir /etc/glpi
sudo chown www-data /etc/glpi/
```
Puis, nous allons déplacer le répertoire "config" de GLPI vers ce nouveau dossier :

```bash
sudo mv /var/www/glpi/config /etc/glpi
```

- Le Dossier /var/lib/glpi

On fait de même avec le dossier /var/lib/glpi, il contiendra le dossier "files" qui contient la majorité des fichiers de GLPI : CSS, plugins, etc.

```bash
sudo mkdir /var/lib/glpi
sudo chown www-data /var/lib/glpi/
```

```bash
sudo mv /var/www/glpi/files /var/lib/glpi
```

- Le Dossier /var/log/glpi

Dernier dossier : la création du répertoire "/var/log/glpi" destiné à stocker les journaux de GLPI

```bash
sudo mkdir /var/log/glpi
sudo chown www-data /var/log/glpi
```

```bash

```