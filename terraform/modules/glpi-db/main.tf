# GLPI Database Module

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

  # Allow SSH from bastion host only
  security_rule {
    name                       = "allow-ssh-from-bastion"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
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
  disable_password_authentication = true

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
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
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

    while ! ping -c 1 -W 1 8.8.8.8
    do
      echo "Waiting for internet access..."
      sleep 5
    done

    apt-get update
    apt-get install -y mysql-server
      # Configure MySQL to listen only on the private IP
    sed -i "s/bind-address.*/bind-address = 10.0.1.10/" /etc/mysql/mysql.conf.d/mysqld.cnf

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
  EOF
  )

  tags = {
    role = "glpi-db"
  }
}