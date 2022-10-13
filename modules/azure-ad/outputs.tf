output "demo_users" {
  sensitive = true
  
  value = flatten([
    for user in azuread_user.DEMO_USER: {
      username = user.user_principal_name
      password = user.password
    }
  ])
}

output "demo_admins" {
  sensitive = true
  
  value = flatten([
    for user in azuread_user.DEMO_ADMIN: {
      username = user.user_principal_name
      password = user.password
    }
  ])
}
