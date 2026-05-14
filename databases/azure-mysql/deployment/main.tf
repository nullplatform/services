resource "random_password" "admin" {
  length  = 20
  special = false
}

resource "azurerm_mysql_flexible_server" "server" {
  name                   = var.server_name
  resource_group_name    = var.resource_group_name
  location               = var.location
  administrator_login    = var.administrator_login
  administrator_password = random_password.admin.result
  backup_retention_days  = var.backup_retention_days
  sku_name               = var.sku_name
  version                = var.mysql_version

  storage {
    size_gb = var.storage_size_gb
  }

  tags = {
    managed-by = "nullplatform"
    service-id = var.service_id
  }
}

# Allow connections from other Azure services (0.0.0.0 → 0.0.0.0 is the Azure special rule)
resource "azurerm_mysql_flexible_server_firewall_rule" "azure_services" {
  name                = "allow-azure-services"
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_flexible_server.server.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

data "azurerm_key_vault" "kv" {
  name                = var.key_vault_name
  resource_group_name = var.resource_group_name
}

resource "azurerm_key_vault_secret" "admin_password" {
  name         = "mysql-${var.server_name}-admin"
  value        = random_password.admin.result
  key_vault_id = data.azurerm_key_vault.kv.id

  tags = {
    managed-by = "nullplatform"
    service-id = var.service_id
  }
}
