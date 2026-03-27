resource "azurerm_container_app" "this" {
  name                         = local.container_app_name
  container_app_environment_id = azurerm_container_app_environment.this.id
  resource_group_name          = azurerm_resource_group.this.name
  revision_mode                = "Single"
  tags                         = local.tags

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.workload.id]
  }

  secret {
    identity            = azurerm_user_assigned_identity.workload.id
    key_vault_secret_id = azurerm_key_vault_secret.ghcr_token.versionless_id
    name                = local.key_vault_secret_names.ghcr_token
  }

  secret {
    identity            = azurerm_user_assigned_identity.workload.id
    key_vault_secret_id = azurerm_key_vault_secret.foundry_api_key.versionless_id
    name                = local.key_vault_secret_names.foundry_api_key
  }

  registry {
    server               = "ghcr.io"
    username             = var.ghcr_username
    password_secret_name = local.key_vault_secret_names.ghcr_token
  }

  dynamic "ingress" {
    for_each = var.container_ingress_external_enabled ? [1] : []

    content {
      external_enabled = true
      target_port      = 8080
      transport        = "auto"

      dynamic "ip_security_restriction" {
        for_each = var.allowed_ingress_cidrs

        content {
          action           = "Allow"
          ip_address_range = ip_security_restriction.value
          name             = "allow-${replace(replace(ip_security_restriction.value, "/", "-"), ".", "-")}"
        }
      }

      traffic_weight {
        latest_revision = true
        percentage      = 100
      }
    }
  }

  template {
    min_replicas = var.container_min_replicas
    max_replicas = var.container_max_replicas

    container {
      name   = "neuro-san"
      image  = local.image_reference
      cpu    = var.container_cpu
      memory = var.container_memory

      env {
        name  = "APPINSIGHTS_CONNECTION_STRING"
        value = azurerm_application_insights.this.connection_string
      }

      env {
        name  = "AZURE_OPENAI_ENDPOINT"
        value = azurerm_cognitive_account.ai_foundry.endpoint
      }

      env {
        name  = "AZURE_OPENAI_DEPLOYMENT"
        value = var.foundry_model_deployment_name
      }

      env {
        name  = "OPENAI_API_VERSION"
        value = var.openai_api_version
      }

      env {
        name  = "LOG_LEVEL"
        value = var.log_level
      }

      env {
        name        = "AZURE_OPENAI_API_KEY"
        secret_name = local.key_vault_secret_names.foundry_api_key
      }

      liveness_probe {
        port      = 8080
        transport = "TCP"
      }

      readiness_probe {
        port      = 8080
        transport = "TCP"
      }

      startup_probe {
        port      = 8080
        transport = "TCP"
      }
    }
  }

  lifecycle {
    ignore_changes = [secret]
  }

  depends_on = [
    azurerm_cognitive_deployment.model,
    azurerm_key_vault_secret.ghcr_token,
    azurerm_key_vault_secret.foundry_api_key,
  ]
}