# Interface réseau pour GLPI
resource "azurerm_network_interface" "glpi_nic" {
  name                = "nic-${var.glpi_vm_name}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.application.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.3.10"
  }
}

# VM GLPI
resource "azurerm_linux_virtual_machine" "glpi" {
  name                  = var.glpi_vm_name
  location              = data.azurerm_resource_group.rg.location
  resource_group_name   = data.azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.glpi_nic.id]
  size                  = var.vm_size

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }

  admin_username                  = var.admin_username
  admin_password                  = random_password.glpi_password.result
  disable_password_authentication = false

  tags = {
    environment = "production"
    role        = "application"
  }
}