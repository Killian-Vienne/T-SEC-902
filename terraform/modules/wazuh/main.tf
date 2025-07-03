# Wazuh Security Monitoring Module

# Local variable for GRUB password hash
locals {
  grub_password_hash = "grub.pbkdf2.sha512.10000.2ED356669204F93CF1A7E95020D8C84A24998A3C36B2D1D3D2DEA01EF397B2D04B5EC56BC25941D13340F7021DB12CE2B8343635B9CB57748D773FE87A0E909B.8F6033CF2691C8E1AE45B34F13E351A67E9C021FB0A29DED470C1E81C00D028AB0BC3D581F41DEBE6D72EA7900A7F075A94A5777B08E007AF84C1EA739F9D1A3"
}

# Create a network interface for the Wazuh server
resource "azurerm_network_interface" "nic_wazuh" {
  name                = "nic-wazuh"
  location            = var.location
  resource_group_name = var.resource_group_name
  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.lan_subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.1.30"
  }
}

# Create a network security group for the Wazuh server
resource "azurerm_network_security_group" "nsg_wazuh" {
  name                = "nsg-wazuh"
  location            = var.location
  resource_group_name = var.resource_group_name

  # Allow SSH from bastion host only (port 2222)
  security_rule {
    name                       = "allow-ssh-from-bastion"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "2222"
    source_address_prefix      = var.bastion_private_ip
    destination_address_prefix = "*"
  }

  # Allow Wazuh agent connections from internal subnets
  security_rule {
    name                       = "allow-wazuh-agent-connections"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["1514", "1515", "514"]
    source_address_prefixes    = ["10.0.0.0/16"]
    destination_address_prefix = "*"
  }

  # Allow Wazuh API connections from internal subnets
  security_rule {
    name                       = "allow-wazuh-api-connections"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "55000"
    source_address_prefixes    = ["10.0.0.0/16"]
    destination_address_prefix = "*"
  }
}

# Associate the NSG with the Wazuh server NIC
resource "azurerm_network_interface_security_group_association" "nsg_association_wazuh" {
  network_interface_id      = azurerm_network_interface.nic_wazuh.id
  network_security_group_id = azurerm_network_security_group.nsg_wazuh.id
}

# Create the Wazuh server VM
resource "azurerm_linux_virtual_machine" "vm_wazuh" {
  name                = "vm-wazuh"
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = "Standard_B1s"
  admin_username      = var.admin_username
  admin_password      = var.admin_password

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_public_key_path)
  }

  network_interface_ids = [
    azurerm_network_interface.nic_wazuh.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 100
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  custom_data = base64encode(<<-EOF
    #!/bin/bash

    # Configure netplan for static IP with proper gateway (pfSense)
    cat > /etc/netplan/01-netcfg.yaml << 'NETPLAN'
    network:
      version: 2
      ethernets:
        eth0:
          dhcp4: no
          addresses: [10.0.1.30/24]
          gateway4: 10.0.1.4
          nameservers:
            addresses: [10.0.1.4, 8.8.8.8]
          routes:
            - to: 168.63.129.16/32
              via: 10.0.1.4
            - to: 169.254.169.254/32
              via: 10.0.1.4
    NETPLAN

    # Apply netplan configuration
    netplan apply

    # Wait for network connectivity
    while ! ping -c 1 -W 1 8.8.8.8
    do
      echo "Waiting for internet access..."
      sleep 5
    done

    # Force traffic through pfSense - Remove automatic kernel route and add via pfSense
    echo "Configuring routes to force traffic through pfSense..."

    # Remove the automatic kernel route for local subnet
    ip route del 10.0.1.0/24 dev eth0 proto kernel scope link || true

    # Add specific route for LAN subnet via pfSense
    ip route add 10.0.1.0/24 via 10.0.1.4 dev eth0

    # Make the route change permanent by creating a script
    cat > /etc/systemd/system/force-pfsense-routing.service << 'SERVICE'
    [Unit]
    Description=Force traffic through pfSense
    After=network.target
    Wants=network.target

    [Service]
    Type=oneshot
    ExecStart=/bin/bash -c 'ip route del 10.0.1.0/24 dev eth0 proto kernel scope link || true; ip route add 10.0.1.0/24 via 10.0.1.4 dev eth0 || true'
    RemainAfterExit=yes

    [Install]
    WantedBy=multi-user.target
    SERVICE

    # Enable the service
    systemctl enable force-pfsense-routing.service
    systemctl start force-pfsense-routing.service

    apt-get update
    apt-get install -y sl

    # Configuration SSH avec port personnalisé
    echo "Configuration SSH avec port personnalisé (2222)..."
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
    sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
    sed -i 's/#Port 22/Port 2222/' /etc/ssh/sshd_config
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

    # Configuration du mot de passe utilisateur avec celui généré par Terraform
    echo "Setting up user password with Terraform-generated password..."
    echo "${var.admin_username}:${var.admin_password}" | chpasswd

    # Forcer l'expiration du mot de passe pour s'assurer qu'il est bien configuré
    passwd -e ${var.admin_username} 2>/dev/null || true

    # Remettre le mot de passe sans expiration
    echo "${var.admin_username}:${var.admin_password}" | chpasswd

    # Configuration sécuritaire de sudo - Exiger un mot de passe à chaque utilisation
    echo "Configuring secure sudo access - password required for every sudo command..."

    # Supprimer toutes les règles NOPASSWD d'Azure et cloud-init
    rm -f /etc/sudoers.d/90-cloud-init-users
    rm -f /etc/sudoers.d/waagent
    rm -f /etc/sudoers.d/azure

    # Supprimer toute ligne NOPASSWD du fichier sudoers principal
    sed -i '/NOPASSWD/d' /etc/sudoers

    # Créer une règle sudo sécurisée pour l'administrateur
    cat > /etc/sudoers.d/01-admin-secure << SUDOERS
    # Configuration sécurisée sudo - Mot de passe requis à chaque utilisation
    ${var.admin_username} ALL=(ALL:ALL) ALL

    # Directives de sécurité sudo
    Defaults timestamp_timeout=0
    Defaults passwd_timeout=1
    Defaults passwd_tries=3
    Defaults logfile=/var/log/sudo.log
    Defaults log_input,log_output
    Defaults requiretty
    Defaults env_reset
    Defaults secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
    SUDOERS

    chmod 440 /etc/sudoers.d/01-admin-secure

    # Vérifier la configuration sudo
    if ! visudo -c; then
        echo "ERREUR: Configuration sudo invalide!"
        exit 1
    fi

    echo "Configuration sudo sécurisée appliquée avec succès."

    echo "Configuration terminée. Redémarrage recommandé après le déploiement."
  EOF
  )
  tags = {
    role = "wazuh"
  }
}