output "db_username" {
  description = "Per-link MySQL username"
  value       = mysql_user.app.user
}

output "db_password" {
  description = "Per-link MySQL password"
  value       = random_password.user.result
  sensitive   = true
}

output "database_name" {
  description = "MySQL database name"
  value       = mysql_database.db.name
}

output "hostname" {
  description = "MySQL server FQDN (passthrough for convenience)"
  value       = var.mysql_host
}

output "port" {
  description = "MySQL port (passthrough for convenience)"
  value       = var.mysql_port
}
