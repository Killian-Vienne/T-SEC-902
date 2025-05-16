# Réseau virtuel principal
resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  address_space       = var.vnet_address_space
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
}

# Sous-réseau DMZ (Public)
resource "azurerm_subnet" "dmz" {
  name                 = var.subnet_dmz.name
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.subnet_dmz.address_prefixes
}

# Sous-réseau Sécurité
resource "azurerm_subnet" "securite" {
  name                 = var.subnet_securite.name
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.subnet_securite.address_prefixes
}

# Sous-réseau Application
resource "azurerm_subnet" "application" {
  name                 = var.subnet_application.name
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.subnet_application.address_prefixes
}

# Sous-réseau Base de Données
resource "azurerm_subnet" "database" {
  name                 = var.subnet_database.name
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.subnet_database.address_prefixes
}

# Sous-réseau WAN (pour l'accès Internet de pfSense)
resource "azurerm_subnet" "wan" {
  name                 = var.subnet_wan.name
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.subnet_wan.address_prefixes
}