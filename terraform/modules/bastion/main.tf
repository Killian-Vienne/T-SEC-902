# Bastion Module

locals {
  grub_password_hash = "grub.pbkdf2.sha512.10000.2ED356669204F93CF1A7E95020D8C84A24998A3C36B2D1D3D2DEA01EF397B2D04B5EC56BC25941D13340F7021DB12CE2B8343635B9CB57748D773FE87A0E909B.8F6033CF2691C8E1AE45B34F13E351A67E9C021FB0A29DED470C1E81C00D028AB0BC3D581F41DEBE6D72EA7900A7F075A94A5777B08E007AF84C1EA739F9D1A3"
}

# Create a network interface for the bastion
resource "azurerm_network_interface" "nic_bastion" {
  name                = "nic-bastion"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.bastion_subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.3.10"
    public_ip_address_id          = var.public_ip_id
  }
}

# Create the bastion VM
resource "azurerm_linux_virtual_machine" "vm_bastion" {
  name                = "vm-bastion"
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = "Standard_B1s"
  admin_username      = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.nic_bastion.id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_public_key_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  # Custom data to configure the bastion with basic SSH forwarding capabilities
  custom_data = base64encode(<<-EOF
    #!/bin/bash

    # Install required packages
    apt-get update
    apt-get install -y openssh-server

    # Enable SSH forwarding for proxying
    echo "AllowTcpForwarding yes" >> /etc/ssh/sshd_config
    echo "GatewayPorts yes" >> /etc/ssh/sshd_config

    # Configuration SSH avec port personnalisé
    echo "Configuration SSH avec port personnalisé (2222)..."
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
    sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
    sed -i 's/#Port 22/Port 2222/' /etc/ssh/sshd_config
    systemctl restart sshd

    # Create SSH config for easy access to internal servers
    mkdir -p /home/${var.admin_username}/.ssh
    cat > /home/${var.admin_username}/.ssh/config << 'SSHCONFIG'
    # GLPI Web Server
    Host glpi-web
      HostName 10.0.1.20
      User ${var.admin_username}
      Port 2222
      IdentityFile ~/.ssh/azure-ssh

    # GLPI Database Server
    Host glpi-db
      HostName 10.0.1.10
      User ${var.admin_username}
      Port 2222
      IdentityFile ~/.ssh/azure-ssh

    # Wazuh Server
    Host wazuh
      HostName 10.0.1.30
      User ${var.admin_username}
      Port 2222
      IdentityFile ~/.ssh/azure-ssh

    # pfSense
    Host pfsense
      HostName 10.0.1.4
      User ${var.admin_username}
      IdentityFile ~/.ssh/azure-ssh
    SSHCONFIG

    # Create minimal help file
    cat > /home/${var.admin_username}/BASTION-USAGE.txt << 'USAGE'
    Bastion Host Quick Reference
    ===========================

    This host allows you to access internal resources securely.

    - SSH to internal servers (using custom port 2222):
      ssh glpi-web
      ssh glpi-db
      ssh wazuh
      ssh pfsense

    - For web interfaces:
      Use the client-side scripts provided separately to
      establish secure SSH tunnels through this bastion.
    USAGE

    # Set permissions
    chown -R ${var.admin_username}:${var.admin_username} /home/${var.admin_username}/.ssh
    chown ${var.admin_username}:${var.admin_username} /home/${var.admin_username}/BASTION-USAGE.txt
    chmod 600 /home/${var.admin_username}/.ssh/config

    # Restart SSH service
    systemctl restart sshd

    # Désactivation de l'IPv6 via sysctl
    echo "Désactivation de l'IPv6 via sysctl..."
    cat > /etc/sysctl.d/99-disable-ipv6.conf << 'SysctlEOF'
      net.ipv6.conf.all.disable_ipv6 = 1
      net.ipv6.conf.default.disable_ipv6 = 1
      net.ipv6.conf.lo.disable_ipv6 = 1
    SysctlEOF

    # Appliquer immédiatement les paramètres
    sysctl -p /etc/sysctl.d/99-disable-ipv6.conf
    echo "IPv6 désactivé (sysctl)"

    # Set superuser and password
    echo "GRUB superuser configuration..."
    echo -e "set superuser=\"admin\"\npassword_pbkdf2 admin ${local.grub_password_hash}" > /etc/grub.d/01_password

    # Make the file executable
    chmod 755 /etc/grub.d/01_password

    # Update GRUB configuration
    echo "Updating GRUB configuration..."
    update-grub

    # # Installation de ClamAV
    # echo "Installation de ClamAV"
    # sudo apt-get install -y clamav clamav-daemon

    # cannot update the virus definitions due to RAM not enough
    # # Mise à jour de la base de définitions de virus
    # echo "Mise à jour de la base de définitions de virus"
    # sudo systemctl stop clamav-freshclam
    # sudo freshclam
    # sudo systemctl start clamav-freshclam

    # Activation du service ClamAV
    # echo "Activation du service ClamAV"
    # sudo systemctl enable clamav-freshclam
    # sudo systemctl enable clamav-daemon

    # Configuration sécuritaire de sudo - Exiger un mot de passe
    echo "Configuring secure sudo access..."

    # Supprimer la règle NOPASSWD d'Azure
    rm -f /etc/sudoers.d/90-cloud-init-users

    # Créer une règle sudo sécurisée pour l'administrateur
    echo "${var.admin_username} ALL=(ALL:ALL) ALL" > /etc/sudoers.d/01-admin-secure
    chmod 440 /etc/sudoers.d/01-admin-secure

    # Vérifier la configuration sudo
    visudo -c
  EOF
  )

  tags = {
    role = "bastion"
  }
}