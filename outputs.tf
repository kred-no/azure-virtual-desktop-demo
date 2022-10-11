output "login" {
  sensitive = true
  value     = one(module.USER_ACCESS.*.demo_credentials)
}