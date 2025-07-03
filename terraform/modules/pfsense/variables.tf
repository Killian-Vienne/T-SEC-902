variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  description = "The Azure region to deploy resources to"
  type        = string
}

variable "public_subnet_id" {
  description = "The ID of the public subnet for pfSense WAN interface"
  type        = string
}

variable "lan_subnet_id" {
  description = "The ID of the LAN subnet for pfSense LAN interface"
  type        = string
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
  default     = "adminuser"
}

variable "admin_password" {
  description = "Admin password for the VM"
  type        = string
  sensitive   = true
}

variable "pfsense_vhd_path" {
  description = "Local path to the pfSense VHD file to upload"
  type        = string
} 