################################################################################
# Required
################################################################################

variable "nrn" {
  description = "Nullplatform Resource Name (organization:account format)"
  type        = string
}

variable "np_api_key" {
  description = "Nullplatform API key for authentication"
  type        = string
  sensitive   = true
}

variable "tags_selectors" {
  description = "Map of tags used to select the agent that will handle this service's notification channel"
  type        = map(string)
}

variable "github_token" {
  description = "GitHub personal access token for fetching spec templates from nullplatform/services"
  type        = string
  sensitive   = true
  default     = null
}

################################################################################
# Repository
################################################################################

variable "git_repo" {
  description = "GitHub repository containing spec templates (org/repo format)"
  type        = string
  default     = "nullplatform/services"
}

variable "git_branch" {
  description = "Git branch to use when fetching spec templates"
  type        = string
  default     = "main"
}

variable "git_service_path" {
  description = "Path within the repository where install/specs/ is located"
  type        = string
  default     = "endpoint-exposer/install"
}

################################################################################
# Agent
################################################################################

variable "repo_path" {
  description = "Local path where the endpoint-exposer directory is located on the agent"
  type        = string
  default     = "/root/.np/nullplatform/services/endpoint-exposer"
}

################################################################################
# Service Definition
################################################################################

variable "service_name" {
  description = "Display name for the service in nullplatform"
  type        = string
  default     = "Endpoint Exposer"
}

variable "service_description" {
  description = "Description of the service"
  type        = string
  default     = "HTTP routing management via Kubernetes Gateway API"
}

################################################################################
# Overrides
################################################################################

variable "overrides_enabled" {
  description = "Append --overrides-path to the agent cmdline for local config overrides"
  type        = bool
  default     = false
}

variable "overrides_repo_path" {
  description = "Full path to the overrides directory on the agent"
  type        = string
  default     = null
}
