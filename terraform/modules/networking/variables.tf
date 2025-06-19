variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  description = "The Azure region to deploy resources to"
  type        = string
}

variable "vnet_name" {
  description = "The name of the virtual network"
  type        = string
  default     = "vnet-main"
}

variable "pfsense_lan_nic_id" {
  description = "The ID of the pfSense LAN network interface"
  type        = string
  default     = ""
}

variable "pfsense_lan_ip" {
  description = "The IP address of the pfSense LAN interface"
  type        = string
  default     = "10.0.1.4"
} 