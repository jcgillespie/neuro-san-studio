resource "azurerm_cognitive_account" "ai_foundry" {
  name                          = local.foundry_account_name
  location                      = azurerm_resource_group.this.location
  resource_group_name           = azurerm_resource_group.this.name
  kind                          = "AIServices"
  sku_name                      = "S0"
  custom_subdomain_name         = local.foundry_account_name
  local_auth_enabled            = true
  project_management_enabled    = true
  public_network_access_enabled = true

  identity {
    type = "SystemAssigned"
  }

  tags = local.tags
}

resource "azurerm_cognitive_account_project" "ai_foundry" {
  name                 = local.foundry_project_name
  cognitive_account_id = azurerm_cognitive_account.ai_foundry.id
  location             = azurerm_resource_group.this.location
  display_name         = "Neuro-san ${upper(var.environment)}"
  description          = "Neuro-san ${var.environment} AI Foundry project"

  identity {
    type = "SystemAssigned"
  }

  tags = local.tags
}

resource "azurerm_cognitive_deployment" "model" {
  name                   = var.foundry_model_deployment_name
  cognitive_account_id   = azurerm_cognitive_account.ai_foundry.id
  version_upgrade_option = "OnceNewDefaultVersionAvailable"

  model {
    format  = "OpenAI"
    name    = var.foundry_model_name
    version = var.foundry_model_version != "" ? var.foundry_model_version : null
  }

  sku {
    name     = var.foundry_model_sku_name
    capacity = var.foundry_model_capacity
  }

  depends_on = [azurerm_cognitive_account_project.ai_foundry]
}

resource "azurerm_key_vault_secret" "ghcr_token" {
  name             = local.key_vault_secret_names.ghcr_token
  key_vault_id     = azurerm_key_vault.this.id
  value_wo         = var.ghcr_token
  value_wo_version = 1

  depends_on = [time_sleep.key_vault_rbac_ready]
}

resource "azurerm_key_vault_secret" "foundry_api_key" {
  name         = local.key_vault_secret_names.foundry_api_key
  key_vault_id = azurerm_key_vault.this.id
  value        = azurerm_cognitive_account.ai_foundry.primary_access_key

  depends_on = [
    time_sleep.key_vault_rbac_ready,
    azurerm_cognitive_deployment.model,
  ]
}