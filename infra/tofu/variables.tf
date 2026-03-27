variable "environment" {
  description = "Deployment environment name."
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be either dev or prod."
  }
}

variable "location" {
  description = "Azure region for all resources."
  type        = string
}

variable "name_prefix" {
  description = "Short prefix used in Azure resource names."
  type        = string
  default     = "neuro-san"
}

variable "github_owner" {
  description = "GitHub owner used for the GHCR image reference."
  type        = string
}

variable "image_name" {
  description = "Container image name in GHCR."
  type        = string
  default     = "neuro-san-studio"
}

variable "image_tag" {
  description = "Immutable image tag to deploy."
  type        = string
}

variable "ghcr_username" {
  description = "Username or org-scoped user for GHCR pulls."
  type        = string
}

variable "ghcr_token" {
  description = "Token with read:packages permission for GHCR pulls."
  type        = string
  sensitive   = true
}

variable "container_cpu" {
  description = "vCPU requested by the Neuro-san container."
  type        = number
  default     = 1
}

variable "container_memory" {
  description = "Memory requested by the Neuro-san container."
  type        = string
  default     = "2Gi"
}

variable "container_min_replicas" {
  description = "Minimum replica count for Container Apps."
  type        = number
  default     = 1
}

variable "container_max_replicas" {
  description = "Maximum replica count for Container Apps."
  type        = number
  default     = 3
}

variable "container_ingress_external_enabled" {
  description = "Whether the app is reachable from the public internet."
  type        = bool
  default     = true
}

variable "allowed_ingress_cidrs" {
  description = "Optional allow-list for Container App ingress. Empty means no IP restrictions."
  type        = list(string)
  default     = []
}

variable "log_level" {
  description = "Runtime log level for Neuro-san."
  type        = string
  default     = "info"
}

variable "log_retention_days" {
  description = "Log Analytics retention in days."
  type        = number
  default     = 30
}

variable "foundry_model_name" {
  description = "Azure AI Foundry model name to deploy."
  type        = string
  default     = "gpt-5.2"
}

variable "foundry_model_version" {
  description = "Optional Foundry model version. Leave empty to use the current regional default."
  type        = string
  default     = ""
}

variable "foundry_model_deployment_name" {
  description = "Deployment name exposed to Neuro-san."
  type        = string
  default     = "gpt-5.2"
}

variable "foundry_model_capacity" {
  description = "Deployment capacity in thousands of TPM."
  type        = number
  default     = 1
}

variable "foundry_model_sku_name" {
  description = "Azure OpenAI deployment SKU name."
  type        = string
  default     = "GlobalStandard"
}

variable "openai_api_version" {
  description = "API version used by Neuro-san for Azure OpenAI calls."
  type        = string
  default     = "2025-04-01-preview"
}

variable "tags" {
  description = "Additional tags applied to all resources."
  type        = map(string)
  default     = {}
}