//////////////////////////////////
// External Resources
//////////////////////////////////

data "azuread_client_config" "CURRENT" {}

data "azuread_domains" "CURRENT" {
  only_initial = true
}

data "azurerm_role_definition" "DESKTOP_USER" { 
  name = "Desktop Virtualization User"
}

data "azurerm_role_definition" "VM_USER" {
  name = "Virtual Machine User Login"
}

//////////////////////////////////
// Azure AD | Role Assignments
//////////////////////////////////

// Create a new AAD Group for AVD Users
resource "azuread_group" "DESKTOP_USER" {
  display_name       = "AvdUsers"
  security_enabled   = true
  owners             = [data.azuread_client_config.CURRENT.object_id]
  
  // BUG: https://github.com/hashicorp/terraform-provider-azuread/issues/624#issuecomment-942280276  
  lifecycle {
    ignore_changes = [owners]
  }
}

resource "azurerm_role_assignment" "DESKTOP_USER" {
  scope              = var.config.resource_group.id
  role_definition_id = data.azurerm_role_definition.DESKTOP_USER.id
  principal_id       = azuread_group.DESKTOP_USER.id
}

resource "azurerm_role_assignment" "VM_LOGIN" {
  scope              = var.config.resource_group.id
  role_definition_id = data.azurerm_role_definition.VM_USER.id
  principal_id       = azuread_group.DESKTOP_USER.id
}

//////////////////////////////////
// Azure AD | Add Users
//////////////////////////////////

data "azuread_user" "DESKTOP_USER" {
  for_each = var.aad_desktop_users

  user_principal_name = format("%s", each.key) // Why?
}

resource "azuread_group_member" "MAIN" {
  for_each = data.azuread_user.DESKTOP_USER

  group_object_id  = azuread_group.DESKTOP_USER.id
  member_object_id = each.value["id"]
}

//////////////////////////////////
// Azure AD | Demo User(s)
//////////////////////////////////

// Create new demo-user
resource "azuread_user" "DEMO_USER" {
  user_principal_name = join("@", ["avd.demo", data.azuread_domains.CURRENT.domains.0.domain_name])
  display_name        = "AVD Demo User"
  mail_nickname       = "avdd"
  password            = "S3cretP@ssword"
}

resource "azuread_group_member" "DEMO_USER" {
  group_object_id  = azuread_group.DESKTOP_USER.id
  member_object_id = azuread_user.DEMO_USER.id
}
