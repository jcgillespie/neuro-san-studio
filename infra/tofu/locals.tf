locals {
  normalized_prefix = substr(replace(lower(var.name_prefix), "/[^a-z0-9]/", ""), 0, 10)
  suffix_seed       = "${local.normalized_prefix}${var.environment}${random_string.suffix.result}"

  resource_group_name         = substr("rg-${local.suffix_seed}", 0, 90)
  log_analytics_name          = substr("log-${local.suffix_seed}", 0, 63)
  application_insights_name   = substr("appi-${local.suffix_seed}", 0, 64)
  container_environment_name  = substr("cae-${local.suffix_seed}", 0, 32)
  container_app_name          = substr("ca-${local.suffix_seed}", 0, 32)
  user_assigned_identity_name = substr("id-${local.suffix_seed}", 0, 24)
  key_vault_name              = substr("kv${replace(local.suffix_seed, "/[^a-z0-9]/", "")}", 0, 24)
  foundry_account_name        = substr("ai${replace(local.suffix_seed, "/[^a-z0-9]/", "")}", 0, 24)
  foundry_project_name        = substr("${local.foundry_account_name}-proj", 0, 32)

  image_reference = "ghcr.io/${var.github_owner}/${var.image_name}:${var.image_tag}"

  key_vault_secret_names = {
    ghcr_token      = "ghcr-token"
    foundry_api_key = "azure-openai-api-key"
  }

  tags = merge(
    {
      environment = var.environment
      managed_by  = "opentofu"
      project     = "neuro-san"
    },
    var.tags,
  )
}

resource "random_string" "suffix" {
  length      = 4
  lower       = true
  min_numeric = 2
  numeric     = true
  special     = false
  upper       = false
}