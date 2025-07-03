# Automatisation de Blacklist IP sur pfSense - Architecture Arasaka

## Vue d'ensemble

Ce document décrit l'implémentation d'un système d'automatisation pour l'ajout d'adresses IP en blacklist sur le firewall pfSense dans l'infrastructure. Cette solution s'intègre dans l'architecture existante et répond aux exigences de sécurité définies dans le projet T-SEC-902.

## Architecture de l'automatisation

### Composants du système

1. **pfSense Firewall** : Point central de filtrage réseau
2. **Wazuh SIEM** : Détection et corrélation des événements de sécurité
3. **Bastion Host** : Point d'accès sécurisé pour l'administration
4. **Scripts d'automatisation** : Logique métier pour la gestion des blacklists
5. **Base de données de blacklist** : Stockage centralisé des IPs bloquées

### Flux de données

```
[Sources de menaces] → [Wazuh SIEM] → [Scripts d'automatisation] → [pfSense API] → [Firewall Rules]
                                    ↓
                            [Base de données blacklist]
```

## Sources de données pour la blacklist

### 1. Wazuh SIEM
- **Détection d'attaques** : Tentatives de brute force, scans de ports, attaques DDoS
- **Corrélation d'événements** : Analyse des patterns d'attaque
- **Alertes en temps réel** : Notifications automatiques

### 2. Sources externes
- **Feeds de menaces** : Listes d'IPs malveillantes connues
- **OSINT** : Intelligence en sources ouvertes
- **CertFr** : Alertes de sécurité françaises

### 3. Monitoring réseau
- **Trafic suspect** : Détection de comportements anormaux
- **Tentatives d'intrusion** : Logs de sécurité pfSense
- **Violations de politique** : Accès non autorisés

## Méthodes d'intégration avec pfSense

### 1. API pfSense (Recommandée)

#### Configuration de l'API
- **Activation** : System > Advanced > Admin Access > Enable pfSense API
- **Authentification** : Token-based ou Basic Auth
- **Sécurité** : HTTPS obligatoire, restrictions d'IP

#### Endpoints utilisés
```bash
# Ajout d'une règle de blocage
POST /api/v1/firewall/rule
{
  "interface": "wan",
  "type": "block",
  "ipprotocol": "inet",
  "src": "IP_ADDRESS",
  "descr": "Auto-blocked IP"
}

# Gestion des alias
POST /api/v1/firewall/alias
{
  "name": "blacklist_ips",
  "type": "host",
  "address": "IP_ADDRESS"
}
```

### 2. Scripts de configuration

#### Utilisation de pfSense CLI
```bash
# Connexion SSH au firewall
ssh admin@pfsense_ip

# Ajout d'une règle via CLI
pfctl -t blacklist -T add IP_ADDRESS
```

#### Fichiers de configuration
- **Aliases** : `/cf/conf/aliases.xml`
- **Rules** : `/cf/conf/rules.xml`
- **Backup** : Sauvegarde automatique avant modification

## Implémentation technique

### 1. Script principal d'automatisation

#### Localisation
```
/scripts/pfsense-blacklist/
├── main.py              # Script principal
├── config.yaml          # Configuration
├── blacklist.db         # Base SQLite locale
├── logs/                # Logs d'exécution
└── templates/           # Templates de règles
```

#### Fonctionnalités
- **Détection automatique** : Surveillance continue des sources
- **Validation des IPs** : Vérification de format et de validité
- **Gestion des conflits** : Éviter les doublons
- **Rollback automatique** : Restauration en cas d'erreur
- **Notifications** : Alertes par email/Slack

### 2. Intégration avec Wazuh

#### Configuration Wazuh
```yaml
# /etc/ossec/ossec.conf
<integration>
  <name>pfsense_blacklist</name>
  <hook_url>http://localhost:5000/api/blacklist</hook_url>
  <api_url>https://pfsense_ip/api/v1</api_url>
  <api_token>YOUR_TOKEN</api_token>
</integration>
```

#### Règles de corrélation
```xml
<!-- Règle pour détecter les attaques répétées -->
<rule id="100001" level="10">
  <if_sid>100000</if_sid>
  <field name="srcip">\.+</field>
  <options>threshold:5,timeframe:300</options>
  <description>Multiple failed login attempts from same IP</description>
</rule>
```

### 3. Base de données de blacklist

#### Structure SQLite
```sql
CREATE TABLE blacklist_ips (
    id INTEGER PRIMARY KEY,
    ip_address TEXT NOT NULL UNIQUE,
    reason TEXT,
    source TEXT,
    added_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_date TIMESTAMP,
    status TEXT DEFAULT 'active'
);

CREATE TABLE blacklist_logs (
    id INTEGER PRIMARY KEY,
    ip_address TEXT,
    action TEXT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    details TEXT
);
```

## Sécurité et bonnes pratiques

### 1. Validation des données
- **Format IP** : Validation IPv4/IPv6
- **Ranges autorisés** : Éviter le blocage d'IPs internes
- **Whitelist** : Protection des IPs critiques
- **Rate limiting** : Limitation des ajouts automatiques

### 2. Gestion des erreurs
- **Logs détaillés** : Traçabilité complète
- **Alertes d'erreur** : Notifications immédiates
- **Mode dégradé** : Fonctionnement sans automatisation
- **Tests de régression** : Validation avant déploiement

### 3. Performance
- **Cache local** : Réduction des appels API
- **Batch processing** : Traitement par lots
- **Optimisation des requêtes** : Indexation de la base
- **Monitoring** : Surveillance des performances

## Configuration de déploiement

### 1. Prérequis
```bash
# Installation des dépendances
pip install requests pyyaml sqlite3 schedule

# Permissions
chmod +x /scripts/pfsense-blacklist/main.py
chown -R pfsense:pfsense /scripts/pfsense-blacklist/
```

### 2. Configuration du service
```ini
# /etc/systemd/system/pfsense-blacklist.service
[Unit]
Description=pfSense Blacklist Automation
After=network.target

[Service]
Type=simple
User=pfsense
WorkingDirectory=/scripts/pfsense-blacklist
ExecStart=/usr/bin/python3 main.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

### 3. Monitoring et alertes
```yaml
# Configuration des alertes
alerts:
  email:
    smtp_server: "smtp.arasaka.com"
    recipients: ["security@arasaka.com"]
  slack:
    webhook_url: "https://hooks.slack.com/services/..."
  webhook:
    url: "https://api.arasaka.com/security/alerts"
```

## Tests et validation

### 1. Tests unitaires
```python
# tests/test_blacklist.py
def test_ip_validation():
    assert is_valid_ip("192.168.1.1") == True
    assert is_valid_ip("invalid_ip") == False

def test_api_connection():
    assert test_pfsense_api() == True
```

### 2. Tests d'intégration
- **Test d'ajout d'IP** : Validation du processus complet
- **Test de rollback** : Vérification de la restauration
- **Test de performance** : Charge et temps de réponse
- **Test de sécurité** : Validation des permissions

### 3. Environnement de test
- **VM de test** : Réplique de l'environnement de production
- **Données de test** : IPs fictives pour validation
- **Monitoring** : Surveillance des tests automatisés