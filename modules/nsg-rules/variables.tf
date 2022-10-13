variable "config" {
  type = object({
    rg = object({
      name = string
    })

    nsg = object({
      name = string
    })
    
    asg = object({
      id = string
    })
  })
}

// See
//   https://learn.microsoft.com/en-us/azure/firewall/protect-azure-virtual-desktop?tabs=azure
//   https://learn.microsoft.com/en-us/azure/virtual-network/service-tags-overview
// NOTE: FQDN's not supported for NSG-rules (requires firewall)
variable "outbound_allow" {
  type = set(object({
    name                       = string
    priority                   = number
    protocol                   = optional(string, "Tcp")
    source_port_range          = optional(string, "*")
    destination_port_range     = optional(string, "*")
    destination_address_prefix = optional(string, "*")
  }))

  default = [{
    name                       = "AzurePlatformIMDS"
    priority                   = 1001
    destination_port_range     = "80"
    destination_address_prefix = "AzurePlatformIMDS" //"169.254.169.254"
  }, {
    name                       = "AzureVirtualHost"
    priority                   = 1002
    destination_port_range     = "80"
    destination_address_prefix = "AzureLoadBalancer" // "168.63.129.16"
  }, {
    name                       = "WindowsVirtualDesktop"
    priority                   = 1003
    destination_port_range     = "443"
    destination_address_prefix = "WindowsVirtualDesktop"
  }, {
    name                       = "AzureFrontDoorFE"
    priority                   = 1004
    destination_port_range     = "443"
    destination_address_prefix = "AzureFrontDoor.Frontend"
  }, {
    name                       = "AzureMonitor"
    priority                   = 1005
    destination_port_range     = "443"
    destination_address_prefix = "AzureMonitor"
  }, {
    name                       = "DNS"
    priority                   = 1006
    protocol                   = "*"
    destination_port_range     = "53"
    destination_address_prefix = "*"
  }/*{
    name                       = "MicrosoftLogin"
    priority                   = 1007
    destination_port_range     = "443"
    destination_address_prefix = "login.microsoftonline.com"
  }, {
    name                       = "AzureKMSActivation"
    priority                   = 1008
    destination_port_range     = "1688"
    destination_address_prefix = "azkms.core.windows.net"
  }, {
    name                       = "KMSActivation"
    priority                   = 1009
    destination_port_range     = "1688"
    destination_address_prefix = "kms.core.windows.net"
  }, {
    name                       = "AzureAgentUpdates"
    priority                   = 1010
    destination_port_range     = "443"
    destination_address_prefix = "mrsglobalsteus2prod.blob.core.windows.net"
  }, {
    name                       = "AzureVdResources"
    priority                   = 1011
    destination_port_range     = "443"
    destination_address_prefix = "wvdportalstorageblob.blob.core.windows.net"
  }, {
    name                       = "AzureCertificateCRL"
    priority                   = 1012
    destination_port_range     = "80"
    destination_address_prefix = "oneocsp.microsoft.com"
  }, {
    name                       = "Microsoft"
    priority                   = 1013
    destination_port_range     = "80"
    destination_address_prefix = "www.microsoft.com"
  }*/]
}