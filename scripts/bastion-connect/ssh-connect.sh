#!/bin/bash
# This script establishes direct SSH connections to internal VMs
# from your local machine through the bastion host

BASTION_IP="20.232.136.151"
BASTION_USER="adminuser"

# Default SSH user for internal VMs
VM_USER="adminuser"

function show_help {
  echo "Usage: $0 [target] [ssh_key_path] [custom_command]"
  echo ""
  echo "Available targets:"
  echo "  bastion    - Direct connection to the bastion host"
  echo "  pfsense    - pfSense firewall (default user: admin)"
  echo "  wazuh      - Wazuh security server"
  echo "  glpi-web   - GLPI web application server"
  echo "  glpi-db    - GLPI database server"
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
    echo "Connecting directly to bastion host..."
    ssh $SSH_EXEC $KEY_OPTION $BASTION_USER@$BASTION_IP $CUSTOM_COMMAND
    exit 0
    ;;
  pfsense)
    TARGET_HOST="10.0.0.4"  # pfSense WAN interface
    ;;
  wazuh)
    TARGET_HOST="10.0.1.30"
    ;;
  glpi-web)
    TARGET_HOST="10.0.1.20"
    ;;
  glpi-db)
    TARGET_HOST="10.0.1.10"
    ;;
  *)
    echo "Unknown target: $TARGET"
    show_help
    exit 1
    ;;
esac

echo "Connecting to $TARGET ($TARGET_HOST) via bastion..."

if [ -z "$CUSTOM_COMMAND" ]; then
  # Interactive SSH session through the bastion
  ssh -J $BASTION_USER@$BASTION_IP $KEY_OPTION $VM_USER@$TARGET_HOST
else
  # Run specific command on the target machine
  ssh -J $BASTION_USER@$BASTION_IP $SSH_EXEC $KEY_OPTION $VM_USER@$TARGET_HOST "$CUSTOM_COMMAND"
fi