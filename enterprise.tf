# Enterprise Resource Group
data "azurerm_resource_group" "enterprise" {
  provider = azurerm.enterprise
  name     = var.ent_resource_group
}

# Enterprise VNET
resource "azurerm_virtual_network" "enterprise" {
  provider            = azurerm.enterprise
  name               = var.ent_vnet_name
  address_space      = ["10.0.0.0/16"]
  location           = data.azurerm_resource_group.enterprise.location
  resource_group_name = data.azurerm_resource_group.enterprise.name
}

# Default subnet
resource "azurerm_subnet" "default" {
  provider             = azurerm.enterprise
  name                = "default"
  resource_group_name  = data.azurerm_resource_group.enterprise.name
  virtual_network_name = azurerm_virtual_network.enterprise.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Service Principal for Function App
resource "azuread_application" "function_app" {
  display_name = var.ent_function_app_spn_name
}

resource "azuread_service_principal" "function_app" {
  client_id = azuread_application.function_app.client_id
}

resource "azuread_service_principal_password" "function_app" {
  service_principal_id = azuread_service_principal.function_app.id
}

# Key Vault
resource "azurerm_key_vault" "enterprise" {
  provider                   = azurerm.enterprise
  name                      = var.ent_akv_name
  location                  = data.azurerm_resource_group.enterprise.location
  resource_group_name       = data.azurerm_resource_group.enterprise.name
  tenant_id                 = var.ent_tenant_id
  sku_name                  = "standard"
  purge_protection_enabled  = false

  network_acls {
    bypass                     = "None"
    default_action             = "Deny"
    ip_rules                   = ["127.0.0.1"]
    virtual_network_subnet_ids = [azurerm_subnet.function.id]
  }
}

# Key Vault Access Policy for Service Principal
resource "azurerm_key_vault_access_policy" "spn" {
  provider     = azurerm.enterprise
  key_vault_id = azurerm_key_vault.enterprise.id
  tenant_id    = var.ent_tenant_id
  object_id    = azuread_service_principal.function_app.object_id

  secret_permissions = [
    "Get",
    "List"
  ]
}

# Data source to get Function App's managed identity
data "azurerm_linux_function_app" "personal" {
  provider            = azurerm.personal
  name                = var.per_function_app_name
  resource_group_name = var.per_resource_group
  depends_on          = [azurerm_linux_function_app.personal]
}

# Key Vault Access Policy for Function App's Managed Identity
resource "azurerm_key_vault_access_policy" "function_mi" {
  provider     = azurerm.enterprise
  key_vault_id = azurerm_key_vault.enterprise.id
  tenant_id    = var.ent_tenant_id
  object_id    = data.azurerm_linux_function_app.personal.identity[0].principal_id

  secret_permissions = [
    "Get",
    "List"
  ]

  depends_on = [azurerm_linux_function_app.personal]
}

# Key Vault Access Policy for current user
resource "azurerm_key_vault_access_policy" "current_user" {
  provider     = azurerm.enterprise
  key_vault_id = azurerm_key_vault.enterprise.id
  tenant_id    = var.ent_tenant_id
  object_id    = "6adeb5ed-b32f-4c3d-8a5b-0535716ee060"

  secret_permissions = [
    "Get",
    "List",
    "Set",
    "Delete",
    "Recover",
    "Backup",
    "Restore",
    "Purge"
  ]
}

# Example secret
resource "azurerm_key_vault_secret" "example" {
  provider     = azurerm.enterprise
  name         = "example-secret"
  value        = "Hello from Enterprise Key Vault!"
  key_vault_id = azurerm_key_vault.enterprise.id
  depends_on   = [azurerm_key_vault_access_policy.current_user]
}
