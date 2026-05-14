variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group where the MySQL Flexible Server will be created"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

variable "service_id" {
  description = "Nullplatform service ID (used for tagging)"
  type        = string
}

variable "server_name" {
  description = "Name for the MySQL Flexible Server (must be globally unique)"
  type        = string
}

variable "administrator_login" {
  description = "Admin username for the MySQL server"
  type        = string
  default     = "npadmin"
}

variable "sku_name" {
  description = "Server SKU. Format: {tier}_{compute_size}. B_=Burstable, GP_=General Purpose, MO_=Memory Optimized"
  type        = string
  default     = "B_Standard_B1ms"
}

variable "mysql_version" {
  description = "MySQL engine version"
  type        = string
  default     = "8.0.21"
}

variable "storage_size_gb" {
  description = "Storage size in GB (20–16384)"
  type        = number
  default     = 20
}

variable "backup_retention_days" {
  description = "Automated backup retention period in days (7–35)"
  type        = number
  default     = 7
}

variable "key_vault_name" {
  description = "Name of the existing Azure Key Vault where the admin password secret will be stored"
  type        = string
}
