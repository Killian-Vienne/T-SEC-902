variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  description = "The Azure region to deploy resources to"
  type        = string
}

variable "lan_subnet_id" {
  description = "The ID of the LAN subnet where the GLPI web server will be deployed"
  type        = string
}

variable "vm_size" {
  description = "The size of the VM"
  type        = string
  default     = "Standard_B1s"
}

variable "admin_username" {
  description = "The admin username for the GLPI web server"
  type        = string
}

variable "admin_password" {
  description = "The admin password for the GLPI web server"
  type        = string
  sensitive   = true
}

variable "bastion_private_ip" {
  description = "The private IP address of the bastion host"
  type        = string
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key file"
  type        = string
}