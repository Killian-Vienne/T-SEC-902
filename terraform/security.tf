# Groupe de sécurité réseau pour DMZ/Public
resource "azurerm_network_security_group" "nsg_dmz" {
  name                = "nsg-dmz"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
}

# Règles NSG pour DMZ
resource "azurerm_network_security_rule" "dmz_https" {
  name                        = "AllowHTTPS"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = data.azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg_dmz.name
}

resource "azurerm_network_security_rule" "dmz_ssh" {
  name                        = "AllowSSH"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = data.azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg_dmz.name
}

# Association NSG à sous-réseau DMZ
resource "azurerm_subnet_network_security_group_association" "dmz_nsg_association" {
  subnet_id                 = azurerm_subnet.dmz.id
  network_security_group_id = azurerm_network_security_group.nsg_dmz.id
}

# Groupe de sécurité réseau pour Sécurité
resource "azurerm_network_security_group" "nsg_securite" {
  name                = "nsg-securite"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
}

# Règles NSG pour Sécurité
resource "azurerm_network_security_rule" "securite_ssh" {
  name                        = "AllowSSH"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = azurerm_subnet.dmz.address_prefixes[0]
  destination_address_prefix  = "*"
  resource_group_name         = data.azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg_securite.name
}

# Association NSG à sous-réseau Sécurité
resource "azurerm_subnet_network_security_group_association" "securite_nsg_association" {
  subnet_id                 = azurerm_subnet.securite.id
  network_security_group_id = azurerm_network_security_group.nsg_securite.id
}

# Groupe de sécurité réseau pour Application
resource "azurerm_network_security_group" "nsg_application" {
  name                = "nsg-application"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
}

# Règles NSG pour Application
resource "azurerm_network_security_rule" "application_ssh" {
  name                        = "AllowSSH"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = azurerm_subnet.dmz.address_prefixes[0]
  destination_address_prefix  = "*"
  resource_group_name         = data.azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg_application.name
}

resource "azurerm_network_security_rule" "application_https" {
  name                        = "AllowHTTPS"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = azurerm_subnet.dmz.address_prefixes[0]
  destination_address_prefix  = "*"
  resource_group_name         = data.azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg_application.name
}

# Association NSG à sous-réseau Application
resource "azurerm_subnet_network_security_group_association" "application_nsg_association" {
  subnet_id                 = azurerm_subnet.application.id
  network_security_group_id = azurerm_network_security_group.nsg_application.id
}

# Groupe de sécurité réseau pour Base de Données
resource "azurerm_network_security_group" "nsg_database" {
  name                = "nsg-database"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
}

# Règles NSG pour Base de Données
resource "azurerm_network_security_rule" "database_ssh" {
  name                        = "AllowSSH"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = azurerm_subnet.dmz.address_prefixes[0]
  destination_address_prefix  = "*"
  resource_group_name         = data.azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg_database.name
}

resource "azurerm_network_security_rule" "database_sql" {
  name                        = "AllowSQL"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3306"
  source_address_prefix       = azurerm_subnet.application.address_prefixes[0]
  destination_address_prefix  = "*"
  resource_group_name         = data.azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg_database.name
}

# Association NSG à sous-réseau Base de Données
resource "azurerm_subnet_network_security_group_association" "database_nsg_association" {
  subnet_id                 = azurerm_subnet.database.id
  network_security_group_id = azurerm_network_security_group.nsg_database.id
}

# Groupe de sécurité réseau pour WAN (interface externe pfSense)
resource "azurerm_network_security_group" "nsg_wan" {
  name                = "nsg-wan"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
}

# Règles NSG pour WAN - Autoriser HTTPS pour l'interface web pfSense
resource "azurerm_network_security_rule" "wan_https" {
  name                        = "AllowHTTPS"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"  # Pour un environnement de production, limitez à votre IP
  destination_address_prefix  = "*"
  resource_group_name         = data.azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg_wan.name
}

# Règles NSG pour WAN - Autoriser SSH pour l'administration
resource "azurerm_network_security_rule" "wan_ssh" {
  name                        = "AllowSSH"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"  # Pour un environnement de production, limitez à votre IP
  destination_address_prefix  = "*"
  resource_group_name         = data.azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg_wan.name
}

# Association NSG à sous-réseau WAN
resource "azurerm_subnet_network_security_group_association" "wan_nsg_association" {
  subnet_id                 = azurerm_subnet.wan.id
  network_security_group_id = azurerm_network_security_group.nsg_wan.id
}