# Azure OpenTofu Deployment

This OpenTofu stack provisions a production-oriented Azure deployment for Neuro-san with separate dev and prod environments.

## What It Creates

- Azure Resource Group
- Azure Log Analytics Workspace
- Azure Application Insights
- Azure Container Apps Environment
- Azure Container App for Neuro-san
- User-assigned managed identity for the workload
- Azure Key Vault with purge protection enabled
- Azure AI Foundry account
- Azure AI Foundry project
- Azure OpenAI deployment for `gpt-5.2`

## Deployment Shape

- Runtime platform: Azure Container Apps
- Environments: `dev` and `prod` via separate `.tfvars`
- Container registry: GitHub Container Registry (`ghcr.io`)
- Secrets: Key Vault references from Container Apps
- AI endpoint: Azure AI Foundry / Cognitive Services `AIServices` account

## Why Container Apps

The existing repo already trends toward container deployment, and Container Apps is the least-complex Azure runtime that still gives you managed ingress, autoscaling, managed identity, and clean GitHub Actions deployment without introducing AKS operational overhead.

## Important Security Note

`azurerm_key_vault_secret` stores secret material in Terraform state. This stack keeps those secrets in Key Vault for runtime use, but you still must protect the remote state backend with strict RBAC.

## Required GitHub Environment Configuration

Create GitHub environments named `dev` and `prod`, then set the following for each environment.

### Secrets

- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`
- `GHCR_READ_TOKEN`

### Variables

- `AZURE_LOCATION`
- `TFSTATE_RESOURCE_GROUP`
- `TFSTATE_STORAGE_ACCOUNT`
- `TFSTATE_CONTAINER`
- `GHCR_USERNAME`
- `NAME_PREFIX`

## Remote State Backend

The stack expects an AzureRM backend. Create the state storage account and blob container once per environment before first use, then the workflow will run `tofu init` with backend settings from GitHub environment variables.

Example local init:

```bash
cd infra/tofu
tofu init \
  -backend-config="resource_group_name=<tfstate-rg>" \
  -backend-config="storage_account_name=<tfstateaccount>" \
  -backend-config="container_name=<tfstatecontainer>" \
  -backend-config="key=dev/neuro-san.tfstate" \
  -backend-config="use_azuread_auth=true"
```

## Local Plan Example

```bash
cd infra/tofu
export ARM_USE_OIDC=true
export ARM_CLIENT_ID="..."
export ARM_TENANT_ID="..."
export ARM_SUBSCRIPTION_ID="..."

tofu plan \
  -var-file="environments/dev.tfvars" \
  -var="github_owner=<org>" \
  -var="image_name=neuro-san-studio" \
  -var="image_tag=<sha-or-release-tag>" \
  -var="ghcr_username=<github-user-or-org-bot>" \
  -var="ghcr_token=<github-read-token>"
```

## Application Configuration

The deployment expects Neuro-san to read these environment variables at runtime:

- `AZURE_OPENAI_ENDPOINT`
- `AZURE_OPENAI_API_KEY`
- `AZURE_OPENAI_DEPLOYMENT`
- `OPENAI_API_VERSION`

`registries/llm_config.hocon` has been updated to consume the endpoint and API key from environment variables instead of source-controlled credentials.

## GitHub Actions

Use `.github/workflows/azure-delivery.yml`.

- Push to `main` builds and deploys `dev`
- Publish a GitHub release to build and deploy `prod`
- Manual dispatch supports choosing either environment

## Build Logic

The workflow reuses `deploy/build.sh` rather than maintaining a second Docker build path. It sets `SERVICE_VERSION` and `TARGET_PLATFORM`, builds the local image tag produced by `build.sh`, then retags and pushes that image to GHCR.