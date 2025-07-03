# pfSense Module

# Create a public IP for pfSense
resource "azurerm_public_ip" "pip_pfsense" {
  name                = "pip-pfsense"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Interface réseau WAN pour pfSense (connectée au sous-réseau public)
resource "azurerm_network_interface" "nic_pfsense_wan" {
  name                = "nic-pfsense-wan"
  location            = var.location
  resource_group_name = var.resource_group_name
  ip_forwarding_enabled = true

  ip_configuration {
    name                          = "wan-ipconfig"
    subnet_id                     = var.public_subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.0.4"
    public_ip_address_id          = azurerm_public_ip.pip_pfsense.id
  }
}

# Interface réseau LAN pour pfSense (connectée au sous-réseau LAN)
resource "azurerm_network_interface" "nic_pfsense_lan" {
  name                = "nic-pfsense-lan"
  location            = var.location
  resource_group_name = var.resource_group_name
  ip_forwarding_enabled = true

  ip_configuration {
    name                          = "lan-ipconfig"
    subnet_id                     = var.lan_subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.1.4"
  }
}

# Generate a random string for storage account name uniqueness
resource "random_string" "storage_account_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Storage account for pfSense VHD
resource "azurerm_storage_account" "sa_pfsense" {
  name                     = "pfsense${random_string.storage_account_suffix.result}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create container for VHD files
resource "azurerm_storage_container" "vhd_container" {
  name                  = "vhds"
  storage_account_id    = azurerm_storage_account.sa_pfsense.id
  container_access_type = "private"
}

# Upload the pfSense VHD to the storage account
resource "azurerm_storage_blob" "pfsense_vhd" {
  name                   = "pfsense_os.vhd"
  storage_account_name   = azurerm_storage_account.sa_pfsense.name
  storage_container_name = azurerm_storage_container.vhd_container.name
  type                   = "Page"
  source                 = var.pfsense_vhd_path
}

# VM pfSense using the uploaded VHD
resource "azurerm_virtual_machine" "vm_pfsense" {
  name                  = "vm-pfsense"
  location              = var.location
  resource_group_name   = var.resource_group_name
  network_interface_ids = [
    azurerm_network_interface.nic_pfsense_wan.id,
    azurerm_network_interface.nic_pfsense_lan.id,
  ]
  primary_network_interface_id = azurerm_network_interface.nic_pfsense_wan.id
  vm_size                      = "Standard_B1s"

  # Using unmanaged disks with uploaded VHD
  storage_os_disk {
    name          = "os-disk-pfsense"
    vhd_uri       = "${azurerm_storage_account.sa_pfsense.primary_blob_endpoint}${azurerm_storage_container.vhd_container.name}/${azurerm_storage_blob.pfsense_vhd.name}"
    os_type       = "Linux"
    caching       = "ReadWrite"
    create_option = "Attach"
  }

  tags = {
    role = "firewall"
    environment = "production"
  }
}