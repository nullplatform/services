variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group where the Service Bus namespace exists"
  type        = string
}

variable "servicebus_namespace_name" {
  description = "Service Bus namespace name"
  type        = string
}

variable "app_name" {
  description = "Azure App Service name (the NP scope consuming this service)"
  type        = string
}

variable "app_resource_group" {
  description = "Resource group where the Azure App Service lives"
  type        = string
}

variable "access_level" {
  description = "Access level to grant: sender, receiver, or owner"
  type        = string
  default     = "receiver"

  validation {
    condition     = contains(["sender", "receiver", "owner"], var.access_level)
    error_message = "access_level must be one of: sender, receiver, owner."
  }
}
