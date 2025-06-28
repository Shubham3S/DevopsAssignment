provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_storage_account" "archive" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "archive_container" {
  name                  = "archive"
  storage_account_name  = azurerm_storage_account.archive.name
  container_access_type = "private"
}

resource "azurerm_cosmosdb_account" "cosmos" {
  name                = var.cosmos_account_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = azurerm_resource_group.main.location
    failover_priority = 0
  }
}

resource "azurerm_cosmosdb_sql_database" "billing" {
  name                = "billing-db"
  resource_group_name = azurerm_resource_group.main.name
  account_name        = azurerm_cosmosdb_account.cosmos.name
}

resource "azurerm_cosmosdb_sql_container" "billing_records" {
  name                = "BillingRecords"
  resource_group_name = azurerm_resource_group.main.name
  account_name        = azurerm_cosmosdb_account.cosmos.name
  database_name       = azurerm_cosmosdb_sql_database.billing.name
  partition_key_path  = "/billingId"

  indexing_policy {
    indexing_mode = "consistent"
  }
}

resource "azurerm_application_insights" "appinsights" {
  name                = "${var.prefix}-insights"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  application_type    = "web"
}

resource "azurerm_app_service_plan" "plan" {
  name                = "${var.prefix}-plan"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  kind                = "FunctionApp"
  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}

resource "azurerm_function_app" "func" {
  name                       = "${var.prefix}-func"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  app_service_plan_id        = azurerm_app_service_plan.plan.id
  storage_account_name       = azurerm_storage_account.archive.name
  storage_account_access_key = azurerm_storage_account.archive.primary_access_key
  os_type                    = "linux"
  version                    = "~4"

  app_settings = {
    FUNCTIONS_WORKER_RUNTIME = "python"
    APPINSIGHTS_INSTRUMENTATIONKEY = azurerm_application_insights.appinsights.instrumentation_key
    COSMOS_CONN_STR = azurerm_cosmosdb_account.cosmos.connection_strings[0]
    BLOB_CONN_STR   = azurerm_storage_account.archive.primary_connection_string
  }

  site_config {
    linux_fx_version = "Python|3.11"
  }
}
