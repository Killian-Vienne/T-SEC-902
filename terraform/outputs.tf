output "virtual_network_id" {
  value = azurerm_virtual_network.vnet.id
}

# output "bastion_host_id" {
#   value = azurerm_bastion_host.bastion.id
# }

# output "firewall_private_ip" {
#   value = azurerm_network_interface.firewall_nic.private_ip_address
# }

output "wazuh_private_ip" {
  value = azurerm_network_interface.wazuh_nic.private_ip_address
}

output "glpi_private_ip" {
  value = azurerm_network_interface.glpi_nic.private_ip_address
}

output "database_private_ip" {
  value = azurerm_network_interface.database_nic.private_ip_address
}

output "firewall_admin_password" {
  value     = random_password.firewall_password.result
  sensitive = true
}

output "wazuh_admin_password" {
  value     = random_password.wazuh_password.result
  sensitive = true
}

output "glpi_admin_password" {
  value     = random_password.glpi_password.result
  sensitive = true
}

output "database_admin_password" {
  value     = random_password.database_password.result
  sensitive = true
}

output "bastion_public_ip" {
  value     = azurerm_public_ip.bastion_pip.ip_address
  sensitive = true
}