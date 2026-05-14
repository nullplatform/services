variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "mysql_host" {
  description = "MySQL Flexible Server FQDN"
  type        = string
}

variable "mysql_port" {
  description = "MySQL port"
  type        = number
  default     = 3306
}

variable "admin_username" {
  description = "MySQL admin username"
  type        = string
}

variable "admin_password" {
  description = "MySQL admin password"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "Name of the MySQL database to create for this link"
  type        = string
}

variable "link_username" {
  description = "Per-link MySQL username to create"
  type        = string
}

variable "access_level" {
  description = "Access level: read, write, or read-write"
  type        = string
  default     = "read-write"

  validation {
    condition     = contains(["read", "write", "read-write"], var.access_level)
    error_message = "access_level must be one of: read, write, read-write"
  }
}
