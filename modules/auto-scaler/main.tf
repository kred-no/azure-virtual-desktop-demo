//////////////////////////////////
// Parent Resources
//////////////////////////////////

data "azurerm_resource_group" "MAIN" {
  name = var.config.resource_group.name
}

//////////////////////////////////
// Virtual Desktop | Auto-Scaling
//////////////////////////////////

resource "random_uuid" "MAIN" {}

/*data "azuread_application" "MAIN" {
  display_name   = "Azure Virtual Desktop"
  #application_id = "9cdead84-a844-4324-93f2-b2e6bb768d07"
  #object_id      = "7f6cbba6-23c8-40a6-b629-fbaddced642c"
}*/

data "azuread_service_principal" "MAIN" {
  display_name   = "Azure Virtual Desktop"
  #application_id = "9cdead84-a844-4324-93f2-b2e6bb768d07"
  #object_id      = "7f6cbba6-23c8-40a6-b629-fbaddced642c"
}

resource "azurerm_role_definition" "MAIN" {
  name        = "AzureVirtualDesktopAutoScaler"
  description = "AzureVirtualDesktop AutoScaler Role"
  scope       = data.azurerm_resource_group.MAIN.id

  permissions {
    actions = [
      "Microsoft.Insights/eventtypes/values/read",
      "Microsoft.Compute/virtualMachines/deallocate/action",
      "Microsoft.Compute/virtualMachines/restart/action",
      "Microsoft.Compute/virtualMachines/powerOff/action",
      "Microsoft.Compute/virtualMachines/start/action",
      "Microsoft.Compute/virtualMachines/read",
      "Microsoft.DesktopVirtualization/hostpools/read",
      "Microsoft.DesktopVirtualization/hostpools/write",
      "Microsoft.DesktopVirtualization/hostpools/sessionhosts/read",
      "Microsoft.DesktopVirtualization/hostpools/sessionhosts/write",
      "Microsoft.DesktopVirtualization/hostpools/sessionhosts/usersessions/delete",
      "Microsoft.DesktopVirtualization/hostpools/sessionhosts/usersessions/read",
      "Microsoft.DesktopVirtualization/hostpools/sessionhosts/usersessions/sendMessage/action",
      "Microsoft.DesktopVirtualization/hostpools/sessionhosts/usersessions/read"
    ]
    
    not_actions = []
  }
  
  assignable_scopes = [
    data.azurerm_resource_group.MAIN.id,
  ]
}

resource "azurerm_role_assignment" "MAIN" {
  name                             = random_uuid.MAIN.result
  scope                            = data.azurerm_resource_group.MAIN.id
  role_definition_id               = azurerm_role_definition.MAIN.role_definition_resource_id
  principal_id                     = data.azuread_service_principal.MAIN.id
  skip_service_principal_aad_check = true
}

resource "azurerm_virtual_desktop_scaling_plan" "MAIN" {
  name          = "DefaultScalingPlan"
  friendly_name = "AzureVirtualDesktop Scaling Plan"
  description   = "Example Azure Virtual Desktop Scaling Plan"
  time_zone     = "W. Europe Standard Time"

  host_pool {
    hostpool_id          = var.config.host_pool.id
    scaling_plan_enabled = true
  }

  schedule {
    name                                 = "Weekdays"
    days_of_week                         = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
    ramp_up_start_time                   = "06:00"
    ramp_up_load_balancing_algorithm     = "BreadthFirst"
    ramp_up_minimum_hosts_percent        = 20
    ramp_up_capacity_threshold_percent   = 20
    peak_start_time                      = "08:30"
    peak_load_balancing_algorithm        = "BreadthFirst"
    ramp_down_start_time                 = "16:30"
    ramp_down_load_balancing_algorithm   = "DepthFirst"
    ramp_down_minimum_hosts_percent      = 5
    ramp_down_force_logoff_users         = false
    ramp_down_wait_time_minutes          = 15
    ramp_down_notification_message       = "Please log off in the next 15 minutes..."
    ramp_down_capacity_threshold_percent = 5
    ramp_down_stop_hosts_when            = "ZeroSessions"
    off_peak_start_time                  = "18:00"
    off_peak_load_balancing_algorithm    = "DepthFirst"
  }
  
  location            = data.azurerm_resource_group.MAIN.location
  resource_group_name = data.azurerm_resource_group.MAIN.name
}
