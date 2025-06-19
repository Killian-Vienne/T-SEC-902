#!/bin/bash
# This script establishes a secure tunnel to internal services
# from your local machine through the bastion host

BASTION_IP="20.172.128.68"
BASTION_USER="adminuser"

function show_help {
  echo "Usage: $0 [service] [local_port] [ssh_key_path]"
  echo ""
  echo "Available services:"
  echo "  pfsense     - pfSense web interface (HTTPS)"
  echo "  wazuh       - Wazuh web interface (HTTPS)"
  echo "  glpi        - GLPI web interface (HTTP)"
  echo ""
  echo "Example: $0 pfsense 8443 ~/.ssh/id_rsa"
  echo "         $0 glpi 8080"
}

if [ "$#" -lt 2 ]; then
  show_help
  exit 1
fi

SERVICE=$1
LOCAL_PORT=$2

# Check if an SSH key was provided
if [ "$#" -ge 3 ]; then
  KEY_OPTION="-i $3"
  echo "Using SSH key: $3"
else
  KEY_OPTION=""
fi

case $SERVICE in
  pfsense)
    TARGET_HOST="10.0.1.4"  # pfSense WAN interface
    TARGET_PORT="443"
    PROTOCOL="https"
    ;;
  wazuh)
    TARGET_HOST="10.0.1.30"
    TARGET_PORT="3000"
    PROTOCOL="http"
    ;;
  glpi)
    TARGET_HOST="10.0.1.20"
    TARGET_PORT="443"
    PROTOCOL="https"
    ;;
  *)
    echo "Unknown service: $SERVICE"
    show_help
    exit 1
    ;;
esac

echo "Establishing secure tunnel to $SERVICE..."
echo "Once connected, access the service at: $PROTOCOL://localhost:$LOCAL_PORT"
echo "Press Ctrl+C to close the connection"

# Create SSH tunnel through bastion to the target service
ssh -N -L $LOCAL_PORT:$TARGET_HOST:$TARGET_PORT $KEY_OPTION $BASTION_USER@$BASTION_IP