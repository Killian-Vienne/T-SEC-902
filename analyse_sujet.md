# Introduction
Nous somme dans l'entreprise Arasaka

Mise en place d'un firewall capable de protéger la vitalité de l'infrastructure et utilisateurs en cas de cyber attaque
Cela nécessite de déployer et maintenir effectif le firewall

# Plusieurs point important sur les quels travailler :
1. Strengthen Arasaka’s Defenses
```
- La sécurisation des ports, les grader fermé si inutile etc... | Monitoring des ports ouvert et ainsi du trafic
```

2. Suspicious movements from Pacifica and other high-risk areas
```
- Filtrage du traffic sortant/entrant : Stratégie Zero Trust/Default Deny
```

3. Limiting the flow of connections to protect the digital bastion
```
- Prévention attaque DOS (Deny Of Service) | Qui nous DOS ?? | Etablissement d'une liste des quelques personnes pouvant rentrer dans le réseau avec VPN | Liste @MAC (adresse MAC) | Nombre de connexion simultanée en SSH limité
```

4. Securing vital areas, isolating for better defense
```
- Masque de sous-réseau + Utilisateur de classe IP privée différente : A/B/C etc...
```

5. Detect hidden transmissions in the information flow
```
- Detect hidden transmissions in the information flow
```

6. Limit external access to Arasaka’s eyes only
```
- Clé SSH tournante voir autre chose que du SSH (ex: AES)
```

7. Stop Militech’s underhand explorations
```
- Surveillez tout notre réseau, nos points d'accès etc afin de détecter les nmap ou toute tentative de détection de vulnérabilité par l'ennemie.
```

8. Keeping out non-Arasaka-approved tools
```
- Analyse de tout les PC ou machines afin de détecter des logiciel malveillant ou non voulu a l'installation, seulement des logiciel qui sont officialisé par Arasaka
```

9. Monitor outgoing traffic to identify traitors
```
- Infiltration sur site | désactiver les ports USB classique des machines ou seulement sur autorisation
```

10. Detecting and warning of impending attacks
```
- Monitoring et alarme des attaques ou actions malveillante détectées
```

# Livraisons attendu :
1. Diagram of Arasaka’s network and illustration of the secured zones.
2. Analysis of Arasaka’s network security requirements.
3. Selection and design of the firewall architecture.
4. Implementation of the firewall and the WAF within Arasaka’s Network.
5. A security audit of your network after it has been secured.

# A propos du Firewall : 
Utiliser le firewall pfSense. Pour ce faire utiliser des ressources terraform, crée une vm et utilisé ansible dans celle ci pour installer le firewall

use the terraform resource provided,
create a new vm in it and use Ansible to install your firewall.


# Remarque
1. On peux utiliser ModSecurity afin d'accomplir la 'WAF Task'
2. Toutes les livraisons devront être en anglais

