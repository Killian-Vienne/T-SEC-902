# Bastion

## Introduction

The bastion is an intermediate machine, placed in a secure subnet, that serves as a single access point to administer other machines in the infrastructure.
It helps strengthen security by avoiding direct exposure of internal VMs (GLPI, Wazuh, etc.) to the Internet.

## Role in the infrastructure

- Secure entry point: Only the bastion's public IP is exposed on the Internet.
- Access to internal VMs: You first connect to the bastion, then bounce to other VMs (which only accept SSH connections from the bastion).
- Network filtering: Security rules (NSG, pfSense) only allow SSH to internal VMs from the bastion.

## Connecting to the bastion

1. Direct SSH connection
To connect directly to the bastion from your local machine:

```sh
ssh -i ~/.ssh/azure-ssh adminuser@<BASTION_PUBLIC_IP>
```
2. Using the connect.sh script
This script (if present in your project) allows you to simplify SSH connection to the bastion.
Usage example:

```sh
./connect.sh
```
or

```sh
./connect.sh ~/.ssh/azure-ssh
```

The script uses the specified SSH key (or the default one) to open a session on the bastion.

3. Using the ssh-connect.sh script

This script allows you to easily connect to any internal VM via the bastion, or execute a remote command.

- Connect to pfSense via the bastion:
```sh
./ssh-connect.sh pfsense ~/.ssh/azure-ssh
```

- Connect to Wazuh via the bastion:
```sh
./ssh-connect.sh wazuh ~/.ssh/azure-ssh
```

- Connect to GLPI web via the bastion:
```sh
./ssh-connect.sh glpi-web ~/.ssh/azure-ssh
```

- Execute a command on a VM via the bastion:
```sh
./ssh-connect.sh glpi-web ~/.ssh/azure-ssh "cat /var/log/nginx/error.log"
```

```text
[Your PC] --(SSH)--> [Bastion] --(Internal SSH)--> [Internal VM (GLPI, Wazuh, etc.)]
```