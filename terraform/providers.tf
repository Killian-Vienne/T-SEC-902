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
}

provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
  subscription_id                 = "db7c2d44-82fa-4a66-99fe-a162b13ecf60"
}