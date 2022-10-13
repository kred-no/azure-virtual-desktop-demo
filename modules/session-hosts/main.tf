//////////////////////////////////
// VM Image
//////////////////////////////////

/*data "azurerm_platform_image" "MAIN" {
  location  = var.config.resource_group.location
  publisher = var.overrides.image_publisher
  offer     = var.overrides.image_offer
  sku       = var.overrides.image_sku
  #version   = var.overrides.image_version
}*/

//////////////////////////////////
// Network Interface
//////////////////////////////////

// Create network interface for SessionHost VM(s)
resource "azurerm_network_interface" "MAIN" {
  count = var.overrides.instances

  name = join("-",[var.overrides.prefix, count.index])

  ip_configuration {
    name                          = "internal"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = var.config.subnet.id
  }
  
  location            = var.config.resource_group.location
  resource_group_name = var.config.resource_group.name
}

resource "azurerm_network_interface_application_security_group_association" "MAIN" {
  for_each = {
    for idx,nic in azurerm_network_interface.MAIN: idx => nic.id
  }
  
  network_interface_id          = each.value
  application_security_group_id = var.config.asg.id
}

resource "azurerm_network_interface_security_group_association" "MAIN" {
  for_each = {
    for idx,nic in azurerm_network_interface.MAIN: idx => nic.id
  }

  network_interface_id      = each.value
  network_security_group_id = var.config.nsg.id
}

//////////////////////////////////
// Virtual Machine | Windows
//////////////////////////////////

resource "random_id" "UNIQUE" {
  for_each = {
    for idx,nic in azurerm_network_interface.MAIN: idx => nic.id
  }
  
  byte_length = 2
  keepers = {
    NIC = each.value
  }
}

resource "azurerm_windows_virtual_machine" "MAIN" {
  #count = var.overrides.instances
  for_each = {
    for idx,nic in azurerm_network_interface.MAIN: idx => nic.id
  }
  
  name = join("-",[
    var.overrides.prefix,
    random_id.UNIQUE[each.key].hex
  ])
  
  network_interface_ids = [
    azurerm_network_interface.MAIN[each.key].id,
  ]

  license_type    = "Windows_Client"
  size            = var.overrides.size
  priority        = var.overrides.priority
  eviction_policy = var.overrides.eviction_policy
  admin_username  = var.overrides.admin_username
  admin_password  = var.overrides.admin_password

  identity {
    type = "SystemAssigned"
  }

  source_image_reference {
    publisher = var.overrides.image_publisher
    offer     = var.overrides.image_offer
    sku       = var.overrides.image_sku
    version   = var.overrides.image_version
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }
  
  resource_group_name = var.config.resource_group.name
  location            = var.config.resource_group.location
}

//////////////////////////////////
// Virtual Machine | Extensions
// az vm extension image list --location <location> -o table
//////////////////////////////////
// https://stackoverflow.com/questions/70743129/terraform-azure-vm-extension-does-not-join-vm-to-azure-active-directory-for-azur

resource "azurerm_virtual_machine_extension" "AAD_LOGIN" {
  for_each = {
    for idx,vm in azurerm_windows_virtual_machine.MAIN: idx => vm.id
  }

  // az vm extension image list --name AADLoginForWindows --publisher Microsoft.Azure.ActiveDirectory --location <location> -o table
  name                       = "AADLogin"
  publisher                  = "Microsoft.Azure.ActiveDirectory"
  type                       = "AADLoginForWindows"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true
  virtual_machine_id         = each.value

  lifecycle {
    ignore_changes = []
  }
}

locals {
  // aadJoin = true is missing for newer versions
  avd_agent_version = "Configuration_06-15-2022.zip" // "Configuration.zip"
  avd_agent_handler_version = "2.73" // "2.83"
}

// RdAgent
resource "azurerm_virtual_machine_extension" "HOSTPOOL" {
  for_each = {
    for idx,vm in azurerm_windows_virtual_machine.MAIN: idx => vm.id
  }
  
  depends_on = [
    azurerm_virtual_machine_extension.AAD_LOGIN,
  ]

  //az vm extension image list --name DSC --publisher Microsoft.Powershell --location <location> -o table
  name                       = "AddSessionHost"
  publisher                  = "Microsoft.Powershell"
  type                       = "DSC"
  type_handler_version       = local.avd_agent_handler_version
  auto_upgrade_minor_version = true
  virtual_machine_id         = each.value

  settings = jsonencode({
    modulesUrl = join("/",["https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts", local.avd_agent_version ])
    configurationFunction = "Configuration.ps1\\AddSessionHost"
    properties = {
      HostPoolName = var.config.host_pool.name
      aadJoin      = true
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
// Virtual Machine | AAD Fix
//////////////////////////////////

// Required when using AAD instead of ADDS. Run last; reboots
resource "azurerm_virtual_machine_extension" "AADJPRIVATE" {
  for_each = {
    for idx,vm in azurerm_windows_virtual_machine.MAIN: idx => vm.id
  }

  depends_on = [
    azurerm_virtual_machine_extension.AAD_LOGIN,
    azurerm_virtual_machine_extension.HOSTPOOL,
  ]

  // az vm extension image list --name CustomScriptExtension --publisher Microsoft.Compute --location <location> -o table
  name                       = "AADJPRIVATE"
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true
  virtual_machine_id         = each.value

  settings = jsonencode({
    commandToExecute = join("", [
      "powershell.exe -Command \"New-Item -Path HKLM:\\SOFTWARE\\Microsoft\\RDInfraAgent\\AADJPrivate\"",
      ";shutdown -r -t 10",
      ";exit 0",
    ])
  })
  
  lifecycle {
    ignore_changes = [settings]
  }
}
