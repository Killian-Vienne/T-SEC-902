# Wazuh Security Monitoring Module

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

  # Allow SSH from bastion host only
  security_rule {
    name                       = "allow-ssh-from-bastion"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
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
  size                = "Standard_B1s"  # Using allowed VM size
  admin_username      = var.admin_username
  # TBD Connection to Wazuh from bastion as problem
  disable_password_authentication = true

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
    disk_size_gb         = 100  # Wazuh needs more storage for logs
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }

  tags = {
    role = "wazuh"
  }
}