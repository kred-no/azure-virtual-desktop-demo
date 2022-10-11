variable "config" {
  type = object({
    resource_group = object({
      name = string
      location = string
    })

    host_pool = object({
      id = string
    })
  })
}
