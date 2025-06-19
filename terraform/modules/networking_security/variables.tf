variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  description = "The Azure region to deploy resources to"
  type        = string
}

variable "pfsense_lan_nic_id" {
  description = "The ID of the pfSense LAN network interface"
  type        = string
}

variable "pfsense_wan_nic_id" {
  description = "The ID of the pfSense WAN network interface"
  type        = string
}

variable "pfsense_lan_ip" {
  description = "The IP address of the pfSense LAN interface"
  type        = string
}

variable "bastion_subnet_cidr" {
  description = "The CIDR block for the bastion subnet"
  type        = string
  default     = "10.0.3.0/24"
}