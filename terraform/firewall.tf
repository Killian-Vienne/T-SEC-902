# Adresse IP publique pour pfSense
resource "azurerm_public_ip" "pfsense_pip" {
  name                = "pip-pfsense"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                = "Standard"
}

# Interface réseau WAN pour pfSense (connectée au sous-réseau public)
resource "azurerm_network_interface" "nic_pfsense_wan" {
  name                = "nic-${var.firewall_vm_name}-wan"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "wan-ipconfig"
    subnet_id                     = azurerm_subnet.wan.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pfsense_pip.id
  }
}

# Interface réseau LAN pour pfSense (connectée au sous-réseau DMZ)
resource "azurerm_network_interface" "nic_pfsense_lan" {
  name                = "nic-${var.firewall_vm_name}-lan"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "lan-ipconfig"
    subnet_id                     = azurerm_subnet.dmz.id
    private_ip_address_allocation = "Static"
    private_ip_address           = "10.0.1.4"
  }
}

# Création d'un compte de stockage pour l'image
resource "azurerm_storage_account" "vhd_storage" {
  name                     = "pfsensvhdstorage"
  resource_group_name      = data.azurerm_resource_group.rg.name
  location                 = data.azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Création d'un conteneur pour stocker le VHD
resource "azurerm_storage_container" "vhd_container" {
  name                  = "vhds"
  storage_account_id    = azurerm_storage_account.vhd_storage.id
  container_access_type = "private"
}

# Téléchargement de l'image VHD pfSense vers le conteneur de stockage
# Utilisation de la condition pour créer le blob seulement s'il n'existe pas déjà
resource "azurerm_storage_blob" "pfsense_vhd" {
  count                  = fileexists("${path.module}/image_os/PfSence.vhd") ? 1 : 0
  name                   = "PfSence.vhd"
  storage_account_name   = azurerm_storage_account.vhd_storage.name
  storage_container_name = azurerm_storage_container.vhd_container.name
  type                   = "Page"
  source                 = "${path.module}/image_os/PfSence.vhd"
}

# VM pfSense using the uploaded VHD
resource "azurerm_virtual_machine" "vm_pfsense" {
  name                  = "vm-pfsense"
  location              = data.azurerm_resource_group.rg.location
  resource_group_name   = data.azurerm_resource_group.rg.name
  network_interface_ids = [
    azurerm_network_interface.nic_pfsense_wan.id,
    azurerm_network_interface.nic_pfsense_lan.id,
   /*  azurerm_network_interface.nic_pfsense_opt1.id */
  ]
  primary_network_interface_id = azurerm_network_interface.nic_pfsense_wan.id
  vm_size                      = "Standard_B1s"

  # Using unmanaged disks with the uploaded VHD
  storage_os_disk {
    name          = "os-disk-pfsense"
    vhd_uri       = "${azurerm_storage_account.vhd_storage.primary_blob_endpoint}${azurerm_storage_container.vhd_container.name}/PfSence.vhd"
    os_type       = "Linux"
    caching       = "ReadWrite"
    create_option = "Attach"
  }

  # Cette dépendance explicite est nécessaire seulement si le blob est créé
  depends_on = [
    azurerm_storage_container.vhd_container,
    azurerm_storage_blob.pfsense_vhd
  ]

  # Balises pour identification
  tags = {
    role = "firewall"
    environment = "production"
  }
}