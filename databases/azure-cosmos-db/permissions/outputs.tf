output "role_assignments" {
  description = "Map of container names to their role assignment IDs"
  value = {
    for name, assignment in azurerm_cosmosdb_sql_role_assignment.container :
    name => assignment.id
  }
}

output "access_level" {
  description = "The access level that was assigned"
  value       = var.access_level
}

output "principal_id" {
  description = "The principal ID that was granted access"
  value       = var.principal_id
}

output "containers" {
  description = "List of containers that were granted access"
  value       = local.containers_to_assign
}
