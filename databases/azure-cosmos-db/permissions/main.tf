# Get Cosmos DB account data
data "azurerm_cosmosdb_account" "this" {
  name                = var.cosmos_account_name
  resource_group_name = var.resource_group_name
}

# Get database data
data "azurerm_cosmosdb_sql_database" "this" {
  name                = var.database_name
  resource_group_name = var.resource_group_name
  account_name        = var.cosmos_account_name
}

# Create role assignment for each container
resource "azurerm_cosmosdb_sql_role_assignment" "container" {
  for_each = toset(local.containers_to_assign)

  resource_group_name = var.resource_group_name
  account_name        = var.cosmos_account_name
  role_definition_id  = "${data.azurerm_cosmosdb_account.this.id}/sqlRoleDefinitions/${local.role_id}"
  principal_id        = var.principal_id
  scope               = "${data.azurerm_cosmosdb_account.this.id}/dbs/${var.database_name}/colls/${each.value}"
}
