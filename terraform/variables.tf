# Variables
variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
  default     = "rg-group-36"
}

variable "subscription_id" {
  description = "The Azure subscription ID"
  type        = string
  sensitive   = true
}

variable "admin_username" {
  description = "Admin username for all VMs"
  type        = string
  default     = "adminuser"
}

variable "admin_password" {
  description = "Admin password for all VMs"
  type        = string
  sensitive   = true
  default     = null
}

variable "pfsense_vhd_path" {
  description = "Local path to the pfSense VHD file to upload"
  type        = string
  default     = "./PfSence.vhd"
}

variable "ssh_public_key_path" {
  description = "The path to the SSH public key file for the jumphost"
  type        = string
  default     = "~/.ssh/azure-ssh.pub"
}