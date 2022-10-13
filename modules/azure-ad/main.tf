//////////////////////////////////
// External Resources
//////////////////////////////////

data "azuread_client_config" "CURRENT" {}

data "azuread_domains" "CURRENT" {
  only_initial = true
}

//////////////////////////////////
// AzureAD | Create Group(s)
//////////////////////////////////

// Create a new AAD Group for AVD Users
resource "azuread_group" "USERS" {
  display_name       = "AVD Users"
  security_enabled   = true
  owners             = [data.azuread_client_config.CURRENT.object_id]
  
  // BUG: https://github.com/hashicorp/terraform-provider-azuread/issues/624#issuecomment-942280276  
  lifecycle {
    ignore_changes = [owners]
  }
}

resource "azuread_group" "ADMINS" {
  display_name       = "AVD Admins"
  security_enabled   = true
  owners             = [data.azuread_client_config.CURRENT.object_id]
  
  // BUG: https://github.com/hashicorp/terraform-provider-azuread/issues/624#issuecomment-942280276  
  lifecycle {
    ignore_changes = [owners]
  }
}

//////////////////////////////////
// AzureAD | Role Assignments
//////////////////////////////////
// See https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles

resource "azurerm_role_assignment" "VIRTUAL_DESKTOP_USER" {
  scope                = var.config.resource_group.id
  role_definition_name = "Desktop Virtualization User" // Builtin
  principal_id         = azuread_group.USERS.id
}

resource "azurerm_role_assignment" "VIRTUAL_DESKTOP_ADMIN" {
  scope                = var.config.resource_group.id
  role_definition_name = "Desktop Virtualization User" // Builtin
  principal_id         = azuread_group.ADMINS.id
}

resource "azurerm_role_assignment" "VM_LOGIN_USER" {
  scope                = var.config.resource_group.id
  role_definition_name = "Virtual Machine User Login" // Builtin
  principal_id         = azuread_group.USERS.id
}

resource "azurerm_role_assignment" "VM_LOGIN_ADMIN" {
  scope                = var.config.resource_group.id
  role_definition_name = "Virtual Machine Administrator Login" // Builtin
  principal_id         = azuread_group.ADMINS.id
}

//////////////////////////////////
// AzureAD | AAD User(s)
//////////////////////////////////

data "azuread_user" "AAD_USER" {
  for_each            = var.aad_users
  user_principal_name = format("%s", each.key) // Why?
}

data "azuread_user" "AAD_ADMIN" {
  for_each            = var.aad_admins
  user_principal_name = format("%s", each.key) // Why?
}

resource "azuread_group_member" "AAD_USER" {
  for_each         = data.azuread_user.AAD_USER
  group_object_id  = azuread_group.USERS.id
  member_object_id = each.value["id"]
}

resource "azuread_group_member" "AAD_ADMIN" {
  for_each         = data.azuread_user.AAD_ADMIN
  group_object_id  = azuread_group.ADMINS.id
  member_object_id = each.value["id"]
}

//////////////////////////////////
// AzureAD | Demo User(s)
//////////////////////////////////

// Create new demo-user(s)
resource "azuread_user" "DEMO_USER" {
  for_each                = var.demo_users
  user_principal_name     = join("@", [each.key, data.azuread_domains.CURRENT.domains.0.domain_name])
  display_name            = format("%s", each.key)
  disable_strong_password = true
  password                = "P@ssw0rd"
}

resource "azuread_user" "DEMO_ADMIN" {
  for_each                = var.demo_admins
  user_principal_name     = join("@", [each.key, data.azuread_domains.CURRENT.domains.0.domain_name])
  display_name            = format("%s", each.key)
  disable_strong_password = true
  password                = "SecretP@ssw0rd"
}

resource "azuread_group_member" "DEMO_USER" {
  for_each         = azuread_user.DEMO_USER
  group_object_id  = azuread_group.USERS.id
  member_object_id = each.value["id"]
}

resource "azuread_group_member" "DEMO_ADMIN" {
  for_each         = azuread_user.DEMO_ADMIN
  group_object_id  = azuread_group.ADMINS.id
  member_object_id = each.value["id"]
}
