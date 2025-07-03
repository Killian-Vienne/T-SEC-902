output "vnet_id" {
  description = "The ID of the virtual network"
  value       = azurerm_virtual_network.vnet_main.id
}

output "public_subnet_id" {
  description = "The ID of the public subnet for pfSense WAN interface"
  value       = azurerm_subnet.snet_public.id
}

output "lan_subnet_id" {
  description = "The ID of the LAN subnet for all internal VMs"
  value       = azurerm_subnet.snet_lan.id
}

output "bastion_subnet_id" {
  description = "The ID of the bastion subnet"
  value       = azurerm_subnet.snet_bastion.id
}


output "nsg_public_id" {
  description = "The ID of the public subnet NSG" 
  value       = azurerm_network_security_group.nsg_public.id
}

output "nsg_lan_id" {
  description = "The ID of the LAN subnet NSG"
  value       = azurerm_network_security_group.nsg_lan.id
}

output "bastion_public_ip_id" {
  description = "The ID of the bastion public IP"
  value       = azurerm_public_ip.pip_bastion.id
}

output "bastion_public_ip_address" {
  description = "The public IP address for bastion"
  value       = azurerm_public_ip.pip_bastion.ip_address
} 