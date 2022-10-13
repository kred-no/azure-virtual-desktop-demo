//////////////////////////////////
// Required
//////////////////////////////////

variable "application_group" {
  type = object({
    id = string
  })
}

variable "config" {
  type = object({
    name      = string
    path      = string
    icon_path = string
    
    friendly_name  = optional(string)
    description    = optional(string)
    icon_index     = optional(number, 0)
    show_in_portal = optional(bool, false)
    cli_policy     = optional(string, "DoNotAllow")
    cli_arguments  = optional(string)
  })
}
