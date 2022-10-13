output "login" {
  sensitive = true
  value = flatten([
    concat(
      module.USER_ACCESS.*.demo_users,
      module.USER_ACCESS.*.demo_admins,
    )
  ])
}

output "azure_url" {
  sensitive = false
  value     = "https://client.wvd.microsoft.com/arm/webclient/"
}
