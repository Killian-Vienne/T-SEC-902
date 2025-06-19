# GLPI Web Server Module

# Create a network interface for the GLPI web server
resource "azurerm_network_interface" "nic_glpi_web" {
  name                = "nic-glpi-web"
  location            = var.location
  resource_group_name = var.resource_group_name
  # Traffic routing will be enforced through NSG rules and OS-level configuration
  ip_forwarding_enabled = true
  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.lan_subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.1.20"
  }
}

# Create a network security group for the GLPI web server
resource "azurerm_network_security_group" "nsg_glpi_web" {
  name                = "nsg-glpi-web"
  location            = var.location
  resource_group_name = var.resource_group_name

  # Allow HTTP/HTTPS from pfSense
  security_rule {
    name                       = "allow-http-https-from-pfsense"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"]
    source_address_prefix      = "10.0.1.4" # pfSense LAN interface
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

  # Force all outbound traffic through pfSense
  security_rule {
    name                       = "route-all-outbound-through-pfsense"
    priority                   = 200
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "10.0.1.4" # pfSense LAN interface
  }
}

# Associate the NSG with the GLPI web server NIC
resource "azurerm_network_interface_security_group_association" "nsg_association_glpi_web" {
  network_interface_id      = azurerm_network_interface.nic_glpi_web.id
  network_security_group_id = azurerm_network_security_group.nsg_glpi_web.id
}

# Create the GLPI web server VM
resource "azurerm_linux_virtual_machine" "vm_glpi_web" {
  name                = "vm-glpi-web"
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
    azurerm_network_interface.nic_glpi_web.id,
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

  custom_data = base64encode(<<-EOF
    #!/bin/bash

    # Configure netplan for static IP with proper gateway (pfSense)
    cat > /etc/netplan/01-netcfg.yaml << 'NETPLAN'
    network:
      version: 2
      ethernets:
        eth0:
          dhcp4: no
          addresses: [10.0.1.20/24]
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

    # Update package list
    apt-get update

    # Install required packages
    apt-get install -y nginx php php-fpm php-cli php-mysql php-curl php-gd php-intl php-pear php-imagick php-imap php-memcache php-pspell php-tidy php-xmlrpc php-xsl php-mbstring php-ldap php-apcu php-json php-xml unzip curl git openssl

    # Create SSL directory and generate self-signed certificate
    mkdir -p /etc/nginx/ssl
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
      -keyout /etc/nginx/ssl/nginx.key \
      -out /etc/nginx/ssl/nginx.crt \
      -subj "/C=US/ST=State/L=City/O=Organization/CN=glpi.local"

    chmod 600 /etc/nginx/ssl/nginx.key

    # Configure Nginx with HTTPS support
    cat > /etc/nginx/sites-available/glpi << NGINXEOF
    # HTTP - Redirect all to HTTPS
    server {
        listen 80;
        server_name _;

        return 301 https://\$host\$request_uri;
    }

    # HTTPS - Main server config
    server {
        listen 443 ssl;
        server_name _;

        # SSL configuration
        ssl_certificate /etc/nginx/ssl/nginx.crt;
        ssl_certificate_key /etc/nginx/ssl/nginx.key;
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_prefer_server_ciphers on;
        ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;

        root /var/www/html/glpi;
        index index.php index.html index.htm;

        location / {
            try_files \$uri \$uri/ /index.php?\$args;
        }

        location ~ ^/public/(.+)\$ {
            try_files \$uri /public/index.php?\$args;
        }

        location ~ \.php\$ {
          fastcgi_pass unix:/var/run/php/php7.4-fpm.sock;

          include snippets/fastcgi-php.conf;
          fastcgi_split_path_info ^(.+\.php)(/.*)$;
          include fastcgi_params;
          fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        }

        # authorization on install during initial setup
        location ~ /install/ {
            allow all;
        }
    }
    NGINXEOF

    # Enable the GLPI site and disable default
    ln -s /etc/nginx/sites-available/glpi /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default

    # Download and install GLPI
    cd /tmp
    wget https://github.com/glpi-project/glpi/releases/download/10.0.18/glpi-10.0.18.tgz
    tar xzf glpi-10.0.18.tgz -C /var/www/html/
    chown -R www-data:www-data /var/www/html/glpi

    # Restart services
    systemctl stop apache2.service || true
    systemctl restart nginx
    systemctl restart php7.4-fpm

    # Install agent wazuh
    apt install -y curl apt-transport-https software-properties-common gpg lsb-release
    curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --dearmor -o /usr/share/keyrings/wazuh.gpg
    echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | tee /etc/apt/sources.list.d/wazuh.list
    apt-get update
    apt-get install -y wazuh-agent
    # Configure Wazuh agent to connect to the manager
    sed -i 's/<address>MANAGER_IP<\/address>/<address>10.0.1.30<\/address>/' /var/ossec/etc/ossec.conf
    systemctl daemon-reload
    systemctl enable wazuh-agent
    systemctl start wazuh-agent
EOF
  )

  tags = {
    role = "glpi-web"
  }
}
