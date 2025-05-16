# Interface réseau pour la base de données
resource "azurerm_network_interface" "database_nic" {
  name                = "nic-${var.database_vm_name}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.database.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.4.10"
  }
}

# VM Base de données
resource "azurerm_linux_virtual_machine" "database" {
  name                  = var.database_vm_name
  location              = data.azurerm_resource_group.rg.location
  resource_group_name   = data.azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.database_nic.id]
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
  admin_password                  = random_password.database_password.result
  disable_password_authentication = false

  tags = {
    environment = "production"
    role        = "database"
  }
}