terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
  }
}

# Enterprise subscription provider
provider "azurerm" {
  features {}
  subscription_id = var.ent_subscription_id
  tenant_id       = var.ent_tenant_id
  alias          = "enterprise"
}

# Personal subscription provider
provider "azurerm" {
  features {}
  subscription_id = var.per_subscription_id
  tenant_id       = var.per_tenant_id
  alias          = "personal"
}

provider "azuread" {
  tenant_id = var.ent_tenant_id
}