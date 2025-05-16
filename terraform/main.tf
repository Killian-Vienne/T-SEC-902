# Génération aléatoire des mots de passe
resource "random_password" "firewall_password" {
  length           = 16
  special          = true
  upper            = true
  lower            = true
  numeric          = true
  override_special = "!@#%^&*()-_=+[]{}<>?"
}

resource "random_password" "wazuh_password" {
  length           = 16
  special          = true
  upper            = true
  lower            = true
  numeric          = true
  override_special = "!@#%^&*()-_=+[]{}<>?"
}

resource "random_password" "glpi_password" {
  length           = 16
  special          = true
  upper            = true
  lower            = true
  numeric          = true
  override_special = "!@#%^&*()-_=+[]{}<>?"
}

resource "random_password" "database_password" {
  length           = 16
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