//////////////////////////////////
// Helpers
//////////////////////////////////

// Create a random postfix
resource "random_pet" "MAIN" {
  length    = 1
  separator = ""
}

// Set postfix as local value, in case we ever
// decide to change the source.
locals {
  uid = random_pet.MAIN.id
}

//////////////////////////////////
// Basic Resources
//////////////////////////////////

resource "azurerm_resource_group" "MAIN" {
  name     = join("-",[var.prefix, local.uid])
  location = var.location
  tags     = var.tags
}

resource "azurerm_virtual_network" "MAIN" {
  name                = var.virtual_network.name
  address_space       = var.virtual_network.address_space
  resource_group_name = azurerm_resource_group.MAIN.name
  location            = azurerm_resource_group.MAIN.location
  tags                = var.tags
}

resource "azurerm_subnet" "MAIN" {
  name                 = var.subnet.name
  address_prefixes     = var.subnet.address_prefixes
  resource_group_name  = azurerm_resource_group.MAIN.name
  virtual_network_name = azurerm_virtual_network.MAIN.name
}


//////////////////////////////////
// Network Security
//////////////////////////////////

resource "azurerm_network_security_group" "MAIN" {
  name                = join("-",[var.subnet.name, "NwSecGrp"])
  
  resource_group_name = azurerm_resource_group.MAIN.name
  location            = azurerm_resource_group.MAIN.location
  tags                = var.tags
}

resource "azurerm_subnet_network_security_group_association" "MAIN" {
  subnet_id                 = azurerm_subnet.MAIN.id
  network_security_group_id = azurerm_network_security_group.MAIN.id
}

resource "azurerm_application_security_group" "MAIN" {
  name                = join("-",["AvdHost", "AppSecGrp"])
  location            = azurerm_resource_group.MAIN.location
  resource_group_name = azurerm_resource_group.MAIN.name
  tags                = var.tags
}

resource "azurerm_network_security_rule" "RDS" {
  name                        = "AllowRDS"
  priority                    = 500
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = "*"
  
  destination_application_security_group_ids = [
    azurerm_application_security_group.MAIN.id,
  ]

  resource_group_name         = azurerm_resource_group.MAIN.name
  network_security_group_name = azurerm_network_security_group.MAIN.name
}

//////////////////////////////////
// Virtual Desktop
//////////////////////////////////
// https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_desktop_host_pool
// https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_desktop_host_pool_registration_info

resource "azurerm_virtual_desktop_host_pool" "MAIN" {
  name                     = var.host_pool.name
  type                     = var.host_pool.type
  load_balancer_type       = var.host_pool.load_balancer_type
  validate_environment     = var.host_pool.validate_environment
  maximum_sessions_allowed = var.host_pool.max_sessions_allowed

  // https://learn.microsoft.com/nb-no/windows-server/remote/remote-desktop-services/clients/rdp-files
  custom_rdp_properties = join(";", [
    "enablerdsaadauth:i:1",
    "targetisaadjoined:i:1",
  ])

  scheduled_agent_updates {
    enabled  = true
    timezone = "W. Europe Standard Time"
    
    schedule {
      day_of_week = "Tuesday"
      hour_of_day = 2
    }

    schedule {
      day_of_week = "Thursday"
      hour_of_day = 2
    }
  }
  
  resource_group_name = azurerm_resource_group.MAIN.name
  location            = azurerm_resource_group.MAIN.location
  tags                = var.tags
}

// Rotate when current time is behind rotation-time
resource "time_rotating" "TOKEN" {
  rotation_hours = 2 //or use e.g. timeadd(timestamp(), "2h")
}

resource "azurerm_virtual_desktop_host_pool_registration_info" "MAIN" {
  hostpool_id     = azurerm_virtual_desktop_host_pool.MAIN.id
  expiration_date = time_rotating.TOKEN.rotation_rfc3339
}

//////////////////////////////////
// Virtual Desktop | Workspace
//////////////////////////////////

// Create Workspace (a collection og application groups)
resource "azurerm_virtual_desktop_workspace" "MAIN" {
  name                = "DefaultWorkspace"
  location            = azurerm_resource_group.MAIN.location
  resource_group_name = azurerm_resource_group.MAIN.name
}

//////////////////////////////////
// Virtual Desktop | Applications
//////////////////////////////////

// Create the default application group for using Remote Desktop
resource "azurerm_virtual_desktop_application_group" "MAIN" {
  name                = "RemoteDesktop"
  type                = "Desktop"
  host_pool_id        = azurerm_virtual_desktop_host_pool.MAIN.id
  location            = azurerm_resource_group.MAIN.location
  resource_group_name = azurerm_resource_group.MAIN.name
}

resource "azurerm_virtual_desktop_workspace_application_group_association" "MAIN" {
  workspace_id         = azurerm_virtual_desktop_workspace.MAIN.id
  application_group_id = azurerm_virtual_desktop_application_group.MAIN.id
}

//////////////////////////////////
// SessionHosts
//////////////////////////////////

module "SESSIONHOST" {
  source = "./modules/session-host"
  count  = 1
  
  config = {
    resource_group    = azurerm_resource_group.MAIN
    host_pool         = azurerm_virtual_desktop_host_pool.MAIN
    registration_info = azurerm_virtual_desktop_host_pool_registration_info.MAIN
    subnet            = azurerm_subnet.MAIN
    asg               = azurerm_application_security_group.MAIN
  }

  overrides = {
    prefix = "Default"
  }
}

//////////////////////////////////
// Azure AD User Access
//////////////////////////////////

module "USER_ACCESS" {
  source = "./modules/azure-ad"
  count  = 1
  
  config = {
    resource_group = azurerm_resource_group.MAIN
  }
}

//////////////////////////////////
// AutoScaler
//////////////////////////////////

module "AUTOSCALER" {
  source = "./modules/auto-scaler"
  count  = 0
  
  config = {
    resource_group = azurerm_resource_group.MAIN
    host_pool      = azurerm_virtual_desktop_host_pool.MAIN
  }
}
