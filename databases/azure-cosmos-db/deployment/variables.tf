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

variable "container_name" {
  description = "Name of the default container (deprecated, use containers array)"
  type        = string
  default     = ""
}

variable "partition_key_path" {
  description = "Partition key path (deprecated, use containers array)"
  type        = string
  default     = "/id"
}

variable "throughput" {
  description = "Throughput in RU/s (deprecated, use containers array)"
  type        = number
  default     = 400
}

variable "throughput_type" {
  description = "Throughput type: manual or autoscale (deprecated, use containers array)"
  type        = string
  default     = "autoscale"
}

variable "default_ttl" {
  description = "Default TTL in seconds (deprecated, use containers array)"
  type        = number
  default     = -1
}

variable "containers" {
  description = "List of containers to create"
  type = list(object({
    containerName  = string
    partitionKey   = string
    throughput     = optional(number, 400)
    throughputType = optional(string, "autoscale")
    defaultTtl     = optional(number, -1)
  }))
  default = []
}
