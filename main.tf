//////////////////////////////////
// Helpers
//////////////////////////////////

// Create a random postfix
resource "random_pet" "RG" {
  length    = 1
  separator = ""
}

resource "random_pet" "SH" {
  length    = 1
  separator = ""
}

// Set postfix as local value, in case we
// decide to change the randomizer ..
locals {
  uid  = random_pet.RG.id
  vmid = random_pet.SH.id
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
  name                = join("-",[var.prefix, "NSG"])
  
  resource_group_name = azurerm_resource_group.MAIN.name
  location            = azurerm_resource_group.MAIN.location
  tags                = var.tags
}

resource "azurerm_subnet_network_security_group_association" "MAIN" {
  subnet_id                 = azurerm_subnet.MAIN.id
  network_security_group_id = azurerm_network_security_group.MAIN.id
}

// ASG for sessions-hosts
resource "azurerm_application_security_group" "MAIN" {
  name                = join("-",[var.prefix, "ASG"])
  location            = azurerm_resource_group.MAIN.location
  resource_group_name = azurerm_resource_group.MAIN.name
  tags                = var.tags
}

//////////////////////////////////
// Network Security | rules
//////////////////////////////////
// https://learn.microsoft.com/en-us/azure/virtual-network/service-tags-overview
// https://learn.microsoft.com/en-us/azure/virtual-desktop/safe-url-list?tabs=azure

resource "azurerm_network_security_rule" "RDS" {
  name                        = "AllowRDS"
  priority                    = 500
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_address_prefix       = "*"
  source_port_range           = "*"
  destination_port_range      = "3389"  

  destination_application_security_group_ids = [
    azurerm_application_security_group.MAIN.id,
  ]

  resource_group_name         = azurerm_resource_group.MAIN.name
  network_security_group_name = azurerm_network_security_group.MAIN.name
}

module "NSGRULES" {
  source = "./modules/nsg-rules"
  count  = var.flags.nsgrules ? 1 : 0
 
  config = {
    rg  = azurerm_resource_group.MAIN
    nsg = azurerm_network_security_group.MAIN
    asg = azurerm_application_security_group.MAIN
  }
}

//////////////////////////////////
// Virtual Desktop
//////////////////////////////////
// https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_desktop_host_pool
// https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_desktop_host_pool_registration_info

resource "azurerm_virtual_desktop_host_pool" "MAIN" {
  name                     = join("-",[var.host_pool.name, "HP"])
  type                     = var.host_pool.type
  load_balancer_type       = var.host_pool.load_balancer_type
  validate_environment     = var.host_pool.validate_environment
  start_vm_on_connect      = var.host_pool.start_vm_on_connect
  maximum_sessions_allowed = var.host_pool.max_sessions_allowed

  // https://learn.microsoft.com/nb-no/windows-server/remote/remote-desktop-services/clients/rdp-files
  custom_rdp_properties = join("", [
    "targetisaadjoined:i:1;",
    "enablerdsaadauth:i:1;",
    "redirectlocation:i:1;",
    "videoplaybackmode:i:1;",
    "audiocapturemode:i:1;",
    "audiomode:i:0;",
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
  rotation_hours = 2
}

resource "azurerm_virtual_desktop_host_pool_registration_info" "MAIN" {
  hostpool_id     = azurerm_virtual_desktop_host_pool.MAIN.id
  expiration_date = time_rotating.TOKEN.rotation_rfc3339 // timeadd(timestamp(), "2h")
}

//////////////////////////////////
// Virtual Desktop | Workspace
//////////////////////////////////

// Create Workspace (collection of application groups)
resource "azurerm_virtual_desktop_workspace" "MAIN" {
  name                = "Workspace"
  location            = azurerm_resource_group.MAIN.location
  resource_group_name = azurerm_resource_group.MAIN.name
}

//////////////////////////////////
// Virtual Desktop | Application Group (Desktop)
//////////////////////////////////

// Create the default application group for using Remote Desktop
resource "azurerm_virtual_desktop_application_group" "DESKTOP" {
  name                = "Desktop-AG"
  type                = "Desktop"
  host_pool_id        = azurerm_virtual_desktop_host_pool.MAIN.id
  location            = azurerm_resource_group.MAIN.location
  resource_group_name = azurerm_resource_group.MAIN.name
}

resource "azurerm_virtual_desktop_workspace_application_group_association" "MAIN" {
  workspace_id         = azurerm_virtual_desktop_workspace.MAIN.id
  application_group_id = azurerm_virtual_desktop_application_group.DESKTOP.id
}

//////////////////////////////////
// Virtual Desktop | Application Group (RemoteApp)
//////////////////////////////////
// https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_desktop_application_group

resource "azurerm_virtual_desktop_application_group" "RAPP" {
  name                = "RemoteApp-AG"
  type                = "RemoteApp"
  host_pool_id        = azurerm_virtual_desktop_host_pool.MAIN.id
  location            = azurerm_resource_group.MAIN.location
  resource_group_name = azurerm_resource_group.MAIN.name
}

resource "azurerm_virtual_desktop_workspace_application_group_association" "RAPP" {
  workspace_id         = azurerm_virtual_desktop_workspace.MAIN.id
  application_group_id = azurerm_virtual_desktop_application_group.RAPP.id
}

//////////////////////////////////
// SessionHosts
//////////////////////////////////

module "SESSIONHOST" {
  source = "./modules/session-hosts"
 
  config = {
    resource_group    = azurerm_resource_group.MAIN
    host_pool         = azurerm_virtual_desktop_host_pool.MAIN
    registration_info = azurerm_virtual_desktop_host_pool_registration_info.MAIN
    subnet            = azurerm_subnet.MAIN
    nsg               = azurerm_network_security_group.MAIN
    asg               = azurerm_application_security_group.MAIN
  }

  overrides = {
    prefix          = local.vmid
    instances       = var.session_hosts
    priority        = "Spot"
    eviction_policy = "Delete"
  }
}

//////////////////////////////////
// AutoScaler
//////////////////////////////////

module "AUTOSCALER" {
  source = "./modules/auto-scaler"
  count  = var.flags.autoscaler ? 1 : 0
  
  config = {
    resource_group = azurerm_resource_group.MAIN
    host_pool      = azurerm_virtual_desktop_host_pool.MAIN
  }
}

//////////////////////////////////
// Azure AD User Integration
//////////////////////////////////

module "USER_ACCESS" {
  source = "./modules/azure-ad"
  count  = var.flags.user_access ? 1 : 0
  
  config = {
    resource_group = azurerm_resource_group.MAIN
  }
}

//////////////////////////////////
// Remote Applications
//////////////////////////////////

module "REMOTEAPP" {
  source = "./modules/rd-app"
  
  for_each = {
    for app in var.remote_applications: app.name => app
  }
  
  application_group = azurerm_virtual_desktop_application_group.RAPP
  config            = each.value
}
