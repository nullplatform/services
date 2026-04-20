variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group where Cosmos DB account exists"
  type        = string
}

variable "cosmos_account_name" {
  description = "Existing Cosmos DB account name"
  type        = string
}

variable "database_name" {
  description = "Name of the SQL database to create"
  type        = string
}

variable "throughput" {
  description = "Database throughput in RU/s"
  type        = number
  default     = 1000
}

variable "throughput_type" {
  description = "Throughput type: manual or autoscale"
  type        = string
  default     = "autoscale"
}

variable "containers" {
  description = "List of containers to create"
  type = list(object({
    container_name = string
    partition_key  = string
  }))
}
