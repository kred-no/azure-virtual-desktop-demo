variable "prefix" {
  type    = string
  
  default = "tf-wvd"
}

variable "location" {
  type    = string
  
  default = "NorthEurope"
}

variable "tags" {
  type    = map(string)
  
  default = {
    service = "VirtualDesktops"
  }
}

variable "virtual_network" {
  type = object({
    name          = string
    address_space = set(string)
  })
  
  default = {
    name          = "AzureVirtualDesktopDemo"
    address_space = ["192.168.0.0/24"]
  }
}

variable "subnet" {
  type = object({
    name             = string
    address_prefixes = set(string)
  })
  
  default = {
    name             = "SessionHosts"
    address_prefixes = ["192.168.0.0/27"]
  }
}

variable "host_pool" {
  type = object({
    name                 = string
    type                 = optional(string, "Pooled")
    load_balancer_type   = optional(string, "DepthFirst")
    max_sessions_allowed = optional(number, 5)
    validate_environment = optional(bool, false)
  })
  
  default = {
    name = "Standard"
  }
}

variable "aad_users" {
  type    = set(string)
  default = []
}