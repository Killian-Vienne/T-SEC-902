terraform {
  required_providers {
    ansible = {
      version = "~> 1.3.0"
      source  = "ansible/ansible"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.17.0"
    }
  }
    #backend "azurerm" {
    #resource_group_name  = "StorageAccount-ResourceGroup"
    #storage_account_name = "abcd1234"
    #container_name       = "tfstate"
    #key                  = "prod.terraform.tfstate"
    #use_azuread_auth     = true
  #}
}

provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
  subscription_id = "db7c2d44-82fa-4a66-99fe-a162b13ecf60"
}