variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "resource_group_name" {
  type = string
}

variable "account_name" {
  type = string
}

variable "database_name" {
  type = string
}

variable "app_name" {
  type = string
}

variable "permissions" {
  type = string
  # JSON array: [{"container_name": "container1", "access_level": "read"}, ...]
}