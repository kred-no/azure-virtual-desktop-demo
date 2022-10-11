//////////////////////////////////
// Virtual Machine | Windows
//////////////////////////////////

// Create network interface for SessionHost VM(s)
resource "azurerm_network_interface" "MAIN" {
  name = join("-",[var.overrides.prefix, "Nic"])

  ip_configuration {
    name                          = "internal"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = var.config.subnet.id
  }
  
  location            = var.config.resource_group.location
  resource_group_name = var.config.resource_group.name
}

resource "azurerm_network_interface_application_security_group_association" "MAIN" {
  network_interface_id          = azurerm_network_interface.MAIN.id
  application_security_group_id = var.config.asg.id
}

resource "azurerm_windows_virtual_machine" "MAIN" {
  name            = join("-",[var.overrides.prefix, "Vm"])
  size            = var.overrides.size
  priority        = "Spot"
  eviction_policy = "Delete"
  
  admin_username = "superman"
  admin_password = "Cl@rkK3nt"

  identity {
    type = "SystemAssigned"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "Windows-11"
    sku       = "win11-22h2-ent"
    version   = "latest"
  }

  network_interface_ids = [
    azurerm_network_interface.MAIN.id,
  ]

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }
  
  resource_group_name = var.config.resource_group.name
  location            = var.config.resource_group.location
}

//////////////////////////////////
// Virtual Machine | Extensions
//////////////////////////////////
// https://stackoverflow.com/questions/70743129/terraform-azure-vm-extension-does-not-join-vm-to-azure-active-directory-for-azur

resource "azurerm_virtual_machine_extension" "AAD" {
  depends_on = [
    azurerm_windows_virtual_machine.MAIN,
  ]

  name                       = "AADLogin"
  publisher                  = "Microsoft.Azure.ActiveDirectory"
  type                       = "AADLoginForWindows"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true
  virtual_machine_id         = azurerm_windows_virtual_machine.MAIN.id

  lifecycle {
    ignore_changes = []
  }
}

resource "azurerm_virtual_machine_extension" "HOSTPOOL" {
  depends_on = [
    azurerm_windows_virtual_machine.MAIN,
  ]

  name                       = "AddSessionHost"
  publisher                  = "Microsoft.Powershell"
  type                       = "DSC"
  type_handler_version       = "2.73"
  auto_upgrade_minor_version = true
  virtual_machine_id         = azurerm_windows_virtual_machine.MAIN.id
  
  settings = jsonencode({
    modulesUrl = "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_02-23-2022.zip"
    configurationFunction = "Configuration.ps1\\AddSessionHost"
    properties = {
      HostPoolName = var.config.host_pool.name
    }
  })

  protected_settings = jsonencode({
    properties = {
      registrationInfoToken = var.config.registration_info.token
    }
  })
 
  lifecycle {
    ignore_changes = [settings, protected_settings]
  }
}

//////////////////////////////////
// Virtual Machine | Workaround 1
//////////////////////////////////

// Required when using AAD instead of ADDS
resource "azurerm_virtual_machine_extension" "AADJPRIVATE" {
  depends_on = [
    azurerm_windows_virtual_machine.MAIN,
    azurerm_virtual_machine_extension.AAD,
  ]

  name                 = "AADJPRIVATE"
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"
  virtual_machine_id = azurerm_windows_virtual_machine.MAIN.id

  settings = jsonencode({
    commandToExecute = join("", [
      "powershell.exe -Command ",
      "New-Item -Path HKLM:/SOFTWARE/Microsoft/RDInfraAgent/AADJPrivate; ",
      "shutdown -r -t 10; ",
      "exit 0",
    ])
  })
  
  lifecycle {
    ignore_changes = [settings]
  }
}
