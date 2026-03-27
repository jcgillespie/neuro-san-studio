output "resource_group_name" {
  description = "Azure resource group containing the deployment."
  value       = azurerm_resource_group.this.name
}

output "container_app_name" {
  description = "Azure Container App name."
  value       = azurerm_container_app.this.name
}

output "container_app_url" {
  description = "Public URL of the deployed Neuro-san service."
  value       = try("https://${azurerm_container_app.this.ingress[0].fqdn}", null)
}

output "container_image" {
  description = "Image reference currently configured on the container app."
  value       = local.image_reference
}

output "foundry_account_name" {
  description = "Azure AI Foundry account name."
  value       = azurerm_cognitive_account.ai_foundry.name
}

output "foundry_endpoint" {
  description = "Azure AI Foundry endpoint used by Neuro-san."
  value       = azurerm_cognitive_account.ai_foundry.endpoint
}

output "foundry_project_id" {
  description = "Azure AI Foundry project resource ID."
  value       = azurerm_cognitive_account_project.ai_foundry.id
}

output "foundry_project_endpoints" {
  description = "Project endpoints returned by Azure AI Foundry."
  value       = azurerm_cognitive_account_project.ai_foundry.endpoints
}

output "foundry_model_deployment_name" {
  description = "Deployment name configured for the GPT model."
  value       = azurerm_cognitive_deployment.model.name
}

output "key_vault_name" {
  description = "Key Vault storing deployment secrets."
  value       = azurerm_key_vault.this.name
}

output "user_assigned_identity_client_id" {
  description = "Client ID of the workload managed identity."
  value       = azurerm_user_assigned_identity.workload.client_id
}