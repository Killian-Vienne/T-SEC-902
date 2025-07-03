output "private_ip_address" {
  description = "The private IP address of the GLPI web server"
  value       = azurerm_network_interface.nic_glpi_web.private_ip_address
}

output "vm_id" {
  description = "The ID of the GLPI web server virtual machine"
  value       = azurerm_linux_virtual_machine.vm_glpi_web.id
} 