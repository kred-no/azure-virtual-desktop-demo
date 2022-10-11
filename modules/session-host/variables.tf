variable "config" {
  type = object({
    resource_group = object({
      name     = string
      location = string
    })

    host_pool = object({
      name  = string
    })
    
    registration_info = object({
      token = string
    })

    subnet = object({
      id = string
    })

    asg = object({
      id = string
    })
  })
}

variable "overrides" {
  type = object({
    prefix = optional(string, "Avd")
    size   = optional(string, "Standard_DS2_v2")
  })

  default = {}
}