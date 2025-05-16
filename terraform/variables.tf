variable "resource_group_name" {
  default = "rg-group-36"
}

variable "location" {
  description = "Emplacement des ressources Azure"
  default     = "West Europe"
}

variable "vnet_name" {
  description = "Nom du réseau virtuel"
  default     = "vnet-securite"
}

variable "vnet_address_space" {
  description = "Espace d'adressage du réseau virtuel"
  default     = ["10.0.0.0/16"]
}

variable "subnet_dmz" {
  description = "Configuration du sous-réseau DMZ"
  default = {
    name             = "subnet-public"
    address_prefixes = ["10.0.1.0/24"]
  }
}

variable "subnet_securite" {
  description = "Configuration du sous-réseau Sécurité"
  default = {
    name             = "subnet-securite"
    address_prefixes = ["10.0.2.0/24"]
  }
}

variable "subnet_application" {
  description = "Configuration du sous-réseau Application"
  default = {
    name             = "subnet-application"
    address_prefixes = ["10.0.3.0/24"]
  }
}

variable "subnet_database" {
  description = "Configuration du sous-réseau Base de Données"
  default = {
    name             = "subnet-database"
    address_prefixes = ["10.0.4.0/24"]
  }
}

variable "subnet_wan" {
  description = "Configuration du sous-réseau WAN pour l'accès Internet"
  default = {
    name             = "subnet-wan"
    address_prefixes = ["10.0.0.0/24"]
  }
}

variable "bastion_name" {
  description = "Nom du service Azure Bastion"
  default     = "bastion-host"
}

variable "firewall_vm_name" {
  description = "Nom de la VM pfSense"
  default     = "vm-pfsense"
}

variable "wazuh_vm_name" {
  description = "Nom de la VM Wazuh SIEM"
  default     = "vm-wazuh"
}

variable "glpi_vm_name" {
  description = "Nom de la VM GLPI"
  default     = "vm-glpi"
}

variable "database_vm_name" {
  description = "Nom de la VM de base de données"
  default     = "vm-database"
}

variable "admin_username" {
  description = "Nom d'utilisateur administrateur pour les VMs"
  default     = "adminuser"
}

variable "vm_size" {
  description = "Taille par défaut des VMs"
  default     = "Standard_B1s"
}
