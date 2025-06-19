# Networking Module

# Création du VNet principal
resource "azurerm_virtual_network" "vnet_main" {
  name                = var.vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = ["10.0.0.0/16"]
}

# Sous-réseau public - Uniquement pour l'interface WAN de pfSense
resource "azurerm_subnet" "snet_public" {
  name                 = "snet-public"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet_main.name
  address_prefixes     = ["10.0.0.0/24"]
}

# Sous-réseau LAN - Pour tous les VMs internes (GLPI, Wazuh, etc.)
resource "azurerm_subnet" "snet_lan" {
  name                 = "snet-lan"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet_main.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Sous-réseau bastion - Spécifique pour le bastion host
resource "azurerm_subnet" "snet_bastion" {
  name                 = "snet-bastion"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet_main.name
  address_prefixes     = ["10.0.3.0/24"]
}

# Table de routage LAN - Pour tous les serveurs internes
resource "azurerm_route_table" "rt_lan" {
  name                = "rt-lan"
  location            = var.location
  resource_group_name = var.resource_group_name
}

# Route table for public subnet (WAN interface)
resource "azurerm_route_table" "rt_public" {
  name                = "rt-public"
  location            = var.location
  resource_group_name = var.resource_group_name
}

# Default route for public subnet
resource "azurerm_route" "route_public_default" {
  name                = "route-public-default"
  resource_group_name = var.resource_group_name
  route_table_name    = azurerm_route_table.rt_public.name
  address_prefix      = "0.0.0.0/0"
  next_hop_type       = "Internet"
}

# Table de routage pour bastion - Accès direct à Internet
resource "azurerm_route_table" "rt_bastion" {
  name                = "rt-bastion" 
  location            = var.location
  resource_group_name = var.resource_group_name
}

# Route par défaut pour bastion - Direct internet access
resource "azurerm_route" "route_bastion_internet" {
  name                = "route-bastion-internet"
  resource_group_name = var.resource_group_name
  route_table_name    = azurerm_route_table.rt_bastion.name
  address_prefix      = "0.0.0.0/0"
  next_hop_type       = "Internet"
}

# Route for internal traffic from bastion - Higher priority than internet route
resource "azurerm_route" "route_bastion_internal" {
  name                = "route-bastion-internal"
  resource_group_name = var.resource_group_name
  route_table_name    = azurerm_route_table.rt_bastion.name
  address_prefix      = "10.0.0.0/16"
  next_hop_type       = "VnetLocal"
}

# Route interne pour LAN - Trafic interne directement via VNet
resource "azurerm_route" "route_lan_internal" {
  name                = "route-lan-internal"
  resource_group_name = var.resource_group_name
  route_table_name    = azurerm_route_table.rt_lan.name
  address_prefix      = "10.0.0.0/16"
  next_hop_type       = "VnetLocal"
}

# Route par défaut pour LAN - Trafic externe via pfSense
resource "azurerm_route" "route_lan_default" {
  name                = "route-lan-external"
  resource_group_name = var.resource_group_name
  route_table_name    = azurerm_route_table.rt_lan.name
  address_prefix      = "0.0.0.0/0"
  next_hop_type       = "VirtualAppliance"
  next_hop_in_ip_address = "10.0.1.4" # IP LAN de pfSense
}

# Route for bastion to LAN subnet - Ensure explicit route with high priority
resource "azurerm_route" "route_bastion_to_lan" {
  name                = "route-bastion-to-lan"
  resource_group_name = var.resource_group_name
  route_table_name    = azurerm_route_table.rt_bastion.name
  address_prefix      = "10.0.1.0/24"  # LAN subnet (contains pfSense LAN and all VMs)
  next_hop_type       = "VnetLocal"
}

# Route for bastion to public subnet - Direct communication
resource "azurerm_route" "route_bastion_to_public" {
  name                = "route-bastion-to-public"
  resource_group_name = var.resource_group_name
  route_table_name    = azurerm_route_table.rt_bastion.name
  address_prefix      = "10.0.0.0/24"  # Public subnet
  next_hop_type       = "VnetLocal"
}

# Route for LAN to bastion subnet - Direct communication
resource "azurerm_route" "route_lan_to_bastion" {
  name                = "route-lan-to-bastion"
  resource_group_name = var.resource_group_name
  route_table_name    = azurerm_route_table.rt_lan.name
  address_prefix      = "10.0.3.0/24"  # Bastion subnet
  next_hop_type       = "VnetLocal"
}

# Route internal traffic from pfSense WAN to all subnets via VNet local
resource "azurerm_route" "route_from_wan_to_all" {
  name                = "route-wan-to-all-subnets"
  resource_group_name = var.resource_group_name
  route_table_name    = azurerm_route_table.rt_public.name
  address_prefix      = "10.0.0.0/16"  # All internal subnets
  next_hop_type       = "VnetLocal"
}

# Route for bastion to reach pfSense management (both LAN and WAN)
resource "azurerm_route" "route_bastion_to_pfsense_mgmt" {
  name                = "route-bastion-to-pfsense-mgmt"
  resource_group_name = var.resource_group_name
  route_table_name    = azurerm_route_table.rt_bastion.name
  address_prefix      = "10.0.1.4/32"  # pfSense LAN IP
  next_hop_type       = "VnetLocal"
  # Note: Azure routes are evaluated from most specific to least specific prefix
  # This /32 route will take precedence over broader routes
}

# Association des tables de routage aux sous-réseaux
resource "azurerm_subnet_route_table_association" "rta_lan" {
  subnet_id      = azurerm_subnet.snet_lan.id
  route_table_id = azurerm_route_table.rt_lan.id
}

resource "azurerm_subnet_route_table_association" "rta_bastion" {
  subnet_id      = azurerm_subnet.snet_bastion.id
  route_table_id = azurerm_route_table.rt_bastion.id
}

# NSG pour le sous-réseau public - ALLOW ALL
resource "azurerm_network_security_group" "nsg_public" {
  name                = "nsg-public"
  location            = var.location
  resource_group_name = var.resource_group_name

  # Allow all inbound traffic
  security_rule {
    name                       = "allow-all-inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow all outbound traffic
  security_rule {
    name                       = "allow-all-outbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# NSG pour le sous-réseau bastion - ALLOW ALL
resource "azurerm_network_security_group" "nsg_bastion" {
  name                = "nsg-bastion-subnet"
  location            = var.location
  resource_group_name = var.resource_group_name

  # Allow all inbound traffic
  security_rule {
    name                       = "allow-all-inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow all outbound traffic
  security_rule {
    name                       = "allow-all-outbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# NSG pour le sous-réseau LAN - ALLOW ALL
resource "azurerm_network_security_group" "nsg_lan" {
  name                = "nsg-lan"
  location            = var.location
  resource_group_name = var.resource_group_name

  # Allow all inbound traffic
  security_rule {
    name                       = "allow-all-inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow all outbound traffic
  security_rule {
    name                       = "allow-all-outbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Association des NSG aux sous-réseaux
resource "azurerm_subnet_network_security_group_association" "nsg_association_public" {
  subnet_id                 = azurerm_subnet.snet_public.id
  network_security_group_id = azurerm_network_security_group.nsg_public.id
}

resource "azurerm_subnet_network_security_group_association" "nsg_association_bastion" {
  subnet_id                 = azurerm_subnet.snet_bastion.id
  network_security_group_id = azurerm_network_security_group.nsg_bastion.id
}

resource "azurerm_subnet_network_security_group_association" "nsg_association_lan" {
  subnet_id                 = azurerm_subnet.snet_lan.id
  network_security_group_id = azurerm_network_security_group.nsg_lan.id
}

# Create a public IP for bastion
resource "azurerm_public_ip" "pip_bastion" {
  name                = "pip-bastion"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Associate route table with public subnet
resource "azurerm_subnet_route_table_association" "rta_public" {
  subnet_id      = azurerm_subnet.snet_public.id
  route_table_id = azurerm_route_table.rt_public.id
}