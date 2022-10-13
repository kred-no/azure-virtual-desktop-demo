variable "config" {
  type = object({
    resource_group = object({
      name     = string
      location = string
      id       = string
    })
  })

}

variable "aad_users" {
  type    = set(string)
  default = []
}

variable "aad_admins" {
  type    = set(string)
  default = []
}

variable "demo_users" {
  type    = set(string)
  
  default = [
    "avd1",
    "avd2",
  ]
}

variable "demo_admins" {
  type    = set(string)
  
  default = [
    "avdadm",
  ]
}

