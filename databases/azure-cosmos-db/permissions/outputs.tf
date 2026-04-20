output "cosmosdb_account_id" {
  description = "The ID of the Cosmos DB account"
  value       = data.azurerm_cosmosdb_account.cosmos_account.id
}

output "cosmosdb_account_endpoint" {
  description = "The endpoint of the Cosmos DB account"
  value       = data.azurerm_cosmosdb_account.cosmos_account.endpoint
}

output "cosmosdb_database_name" {
  description = "The name of the Cosmos DB SQL database"
  value       = data.azurerm_cosmosdb_sql_database.cosmos_database.name
}

output "app_principal_id" {
  description = "The principal ID of the web app's managed identity"
  value       = data.azurerm_linux_web_app.app.identity[0].principal_id
}

output "role_assignments" {
  description = "Map of container names to their role assignment details (or database-level when all_containers is true)"
  value = var.all_containers ? {
    database = {
      id           = azurerm_cosmosdb_sql_role_assignment.database_access[0].id
      access_level = local.database_access_level
      scope        = azurerm_cosmosdb_sql_role_assignment.database_access[0].scope
    }
    } : {
    for k, v in azurerm_cosmosdb_sql_role_assignment.container_access : k => {
      id           = v.id
      access_level = local.permissions_map[k]
      scope        = v.scope
    }
  }
}

output "assigned_containers" {
  description = "List of container names with assigned permissions (empty when all_containers is true)"
  value       = var.all_containers ? [] : keys(local.permissions_map)
}

output "database_endpoint" {
  value = data.azurerm_cosmosdb_account.cosmos_account.endpoint
}

output "database_name" {
  value = data.azurerm_cosmosdb_sql_database.cosmos_database.name
}

output "connection_info" {
  description = "Connection information for the application"
  value = {
    account_endpoint = data.azurerm_cosmosdb_account.cosmos_account.endpoint
    database_name    = data.azurerm_cosmosdb_sql_database.cosmos_database.name
    all_containers   = var.all_containers
    containers       = var.all_containers ? [] : keys(local.permissions_map)
  }
}

output "all_containers" {
  value = var.all_containers
}

output "target" {
  value = var.permissions
}