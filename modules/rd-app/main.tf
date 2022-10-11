//////////////////////////////////
// Virtual Desktop Application
//////////////////////////////////

resource "azurerm_virtual_desktop_application_group" "MAIN" {
  name          = "ExampleApps"
  type          = "RemoteApp"
  host_pool_id  = azurerm_virtual_desktop_host_pool.MAIN.id
  friendly_name = "Examples"
  description   = "Example RemoteApp Applications"

  location            = azurerm_resource_group.MAIN.location
  resource_group_name = azurerm_resource_group.MAIN.name
}


resource "azurerm_virtual_desktop_application" "MAIN" {
  name                         = "notepad"
  friendly_name                = "Notepad"
  description                  = "Notepad text-editor"
  path                         = "C:\\WINDOWS\\System32\\notepad.exe"
  command_line_argument_policy = "DoNotAllow"
  show_in_portal               = false
  icon_path                    = "C:\\WINDOWS\\System32\\notepad.exe"
  icon_index                   = 0
  application_group_id         = azurerm_virtual_desktop_application_group.MAIN.id
}

