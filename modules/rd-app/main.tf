//////////////////////////////////
// Virtual Desktop Application
//////////////////////////////////
// https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_desktop_application

resource "azurerm_virtual_desktop_application" "MAIN" {
  name                         = var.config.name
  friendly_name                = var.config.friendly_name
  description                  = var.config.description
  path                         = var.config.path
  icon_path                    = var.config.icon_path
  icon_index                   = var.config.icon_index
  command_line_argument_policy = var.config.cli_policy
  command_line_arguments       = var.config.cli_arguments
  show_in_portal               = var.config.show_in_portal
  application_group_id         = var.application_group.id
}

