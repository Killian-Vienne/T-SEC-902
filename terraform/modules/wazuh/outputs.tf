output "private_ip_address" {
  description = "The private IP address of the Wazuh server"
  value       = azurerm_network_interface.nic_wazuh.private_ip_address
}

output "vm_id" {
  description = "The ID of the Wazuh server virtual machine"
  value       = azurerm_linux_virtual_machine.vm_wazuh.id
} 