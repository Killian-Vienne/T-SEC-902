# Génération aléatoire du mot de passe
resource "random_password" "password" {
  length           = 12
  special          = true
  upper            = true
  lower            = true
  numeric          = true
  override_special = "!@#%^&*()-_=+[]{}<>?"
}

# Resource Group
data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

# Networking Module - First create subnets and routing
module "networking" {
  source = "./modules/networking"

  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  vnet_name           = "vnet-main"
}

# pfSense Module
module "pfsense" {
  source = "./modules/pfsense"

  resource_group_name  = data.azurerm_resource_group.rg.name
  location              = data.azurerm_resource_group.rg.location
  public_subnet_id      = module.networking.public_subnet_id
  lan_subnet_id         = module.networking.lan_subnet_id
  admin_username        = var.admin_username
  admin_password        = var.admin_password != null ? var.admin_password : random_password.password.result
  pfsense_vhd_path      = var.pfsense_vhd_path

  depends_on = [module.networking]
}

# Networking Security Module - Configure after pfSense is created
module "networking_security" {
  source = "./modules/networking_security"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  pfsense_lan_nic_id  = module.pfsense.lan_nic_id
  pfsense_wan_nic_id  = module.pfsense.wan_nic_id
  pfsense_lan_ip      = "10.0.1.4"
  bastion_subnet_cidr = "10.0.3.0/24"

  depends_on = [module.pfsense]
}

# Bastion Host Module
module "bastion" {
  source = "./modules/bastion"

  resource_group_name  = data.azurerm_resource_group.rg.name
  location             = data.azurerm_resource_group.rg.location
  bastion_subnet_id    = module.networking.bastion_subnet_id
  admin_username       = var.admin_username
  ssh_public_key_path  = var.ssh_public_key_path
  public_ip_id         = module.networking.bastion_public_ip_id
}

# GLPI Web Module
module "glpi_web" {
  source = "./modules/glpi-web"

  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  lan_subnet_id       = module.networking.lan_subnet_id
  admin_username      = var.admin_username
  admin_password      = var.admin_password != null ? var.admin_password : random_password.password.result
  bastion_private_ip  = module.bastion.private_ip_address
  ssh_public_key_path = var.ssh_public_key_path
}

# GLPI DB Module
module "glpi_db" {
  source = "./modules/glpi-db"

  resource_group_name  = data.azurerm_resource_group.rg.name
  location             = data.azurerm_resource_group.rg.location
  lan_subnet_id        = module.networking.lan_subnet_id
  admin_username       = var.admin_username
  admin_password       = var.admin_password != null ? var.admin_password : random_password.password.result
  glpi_web_private_ip  = module.glpi_web.private_ip_address
  bastion_private_ip   = module.bastion.private_ip_address
  ssh_public_key_path  = var.ssh_public_key_path
}

# Wazuh Module
module "wazuh" {
  source = "./modules/wazuh"

  resource_group_name  = data.azurerm_resource_group.rg.name
  location             = data.azurerm_resource_group.rg.location
  lan_subnet_id        = module.networking.lan_subnet_id
  admin_username       = var.admin_username
  admin_password       = var.admin_password != null ? var.admin_password : random_password.password.result
  bastion_private_ip   = module.bastion.private_ip_address
  ssh_public_key_path  = var.ssh_public_key_path
}