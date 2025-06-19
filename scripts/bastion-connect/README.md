# Bastion Connection Scripts

These scripts provide secure access to internal services in your Azure infrastructure through the bastion host. They create temporary SSH tunnels that allow you to access web interfaces and services without exposing them directly to the internet.

## Security Architecture

This infrastructure follows the secure design pattern where:
- Only the bastion host has a public IP address
- pfSense and all other internal services have only private IP addresses
- All access to internal services is proxied through SSH tunnels

## Prerequisites

- SSH client installed on your local machine
- SSH key for authentication (recommended)
- The public IP address of your bastion host

## Setup

1. Edit both scripts to add your bastion details:
   - Open each script in a text editor
   - Replace `YOUR_BASTION_PUBLIC_IP` with the actual public IP of your bastion
   - Replace `YOUR_USERNAME` with your username on the bastion

2. Make the scripts executable:
   ```bash
   chmod +x connect.sh connect-pfsense.sh
   ```

## Usage

### Connect to pfSense Admin Interface

```bash
./connect.sh pfsense 8443
```

This will create a secure tunnel to the pfSense web interface. Once connected, access the interface at:
https://localhost:8443

### Connect to Other Services

```bash
./connect.sh SERVICE LOCAL_PORT [SSH_KEY_PATH]
```

Where:
- `SERVICE` is one of: pfsense, wazuh, glpi
- `LOCAL_PORT` is the port you want to use on your local machine
- `SSH_KEY_PATH` is the path to your SSH private key (optional but recommended)

Examples:
```bash
./connect.sh pfsense 8443 ~/.ssh/id_rsa
./connect.sh wazuh 8444 ~/.ssh/id_rsa
./connect.sh glpi 8080 ~/.ssh/id_rsa
```

## Available Services

- **pfsense**: pfSense web interface (HTTPS)
- **wazuh**: Wazuh web interface (HTTPS)
- **glpi**: GLPI web interface (HTTP)

## Stopping the Connection

Press `Ctrl+C` in the terminal where the script is running to close the connection. 