output "namespace_name" {
  description = "Service Bus namespace name"
  value       = data.azurerm_servicebus_namespace.existing.name
}

output "namespace_id" {
  description = "Service Bus namespace resource ID"
  value       = data.azurerm_servicebus_namespace.existing.id
}

output "queues" {
  description = "Created queues"
  value = [
    for name, queue in azurerm_servicebus_queue.queues : {
      name = name
      id   = queue.id
    }
  ]
}

output "topics" {
  description = "Created topics with their subscriptions"
  value = [
    for name, topic in azurerm_servicebus_topic.topics : {
      name = name
      id   = topic.id
    }
  ]
}
