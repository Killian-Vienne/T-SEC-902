# GLPI Database Module

locals {
  grub_password_hash = "grub.pbkdf2.sha512.10000.2ED356669204F93CF1A7E95020D8C84A24998A3C36B2D1D3D2DEA01EF397B2D04B5EC56BC25941D13340F7021DB12CE2B8343635B9CB57748D773FE87A0E909B.8F6033CF2691C8E1AE45B34F13E351A67E9C021FB0A29DED470C1E81C00D028AB0BC3D581F41DEBE6D72EA7900A7F075A94A5777B08E007AF84C1EA739F9D1A3"
}

# Create a network interface for the GLPI database server
resource "azurerm_network_interface" "nic_glpi_db" {
  name                = "nic-glpi-db"
  location            = var.location
  resource_group_name = var.resource_group_name
  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.lan_subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.1.10"
  }
}

# Create a network security group for the GLPI database server
resource "azurerm_network_security_group" "nsg_glpi_db" {
  name                = "nsg-glpi-db"
  location            = var.location
  resource_group_name = var.resource_group_name

  # Allow MySQL from GLPI web server only
  security_rule {
    name                       = "allow-mysql-from-glpi-web"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3306"
    source_address_prefix      = var.glpi_web_private_ip
    destination_address_prefix = "*"
  }

  # Allow SSH from bastion host only (port 2222)
  security_rule {
    name                       = "allow-ssh-from-bastion"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "2222"
    source_address_prefix      = var.bastion_private_ip
    destination_address_prefix = "*"
  }
}

# Associate the NSG with the GLPI database server NIC
resource "azurerm_network_interface_security_group_association" "nsg_association_glpi_db" {
  network_interface_id      = azurerm_network_interface.nic_glpi_db.id
  network_security_group_id = azurerm_network_security_group.nsg_glpi_db.id
}

# Create the GLPI database server VM
resource "azurerm_linux_virtual_machine" "vm_glpi_db" {
  name                = "vm-glpi-db"
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = "Standard_B1s"
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  # disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_public_key_path)
  }

  network_interface_ids = [
    azurerm_network_interface.nic_glpi_db.id,
  ]

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

  # Custom data to install and configure MySQL
  custom_data = base64encode(<<-EOF
    #!/bin/bash
    # Configure netplan for static IP with proper gateway (pfSense)
    cat > /etc/netplan/01-netcfg.yaml << 'NETPLAN'
    network:
      version: 2
      ethernets:
        eth0:
          dhcp4: no
          addresses: [10.0.1.10/24]
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

    # Wait for network connectivity
    while ! ping -c 1 -W 1 8.8.8.8
    do
      echo "Waiting for internet access..."
      sleep 5
    done

    apt-get update
    apt-get install -y mysql-server
      # Configure MySQL to listen only on the private IP
    sed -i "s/bind-address.*/bind-address = 10.0.1.10/" /etc/mysql/mysql.conf.d/mysqld.cnf

    # Configuration SSH avec port personnalisé
    echo "Configuration SSH avec port personnalisé (2222)..."
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
    sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
    sed -i 's/#Port 22/Port 2222/' /etc/ssh/sshd_config
    systemctl restart sshd

    # Secure MySQL installation
    mysql -u root -p"${var.admin_password}" -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${var.admin_password}';"
    mysql -u root -p"${var.admin_password}" -e "DELETE FROM mysql.user WHERE User='';"
    mysql -u root -p"${var.admin_password}" -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
    mysql -u root -p"${var.admin_password}" -e "DROP DATABASE IF EXISTS test;"
    mysql -u root -p"${var.admin_password}" -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
    mysql -u root -p"${var.admin_password}" -e "FLUSH PRIVILEGES;"

    # Create GLPI user with database creation privileges
    mysql -u root -p"${var.admin_password}" -e "CREATE USER 'glpi'@'10.0.1.20' IDENTIFIED BY '${var.admin_password}';"
    mysql -u root -p"${var.admin_password}" -e "GRANT ALL PRIVILEGES ON glpi.* TO 'glpi'@'10.0.1.20';"
    mysql -u root -p"${var.admin_password}" -e "GRANT ALL PRIVILEGES ON mysql.* TO 'glpi'@'10.0.1.20';"
    mysql -u root -p"${var.admin_password}" -e "GRANT CREATE ON *.* TO 'glpi'@'10.0.1.20';"
    mysql -u root -p"${var.admin_password}" -e "FLUSH PRIVILEGES;"

    # Restart MySQL service
    systemctl restart mysql

    # Install agent wazuh
    apt install -y curl apt-transport-https software-properties-common gpg lsb-release
    apt install -y curl apt-transport-https software-properties-common gpg lsb-release
    curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --dearmor -o /usr/share/keyrings/wazuh.gpg
    echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | tee /etc/apt/sources.list.d/wazuh.list
    apt-get update
    apt-get install -y wazuh-agent
    # Configure Wazuh agent to connect to the manager
    sed -i 's/<address>MANAGER_IP<\/address>/<address>10.0.1.20<\/address>/' /var/ossec/etc/ossec.conf
    systemctl daemon-reload
    systemctl enable wazuh-agent
    systemctl start wazuh-agent

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

  EOF
  )

  tags = {
    role = "glpi-db"
  }
}