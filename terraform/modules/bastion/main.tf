# Bastion Module

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
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
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

    # Create SSH config for easy access to internal servers
    mkdir -p /home/${var.admin_username}/.ssh
    cat > /home/${var.admin_username}/.ssh/config << 'SSHCONFIG'
    # GLPI Web Server
    Host glpi-web
      HostName 10.0.1.20
      User ${var.admin_username}
      IdentityFile ~/.ssh/azure-ssh

    # GLPI Database Server
    Host glpi-db
      HostName 10.0.1.10
      User ${var.admin_username}
      IdentityFile ~/.ssh/azure-ssh

    # Wazuh Server
    Host wazuh
      HostName 10.0.1.30
      User ${var.admin_username}
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

    - SSH to internal servers:
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
  EOF
  )

  tags = {
    role = "bastion"
  }
}