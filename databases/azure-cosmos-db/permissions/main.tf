data "azurerm_cosmosdb_account" "cosmos_account" {
  name                = var.account_name
  resource_group_name = var.resource_group_name
}

data "azurerm_cosmosdb_sql_database" "cosmos_database" {
  name                = var.database_name
  resource_group_name = var.resource_group_name
  account_name        = data.azurerm_cosmosdb_account.cosmos_account.name
}

data "azurerm_linux_web_app" "app" {
  name                = var.app_name
  resource_group_name = var.resource_group_name
}

resource "azurerm_cosmosdb_sql_role_assignment" "app_access" {
  for_each = local.permissions_map

  resource_group_name = data.azurerm_cosmosdb_account.cosmos_account.resource_group_name
  account_name        = data.azurerm_cosmosdb_account.cosmos_account.name
  role_definition_id  = "${data.azurerm_cosmosdb_account.cosmos_account.id}/sqlRoleDefinitions/${local.role_definitions[each.value]}"
  principal_id        = data.azurerm_linux_web_app.app.identity[0].principal_id
  scope               = "${data.azurerm_cosmosdb_account.cosmos_account.id}/dbs/${data.azurerm_cosmosdb_sql_database.cosmos_database.name}/colls/${each.key}"
}