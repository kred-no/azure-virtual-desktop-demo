resource "azurerm_network_security_rule" "OUT_ALLOW" {
  for_each = {
    for idx,rule in var.outbound_allow: rule.name => rule
  }
  
  direction                  = "Outbound"
  access                     = "Allow"
  name                       = each.value["name"]
  priority                   = each.value["priority"]
  protocol                   = each.value["protocol"]
  source_port_range          = each.value["source_port_range"]
  destination_port_range     = each.value["destination_port_range"]
  destination_address_prefix = each.value["destination_address_prefix"]
  
  source_application_security_group_ids = [
    var.config.asg.id,
  ]

  resource_group_name         = var.config.rg.name
  network_security_group_name = var.config.nsg.name
}

/*resource "azurerm_network_security_rule" "RDS" {
  name                        = "AllowRDS"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_address_prefix       = "*"
  source_port_range           = "*"
  destination_port_range      = "3389"  

  // https://learn.microsoft.com/en-us/azure/virtual-network/service-tags-overview
  // https://learn.microsoft.com/en-us/azure/virtual-desktop/safe-url-list?tabs=azure

  destination_application_security_group_ids = [
    var.config.asg.id,
  ]

  resource_group_name         = var.config.rg.name
  network_security_group_name = var.config.nsg.name
}*/