variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group where the Service Bus namespace exists"
  type        = string
}

variable "servicebus_namespace_name" {
  description = "Existing Service Bus namespace name"
  type        = string
}

variable "queues" {
  description = "List of queues to create in the namespace"
  type = list(object({
    name = string
  }))
  default = []
}

variable "topics" {
  description = "List of topics to create with their subscriptions"
  type = list(object({
    name = string
    subscriptions = list(object({
      name = string
    }))
  }))
  default = []
}
