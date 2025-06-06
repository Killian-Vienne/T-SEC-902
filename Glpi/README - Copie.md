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
- Créer les fichiers de configuration

Nous devons configurer GLPI pour qu'il sache où aller chercher les données. Autrement dit, nous allons déclarer les nouveaux répertoires fraichement créés.

```bash
nano /var/www/glpi/inc/downstream.php
```

Afin d'ajouter le contenu ci-dessous qui indique le chemin vers le répertoire de configuration :

```php
<?php
define('GLPI_CONFIG_DIR', '/etc/glpi/');
if (file_exists(GLPI_CONFIG_DIR . '/local_define.php')) {
    require_once GLPI_CONFIG_DIR . '/local_define.php';
}
```

Ensuite, nous allons créer ce second fichier :

```bash
sudo nano /etc/glpi/local_define.php
```

Afin d'ajouter le contenu ci-dessous permettant de déclarer deux variables permettant de préciser les chemins vers les répertoires "files" et "log" que l'on a préparé précédemment.

```php
<?php
define('GLPI_VAR_DIR', '/var/lib/glpi/files');
define('GLPI_LOG_DIR', '/var/log/glpi');
```

### Préparer la config d'Apache2

Passons à la configuration du serveur web Apache2. Nous allons créer un nouveau fichier de configuration qui va permettre de configurer le VirtualHost dédié à GLPI. Ici, on appelle le fichier "support.it-connect.tech.conf" en référence au nom de domaine choisi pour accéder à GLPI : support.it-connect.tech. L'idéal étant d'avoir un nom de domaine (même interne) pour accéder à GLPI afin de pouvoir positionner un certificat SSL par la suite.

```bash
sudo nano /etc/apache2/sites-available/support.it-connect.tech.conf
```

```
<VirtualHost *:80>
    ServerName support.it-connect.tech

    DocumentRoot /var/www/glpi/public

    # If you want to place GLPI in a subfolder of your site (e.g. your virtual host is serving multiple applications),
    # you can use an Alias directive. If you do this, the DocumentRoot directive MUST NOT target the GLPI directory itself.
    # Alias "/glpi" "/var/www/glpi/public"

    <Directory /var/www/glpi/public>
        Require all granted

        RewriteEngine On

        # Redirect all requests to GLPI router, unless file exists.
        RewriteCond %{REQUEST_FILENAME} !-f
        RewriteRule ^(.*)$ index.php [QSA,L]
    </Directory>
</VirtualHost>
```

Maintenant, nous allons activer ce nouveau site dans Apache2 :

```bash
sudo a2ensite support.it-connect.tech.conf
```

Nous en profitons également pour désactiver le site par défaut car il est inutile :

```bash
sudo a2dissite 000-default.conf
```

Nous allons aussi activer le module "rewrite" (pour les règles de réécriture) car on l'a utilisé dans le fichier de configuration du VirtualHost (RewriteCond / RewriteRule).

```bash
sudo a2enmod rewrite
```

Il ne reste plus qu'à redémarrer le service Apache2 :

```bash
sudo systemctl restart apache2
```
### Utilisation de PHP8.2-FPM avec Apache2

Pour utiliser PHP en tant que moteur de scripts avec Apache2, il y a deux possibilités : utiliser le module PHP pour Apache2 (libapache2-mod-php8.2) ou utiliser PHP-FPM.

Il est recommandé d'utiliser PHP-FPM car il est plus performant et se présente comme un service indépendant. Dans l'autre mode, chaque processus Apache2 exécute son propre moteur de scripts PHP.

Si vous souhaitez utiliser PHP-FPM, suivez les étapes ci-dessous. Sinon, passez à la suite mais veillez à configurer l'option "session.cookie_httponly" évoquée ci-dessous.

Nous allons commencer par installer PHP8.2-FPM avec la commande suivante :

```bash
sudo apt-get install php8.2-fpm
```

Puis, nous allons activer deux modules dans Apache et la configuration de PHP-FPM, avant de recharger Apache2 :

```bash
sudo a2enmod proxy_fcgi setenvif
sudo a2enconf php8.2-fpm
sudo systemctl reload apache2
```

Pour configurer PHP-FPM pour Apache2, nous devons éditer le fichier :

```bash
sudo nano /etc/php/8.2/fpm/php.ini
```

Dans ce fichier, recherchez l'option "session.cookie_httponly" et indiquez la valeur "on" pour l'activer, afin de protéger les cookies de GLPI.

```nano
; Whether or not to add the httpOnly flag to the cookie, which makes it
; inaccessible to browser scripting languages such as JavaScript.
; https://php.net/session.cookie-httponly
session.cookie_httponly = on
```

Pour appliquer les modifications, nous devons redémarrer PHP-FPM :

```bash
sudo systemctl restart php8.2-fpm.service
```

Pour finir, nous devons modifier notre VirtualHost pour préciser à Apache2 que PHP-FPM doit être utilisé pour les fichiers PHP :

```bash
nano /etc/apache2/sites-available/support.it-connect.tech.conf
```

```bash
<FilesMatch \.php$>
    SetHandler "proxy:unix:/run/php/php8.2-fpm.sock|fcgi://localhost/"
</FilesMatch>
```

Maintenant plus qu'à relancer l'Apache

```bash
sudo systemctl restart apache2
```

Dernière étape : Installer GLPI 

## Installer GLPI

On ouvre le glpi dans le browser :

"localhost/"

*** EXPLICATION CONFIG GLPI DANS LE BROWSER ***

Pour se connecter : 
identifiant : glpi
mot de passe : glpi

et pour finir on delete le fichier "install.php" puisqu'il n'est plus nécessaire :

```bash
sudo rm /var/www/glpi/install/install.php
```