# Output for SPN credentials (useful for configuration)
output "function_app_client_id" {
  value     = azuread_application.function_app.client_id
  sensitive = true
}

output "function_app_client_secret" {
  value     = azuread_service_principal_password.function_app.value
  sensitive = true
}