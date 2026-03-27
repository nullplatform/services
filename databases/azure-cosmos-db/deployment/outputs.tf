output "cosmos_endpoint" {
  description = "Cosmos DB account endpoint"
  value       = data.azurerm_cosmosdb_account.existing.endpoint
}

output "database_id" {
  description = "Database resource ID"
  value       = azurerm_cosmosdb_sql_database.database.id
}

output "database_name" {
  description = "Database name"
  value       = azurerm_cosmosdb_sql_database.database.name
}

output "containers" {
  description = "Created containers"
  value = [
    for name, container in azurerm_cosmosdb_sql_container.containers : {
      container_name = name
      id             = container.id
      partition_key  = container.partition_key_paths[0]
    }
  ]
}