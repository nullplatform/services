variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group where Cosmos DB account exists"
  type        = string
}

variable "cosmos_account_name" {
  description = "Cosmos DB account name"
  type        = string
}

variable "database_name" {
  description = "Cosmos DB database name"
  type        = string
}

variable "principal_id" {
  description = "Object ID of the service principal/managed identity to grant access"
  type        = string
}

variable "access_level" {
  description = "Access level: read or write"
  type        = string
  validation {
    condition     = contains(["read", "write"], var.access_level)
    error_message = "access_level must be 'read' or 'write'"
  }
}

variable "all_containers" {
  description = "If true, assign role to all containers in the database"
  type        = bool
  default     = false
}

variable "containers_to_apply_permissions" {
  description = "List of container names to assign permissions"
  type        = list(string)
  default     = []
}
