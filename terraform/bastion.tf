// IP Publique pour le bastion
resource "azurerm_public_ip" "bastion_pip" {
  name                = "pip-bastion"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                = "Standard"
}

// Interface réseau pour le bastion
resource "azurerm_network_interface" "bastion_nic" {
  name                = "nic-bastion"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.dmz.id
    private_ip_address_allocation = "Static"
    private_ip_address           = "10.0.1.5"
    public_ip_address_id          = azurerm_public_ip.bastion_pip.id
  }
}

// VM Linux pour le bastion
resource "azurerm_linux_virtual_machine" "bastion" {
  name                = "vm-bastion"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  size                = "Standard_B1s"  // SKU minimal
  admin_username      = "adminuser"

  network_interface_ids = [
    azurerm_network_interface.bastion_nic.id
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/azure-ssh.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }

  custom_data = base64encode(<<-EOF
    #!/bin/bash
    # Mise à jour du système
    apt-get update
    apt-get upgrade -y

    # Installation des outils nécessaires
    apt-get install -y \
      openssh-server \
      iptables-persistent \
      fail2ban

    # Configuration SSH
    sed -i 's/#AllowTcpForwarding yes/AllowTcpForwarding yes/' /etc/ssh/sshd_config
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
    sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
    systemctl restart sshd

    # Configuration basique du pare-feu
    iptables -A INPUT -p tcp --dport 22 -j ACCEPT
    iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    iptables -A INPUT -j DROP
    netfilter-persistent save
    EOF
  )

  tags = {
    role = "bastion"
  }
}

// NSG pour le bastion
resource "azurerm_network_security_group" "bastion_nsg" {
  name                = "nsg-bastion"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  security_rule {
    name                       = "AllowSSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range         = "*"
    destination_port_range     = "22"
    source_address_prefix      = "163.5.3.15/32"
    destination_address_prefix = "*"
  }
}

// Association du NSG à l'interface réseau
resource "azurerm_network_interface_security_group_association" "bastion_nsg_association" {
  network_interface_id      = azurerm_network_interface.bastion_nic.id
  network_security_group_id = azurerm_network_security_group.bastion_nsg.id
}