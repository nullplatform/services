data "azurerm_cosmosdb_account" "existing" {
  name                = var.cosmos_account_name
  resource_group_name = var.resource_group_name
}

resource "azurerm_cosmosdb_sql_database" "database" {
  name                = var.database_name
  resource_group_name = var.resource_group_name
  account_name        = data.azurerm_cosmosdb_account.existing.name

  dynamic "autoscale_settings" {
    for_each = var.throughput_type == "autoscale" ? [1] : []
    content {
      max_throughput = var.throughput
    }
  }

  throughput = var.throughput_type == "manual" ? var.throughput : null
}

resource "azurerm_cosmosdb_sql_container" "containers" {
  for_each = { for c in var.containers : c.containerName => c }

  name                  = each.value.containerName
  resource_group_name   = var.resource_group_name
  account_name          = data.azurerm_cosmosdb_account.existing.name
  database_name         = azurerm_cosmosdb_sql_database.database.name
  partition_key_paths   = [startswith(each.value.partitionKey, "/") ? each.value.partitionKey : "/${each.value.partitionKey}"]
  partition_key_version = 2

  indexing_policy {
    indexing_mode = "consistent"

    included_path {
      path = "/*"
    }

    excluded_path {
      path = "/_etag/?"
    }
  }
}
