data "azurerm_servicebus_namespace" "existing" {
  name                = var.servicebus_namespace_name
  resource_group_name = var.resource_group_name
}

resource "azurerm_servicebus_queue" "queues" {
  for_each = { for q in var.queues : q.name => q }

  name         = each.value.name
  namespace_id = data.azurerm_servicebus_namespace.existing.id
}

resource "azurerm_servicebus_topic" "topics" {
  for_each = { for t in var.topics : t.name => t }

  name         = each.value.name
  namespace_id = data.azurerm_servicebus_namespace.existing.id
}

resource "azurerm_servicebus_subscription" "subscriptions" {
  for_each = {
    for item in flatten([
      for t in var.topics : [
        for s in t.subscriptions : {
          key        = "${t.name}--${s.name}"
          topic_name = t.name
          sub_name   = s.name
        }
      ]
    ]) : item.key => item
  }

  name               = each.value.sub_name
  topic_id           = azurerm_servicebus_topic.topics[each.value.topic_name].id
  max_delivery_count = 10
}
