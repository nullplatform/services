output "namespace_id" {
  description = "Service Bus namespace resource ID"
  value       = data.azurerm_servicebus_namespace.existing.id
}

output "namespace_name" {
  description = "Service Bus namespace name"
  value       = data.azurerm_servicebus_namespace.existing.name
}

output "app_principal_id" {
  description = "The principal ID of the app's managed identity"
  value       = data.azurerm_linux_web_app.app.identity[0].principal_id
}

output "role_assignment_id" {
  description = "Role assignment resource ID"
  value       = azurerm_role_assignment.servicebus_access.id
}

output "access_level" {
  description = "Granted access level"
  value       = var.access_level
}
