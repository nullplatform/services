variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "resource_group_name" {
  type = string
}

variable "cosmos_account_name" {
  type = string
}

variable "database_name" {
  type = string
}

variable "app_name" {
  type = string
}

variable "permissions" {
  type = list(object({
    container    = string
    access_level = string
  }))
  default = []
}

variable "all_containers" {
  type = bool
}
