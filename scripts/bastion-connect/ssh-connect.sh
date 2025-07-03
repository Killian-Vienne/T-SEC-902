#!/bin/bash
# This script establishes direct SSH connections to internal VMs
# from your local machine through the bastion host

BASTION_IP="4.246.157.22"
BASTION_USER="adminuser"
BASTION_PORT="2222"  # Le bastion écoute sur le port 2222

# Default SSH user for internal VMs
VM_USER="adminuser"

function show_help {
  echo "Usage: $0 [target] [ssh_key_path] [custom_command]"
  echo ""
  echo "Available targets:"
  echo "  bastion    - Direct connection to the bastion host (port 2222)"
  echo "  pfsense    - pfSense firewall (default user: admin, via bastion)"
  echo "  wazuh      - Wazuh security server (via bastion, port 2222)"
  echo "  glpi-web   - GLPI web application server (via bastion, port 2222)"
  echo "  glpi-db    - GLPI database server (via bastion, port 2222)"
  echo ""
  echo "Examples:"
  echo "  $0 pfsense                    - Connect to pfSense through bastion"
  echo "  $0 wazuh ~/.ssh/azure-ssh     - Connect to Wazuh using specified SSH key"
  echo "  $0 glpi-web azure-ssh \"cat /var/log/nginx/error.log\"  - Run custom command on GLPI web server"
  echo "  $0 bastion                    - Connect directly to the bastion host"
}

if [ "$#" -lt 1 ]; then
  show_help
  exit 1
fi

TARGET=$1

# Check if an SSH key was provided
if [ "$#" -ge 2 ]; then
  KEY_OPTION="-i $2"
  echo "Using SSH key: $2"
else
  KEY_OPTION=""
fi

# Check if a custom command was provided
if [ "$#" -ge 3 ]; then
  shift 2  # Shift past the first two arguments
  CUSTOM_COMMAND="$*"
  echo "Will execute: $CUSTOM_COMMAND"
  SSH_EXEC="-t"
else
  CUSTOM_COMMAND=""
  SSH_EXEC=""
fi

case $TARGET in
  bastion)
    echo "Connecting directly to bastion host (port 2222)..."
    ssh $SSH_EXEC -p $BASTION_PORT $KEY_OPTION $BASTION_USER@$BASTION_IP $CUSTOM_COMMAND
    exit 0
    ;;
  pfsense)
    TARGET_HOST="10.0.0.4"  # pfSense WAN interface
    TARGET_PORT="22"  # pfSense écoute sur le port 22
    ;;
  wazuh)
    TARGET_HOST="10.0.1.30"
    TARGET_PORT="2222"  # Wazuh écoute sur le port 2222
    ;;
  glpi-web)
    TARGET_HOST="10.0.1.20"
    TARGET_PORT="2222"  # GLPI Web écoute sur le port 2222
    ;;
  glpi-db)
    TARGET_HOST="10.0.1.10"
    TARGET_PORT="2222"  # GLPI DB écoute sur le port 2222
    ;;
  *)
    echo "Unknown target: $TARGET"
    show_help
    exit 1
    ;;
esac

echo "Connecting to $TARGET ($TARGET_HOST) via bastion..."
echo "Bastion port: $BASTION_PORT, Target port: $TARGET_PORT"

if [ -z "$CUSTOM_COMMAND" ]; then
  # Interactive SSH session through the bastion
  ssh -J $BASTION_USER@$BASTION_IP:$BASTION_PORT -p $TARGET_PORT $KEY_OPTION $VM_USER@$TARGET_HOST
else
  # Run specific command on the target machine
  ssh -J $BASTION_USER@$BASTION_IP:$BASTION_PORT -p $TARGET_PORT $SSH_EXEC $KEY_OPTION $VM_USER@$TARGET_HOST "$CUSTOM_COMMAND"
fi