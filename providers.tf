terraform {
  required_version = ">= 1.3.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
    }

    azuread = {
      source  = "hashicorp/azuread"
    }
  }
}

// See https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs
provider "azurerm" {
  features {}

  //tenant_id = var.azure.tenant_id
  //subscription_id = var.azure.subscription_id
}

// See https://registry.terraform.io/providers/hashicorp/azuread/latest/docs
provider "azuread" {
  //tenant_id = var.azure.tenant_id
}