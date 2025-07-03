# Networking Security Module - Allow All Traffic (pfSense handles security)

# NSG for pfSense LAN interface - Allow all traffic
resource "azurerm_network_security_group" "nsg_pfsense_lan" {
  name                = "nsg-pfsense-lan"
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

# NSG for pfSense WAN interface - Allow all traffic
resource "azurerm_network_security_group" "nsg_pfsense_wan" {
  name                = "nsg-pfsense-wan"
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

# NSG Associations with pfSense Network Interfaces
resource "azurerm_network_interface_security_group_association" "nsg_pfsense_lan_association" {
  network_interface_id      = var.pfsense_lan_nic_id
  network_security_group_id = azurerm_network_security_group.nsg_pfsense_lan.id
}

resource "azurerm_network_interface_security_group_association" "nsg_pfsense_wan_association" {
  network_interface_id      = var.pfsense_wan_nic_id
  network_security_group_id = azurerm_network_security_group.nsg_pfsense_wan.id
}