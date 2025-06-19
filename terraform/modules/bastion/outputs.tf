output "private_ip_address" {
  description = "The private IP address of the bastion host"
  value       = azurerm_network_interface.nic_bastion.private_ip_address
}

output "vm_id" {
  description = "The ID of the bastion virtual machine"
  value       = azurerm_linux_virtual_machine.vm_bastion.id
} 