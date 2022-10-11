output "demo_credentials" {
  sensitive = true
  
  value = {
    url      = "https://client.wvd.microsoft.com/arm/webclient/"
    username = azuread_user.DEMO_USER.user_principal_name
    password = azuread_user.DEMO_USER.password
  }
}