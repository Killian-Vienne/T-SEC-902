# Génération aléatoire du mot de passe
resource "random_password" "password" {
  length           = 12
  special          = true
  upper            = true
  lower            = true
  numeric           = true
  override_special = "!@#%^&*()-_=+[]{}<>?"
}

# Resource Group
data "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
}

# VNet 1
resource "azurerm_virtual_network" "vnet-internal-001" {
  name                = "vnet-internal-001"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "snet-internal-001" {
  name                 = "snet-internal-001"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet-internal-001.name
  address_prefixes     = ["10.0.1.0/24"]
}

# VNet 2
resource "azurerm_virtual_network" "vnet-connectivity-001" {
  name                = "vnet-connectivity-001"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  address_space       = ["10.1.0.0/16"]
}

resource "azurerm_subnet" "snet-connectivity-001" {
  name                 = "snet-connectivity-001"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet-connectivity-001.name
  address_prefixes     = ["10.1.1.0/24"]
}

# VNet 3
resource "azurerm_virtual_network" "vnet-internal-002" {
  name                = "vnet-internal-002"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  address_space       = ["10.2.0.0/16"]
}

resource "azurerm_subnet" "snet-internal-002" {
  name                 = "snet-internal-002"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet-internal-002.name
  address_prefixes     = ["10.2.1.0/24"]
}

# Peering entre les VNets
resource "azurerm_virtual_network_peering" "vnet-internal-001_to_vnet-connectivity-001" {
  name                      = "vnet-internal-001-to-vnet-connectivity-001"
  resource_group_name       = data.azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.vnet-internal-001.name
  remote_virtual_network_id = azurerm_virtual_network.vnet-connectivity-001.id
  allow_virtual_network_access = true
}


resource "azurerm_virtual_network_peering" "vnet-internal-002_to_vnet-internal-001" {
  name                      = "vnet-internal-002-to-vnet-internal-001"
  resource_group_name       = data.azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.vnet-internal-002.name
  remote_virtual_network_id = azurerm_virtual_network.vnet-internal-001.id
  allow_virtual_network_access = true
}

# Table de routage
resource "azurerm_route_table" "rt-networking-001" {
  name                = "rt-networking-001"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
}

# Associer la table de routage aux sous-réseaux
resource "azurerm_subnet_route_table_association" "rta-internal-snet-internal-001" {
  subnet_id      = azurerm_subnet.snet-internal-001.id
  route_table_id = azurerm_route_table.rt-networking-001.id
}

resource "azurerm_subnet_route_table_association" "rta-connectivity-snet-connectivity-001" {
  subnet_id      = azurerm_subnet.snet-connectivity-001.id
  route_table_id = azurerm_route_table.rt-networking-001.id
}

resource "azurerm_subnet_route_table_association" "rta-internal-subnet3" {
  subnet_id      = azurerm_subnet.snet-internal-002.id
  route_table_id = azurerm_route_table.rt-networking-001.id
}

#Route par défaut pour la communication entre VNets
resource "azurerm_route" "default_route" {
  name                   = "route-default"
  resource_group_name    = data.azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.rt-networking-001.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualNetworkGateway"
}

# Network Interface for each VM site-web-001
resource "azurerm_network_interface" "nic-site-web-001" {
  name                = "nic-site-web-001"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.snet-internal-001.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Virtual Machines
resource "azurerm_linux_virtual_machine" "vm-site-web-001" {
  name                = "vm-site-web-001"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  ## 8$ par mois
  size                = "Standard_B1s"
  admin_username      = "adminuser"
  admin_password      = random_password.password.result
  disable_password_authentication = false
  network_interface_ids = [azurerm_network_interface.nic-site-web-001.id]
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
}

# Network Interface for each VM ftp-001
resource "azurerm_network_interface" "nic-ftp-001" {
  name                = "nic-ftp-001-ftp-001"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.snet-internal-002.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "vm-ftp-001" {
  name                = "vm-ftp-001"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  ## 8$ par mois
  size                = "Standard_B1s"
  admin_username      = "adminuser"
  admin_password      = random_password.password.result
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.nic-ftp-001.id
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
}