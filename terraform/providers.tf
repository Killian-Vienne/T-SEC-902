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
  backend "local" {
    path = "./terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  resource_provider_registrations = "none"
}