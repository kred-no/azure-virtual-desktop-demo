variable "config" {
  type = object({
    resource_group = object({
      name     = string
      location = string
      id       = string
    })
  })

}

variable "aad_desktop_users" {
  type    = set(string)
  default = []
}

