data "azurerm_servicebus_namespace" "existing" {
  name                = var.servicebus_namespace_name
  resource_group_name = var.resource_group_name
}

data "azurerm_linux_web_app" "app" {
  name                = var.app_name
  resource_group_name = var.app_resource_group
}

resource "azurerm_role_assignment" "servicebus_access" {
  scope                = data.azurerm_servicebus_namespace.existing.id
  role_definition_name = local.role_names[var.access_level]
  principal_id         = data.azurerm_linux_web_app.app.identity[0].principal_id
}
