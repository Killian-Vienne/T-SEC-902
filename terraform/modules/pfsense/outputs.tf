output "vm_id" {
  description = "The ID of the pfSense VM"
  value       = azurerm_virtual_machine.vm_pfsense.id
}

output "private_ip_address" {
  description = "The private IP address of the pfSense VM"
  value       = azurerm_network_interface.nic_pfsense_wan.private_ip_address
}

output "public_ip_address" {
  description = "The public IP address of the pfSense VM"
  value       = azurerm_public_ip.pip_pfsense.ip_address
}

output "lan_nic_id" {
  description = "The ID of the pfSense LAN network interface"
  value       = azurerm_network_interface.nic_pfsense_lan.id
}

output "wan_nic_id" {
  description = "The ID of the pfSense WAN network interface"
  value       = azurerm_network_interface.nic_pfsense_wan.id
}

output "pfsense_lan_ip" {
  description = "The IP address of the pfSense LAN interface"
  value       = azurerm_network_interface.nic_pfsense_lan.private_ip_address
}

output "pfsense_wan_ip" {
  description = "The IP address of the pfSense WAN interface"
  value       = azurerm_network_interface.nic_pfsense_wan.private_ip_address
} 