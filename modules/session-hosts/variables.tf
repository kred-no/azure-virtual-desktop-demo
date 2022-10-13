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

    nsg = object({
      id = string
    })

    asg = object({
      id = string
    })
  })
}

variable "overrides" {
  type = object({
    prefix          = optional(string, "SH")
    instances       = optional(number, 1)
    size            = optional(string, "Standard_DS2_v2")
    priority        = optional(string, "Regular")
    eviction_policy = optional(string)
    admin_username  = optional(string, "superman")
    admin_password  = optional(string, "Cl@rkK3nt")
    image_publisher = optional(string, "MicrosoftWindowsDesktop")
    image_offer     = optional(string, "office-365") //"Windows-11"
    image_sku       = optional(string, "win11-22h2-avd-m365") // "win11-22h2-avd"
    image_version   = optional(string, "latest")
  })

  default = {}
}