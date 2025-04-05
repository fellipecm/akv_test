# Personal Resource Group
data "azurerm_resource_group" "personal" {
  provider = azurerm.personal
  name     = var.per_resource_group
}

# Personal VNET
resource "azurerm_virtual_network" "personal" {
  provider            = azurerm.personal
  name               = var.per_vnet_name
  address_space      = ["172.16.0.0/16"]
  location           = data.azurerm_resource_group.personal.location
  resource_group_name = data.azurerm_resource_group.personal.name
}

# Subnet for Function App
resource "azurerm_subnet" "function" {
  provider             = azurerm.personal
  name                 = "function-subnet"
  resource_group_name  = data.azurerm_resource_group.personal.name
  virtual_network_name = azurerm_virtual_network.personal.name
  address_prefixes     = ["172.16.1.0/24"]
  
  service_endpoints    = ["Microsoft.KeyVault"]  # Add KeyVault service endpoint
  
  delegation {
    name = "function-delegation"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

# Storage Account for Function App
resource "azurerm_storage_account" "function" {
  provider                 = azurerm.personal
  name                    = replace(lower(var.per_function_app_name), "-", "")
  resource_group_name     = data.azurerm_resource_group.personal.name
  location                = data.azurerm_resource_group.personal.location
  account_tier            = "Standard"
  account_replication_type = "LRS"
}

# App Service Plan
resource "azurerm_service_plan" "function" {
  provider            = azurerm.personal
  name               = "${var.per_function_app_name}-plan"
  resource_group_name = data.azurerm_resource_group.personal.name
  location           = data.azurerm_resource_group.personal.location
  os_type            = "Linux"
  sku_name           = "EP1"
}

# Function App
resource "azurerm_linux_function_app" "personal" {
  provider                    = azurerm.personal
  name                       = var.per_function_app_name
  resource_group_name        = data.azurerm_resource_group.personal.name
  location                   = data.azurerm_resource_group.personal.location
  service_plan_id            = azurerm_service_plan.function.id
  storage_account_name       = azurerm_storage_account.function.name
  storage_account_access_key = azurerm_storage_account.function.primary_access_key

  identity {
    type = "SystemAssigned"
  }

  app_settings = {
    FUNCTIONS_WORKER_RUNTIME = "python"
    AZURE_CLIENT_ID         = azuread_application.function_app.client_id
    AZURE_CLIENT_SECRET     = azuread_service_principal_password.function_app.value
    AZURE_TENANT_ID         = var.ent_tenant_id
    KEY_VAULT_NAME          = var.ent_akv_name
  }

  site_config {
    application_stack {
      python_version = "3.11"
    }
    vnet_route_all_enabled = true
  }

  virtual_network_subnet_id = azurerm_subnet.function.id
}