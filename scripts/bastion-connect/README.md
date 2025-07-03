# Bastion Connection Scripts

These scripts provide secure access to internal services in your Azure infrastructure through the bastion host. They create temporary SSH tunnels that allow you to access web interfaces and services without exposing them directly to the internet.

## Security Architecture

This infrastructure follows the secure design pattern where:
- Only the bastion host has a public IP address
- pfSense and all other internal services have only private IP addresses
- All access to internal services is proxied through SSH tunnels
- **SSH ports are customized for security**:
  - Bastion host: Port 2222 (public access)
  - Internal services: Port 2222 (Wazuh, GLPI), Port 22 (pfSense)

## Prerequisites

- SSH client installed on your local machine
- SSH key for authentication (recommended)
- The public IP address of your bastion host

## Setup

1. Edit both scripts to add your bastion details:
   - Open each script in a text editor
   - Replace `4.246.157.22` with the actual public IP of your bastion
   - Replace `adminuser` with your username on the bastion

2. Make the scripts executable:
   ```bash
   chmod +x connect.sh ssh-connect.sh
   ```

## Usage

### Connect to pfSense Admin Interface

```bash
./connect.sh pfsense 8443
```

This will create a secure tunnel to the pfSense web interface. Once connected, access the interface at:
https://localhost:8443

**Note**: The connection goes through the bastion (port 2222) to reach pfSense's web interface.

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
./connect.sh pfsense 8443 ~/.ssh/azure-ssh
./connect.sh wazuh 8444 ~/.ssh/azure-ssh
./connect.sh glpi 8080 ~/.ssh/azure-ssh
```

### Direct SSH Connections

```bash
./ssh-connect.sh TARGET [SSH_KEY_PATH] [CUSTOM_COMMAND]
```

Where:
- `TARGET` is one of: bastion, pfsense, wazuh, glpi-web, glpi-db
- `SSH_KEY_PATH` is the path to your SSH private key (optional)
- `CUSTOM_COMMAND` is a command to execute on the target (optional)

Examples:
```bash
./ssh-connect.sh bastion                    # Connect to bastion (port 2222)
./ssh-connect.sh pfsense                    # Connect to pfSense via bastion (pfSense port 22)
./ssh-connect.sh wazuh ~/.ssh/azure-ssh     # Connect to Wazuh via bastion (Wazuh port 2222)
./ssh-connect.sh glpi-web azure-ssh "cat /var/log/nginx/error.log"
```

## Available Services

- **pfsense**: pfSense web interface (HTTPS) - Internal SSH port 22
- **wazuh**: Wazuh web interface (HTTPS) - Internal SSH port 2222
- **glpi**: GLPI web interface (HTTP) - Internal SSH port 2222

## Port Configuration

| Service | Bastion SSH Port | Internal SSH Port | Web Port | Protocol |
|---------|------------------|-------------------|----------|----------|
| Bastion | 2222 | - | - | SSH |
| pfSense | 2222 (via bastion) | 22 | 443 | HTTPS |
| Wazuh | 2222 (via bastion) | 2222 | 3000 | HTTP |
| GLPI Web | 2222 (via bastion) | 2222 | 443 | HTTPS |
| GLPI DB | 2222 (via bastion) | 2222 | - | SSH |

## Connection Flow

1. **Direct bastion connection**: `ssh -p 2222 user@bastion-ip`
2. **Service via bastion**: `ssh -J user@bastion-ip:2222 -p [internal-port] user@internal-ip`
3. **Tunneling**: `ssh -L local-port:internal-ip:web-port -p 2222 user@bastion-ip`

## Stopping the Connection

Press `Ctrl+C` in the terminal where the script is running to close the connection.