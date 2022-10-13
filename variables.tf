//////////////////////////////////
// Required
//////////////////////////////////
# Nothing here!

//////////////////////////////////
// Optional
//////////////////////////////////

variable "prefix" {
  type    = string
  default = "TFAVD"
}

variable "location" {
  type    = string
  default = "NorthEurope"
}

variable "tags" {
  type    = map(string)
  
  default = {
    environment = "Demo"
    application = "AzureVirtualDesktop"
  }
}

variable "flags" {
  type = object({
    user_access = optional(bool, true)
    autoscaler  = optional(bool, false)
    nsgrules    = optional(bool, false)
  })

  default = {}
}

variable "virtual_network" {
  type = object({
    name          = string
    address_space = set(string)
  })
  
  default = {
    name          = "VirtualDesktop"
    address_space = ["192.168.0.0/24"]
  }
}

variable "subnet" {
  type = object({
    name             = string
    address_prefixes = set(string)
  })
  
  default = {
    name             = "SessionPool-VD"
    address_prefixes = ["192.168.0.0/27"]
  }
}

variable "host_pool" {
  type = object({
    name                 = optional(string, "Default")
    type                 = optional(string, "Pooled")
    load_balancer_type   = optional(string, "BreadthFirst")
    max_sessions_allowed = optional(number, 3)
    validate_environment = optional(bool, false)
    start_vm_on_connect  = optional(bool, true)
  })
  
  default = {}
}

variable "session_hosts" {
  type    = number
  default = 1
}

variable "aad_users" {
  description = <<-HEREDOC
  List of user with access to logging on the deployed
  AVD solution.
  NOTE: External users at present not working (AAD).
  HEREDOC

  type    = set(string)
  default = []
}

variable "remote_applications" {
  description = <<-HEREDOC
  List of applications to expose as RemoteApps
  for the AVD solution.
  HEREDOC
  type = set(object({
    name           = string
    path           = string
    icon_path      = string
    friendly_name  = optional(string)
    description    = optional(string)
    icon_index     = optional(number, 0)
    show_in_portal = optional(bool, false)
    cli_policy     = optional(string, "DoNotAllow")
    cli_arguments  = optional(string)
  }))
  
  default = [{
  name           = "ResourceMonitor"
  path           = "C:\\Windows\\system32\\perfmon.exe"
  icon_path      = "C:\\Windows\\system32\\wdc.dll"
  friendly_name  = "Resource Monitor (Admin)"
  icon_index     = -108
  show_in_portal = false
  cli_policy     = "Require"
  cli_arguments  = "/res"
},{
  name           = "Outlook"
  friendly_name  = "Outlook"
  path           = "C:\\Program Files\\Microsoft Office\\root\\Office16\\OUTLOOK.EXE"
  icon_path      = "C:\\Program Files\\Microsoft Office\\Root\\VFS\\Windows\\Installer\\{90160000-000F-0000-1000-0000000FF1CE}\\outicon.exe"
  icon_index     = 0
  show_in_portal = false
  cli_policy     = "DoNotAllow"
}]
}
