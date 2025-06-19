variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  description = "The Azure region to deploy resources to"
  type        = string
}

variable "bastion_subnet_id" {
  description = "The ID of the subnet where the bastion will be deployed"
  type        = string
}

variable "admin_username" {
  description = "The admin username for the bastion"
  type        = string
}

variable "ssh_public_key_path" {
  description = "The path to the SSH public key file for the bastion"
  type        = string
}

variable "public_ip_id" {
  description = "The ID of the public IP address for the bastion"
  type        = string
} 