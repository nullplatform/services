output "hostname" {
  description = "MySQL Flexible Server FQDN"
  value       = azurerm_mysql_flexible_server.server.fqdn
}

output "port" {
  description = "MySQL port (always 3306)"
  value       = 3306
}

output "administrator_login" {
  description = "Admin username"
  value       = azurerm_mysql_flexible_server.server.administrator_login
}

output "server_name" {
  description = "MySQL Flexible Server resource name"
  value       = azurerm_mysql_flexible_server.server.name
}

output "admin_password_secret_id" {
  description = "Azure Key Vault secret ID holding the admin password"
  value       = azurerm_key_vault_secret.admin_password.id
}
