output "function_app_url" {
  value = azurerm_function_app.func.default_hostname
}

output "cosmosdb_endpoint" {
  value = azurerm_cosmosdb_account.cosmos.endpoint
}

output "blob_storage_account_name" {
  value = azurerm_storage_account.archive.name
}
