# PowerShell deployment script for Windows
# Manual deployment with step-by-step execution

$ErrorActionPreference = "Stop"

# Configuration
$PROJECT_CODE = if ($env:PROJECT_CODE) { $env:PROJECT_CODE } else { "mcp" }
$ENVIRONMENT = if ($env:ENVIRONMENT) { $env:ENVIRONMENT } else { "dv" }
$LOCATION_CODE = if ($env:LOCATION_CODE) { $env:LOCATION_CODE } else { "eus2" }
$INSTANCE_NUMBER = if ($env:INSTANCE_NUMBER) { $env:INSTANCE_NUMBER } else { "001" }

# Naming following standard conventions
$RESOURCE_GROUP = "rg-00-integration-$PROJECT_CODE-$ENVIRONMENT-$LOCATION_CODE-$INSTANCE_NUMBER"
$CONTAINER_APP_NAME = "cap-00-$ENVIRONMENT-$PROJECT_CODE-$INSTANCE_NUMBER"
# ACR names can only contain alphanumeric (no dashes)
$CONTAINER_REGISTRY = "acr00$ENVIRONMENT$PROJECT_CODE$INSTANCE_NUMBER"
$KEY_VAULT_NAME = "kyt-00-$ENVIRONMENT-$PROJECT_CODE-$INSTANCE_NUMBER"
$CONTAINER_APP_ENV = "cae-00-$ENVIRONMENT-$PROJECT_CODE-$INSTANCE_NUMBER"
$IMAGE_NAME = "mcp-ado-server"
$SUBSCRIPTION_ID = "71ec4f78-f42e-41e1-96f4-b75a69a53851"
$LOCATION = "eastus2"

Write-Host "🚀 Deploying MCP ADO Server to Azure (Team Shared Service)..." -ForegroundColor Cyan
Write-Host "   Resource Group: $RESOURCE_GROUP"
Write-Host "   Container App: $CONTAINER_APP_NAME"
Write-Host "   Key Vault: $KEY_VAULT_NAME"
Write-Host "   Container Registry: $CONTAINER_REGISTRY (alphanumeric only)"
Write-Host "   Location: $LOCATION"
Write-Host ""

# Check Azure login
Write-Host "Checking Azure login..." -ForegroundColor Yellow
try {
    $account = az account show 2>$null | ConvertFrom-Json
    if (-not $account) {
        Write-Host "Please login to Azure first:" -ForegroundColor Yellow
        Write-Host "  az login --scope https://management.core.windows.net//.default" -ForegroundColor White
        exit 1
    }
} catch {
    Write-Host "Please login to Azure first:" -ForegroundColor Yellow
    Write-Host "  az login --scope https://management.core.windows.net//.default" -ForegroundColor White
    exit 1
}

# Set subscription
Write-Host "Setting subscription..." -ForegroundColor Yellow
az account set --subscription $SUBSCRIPTION_ID

# Create resource group
Write-Host "📦 Creating resource group: $RESOURCE_GROUP..." -ForegroundColor Cyan
az group create --name $RESOURCE_GROUP --location $LOCATION --output none

# Create Key Vault
Write-Host "🔐 Creating Key Vault: $KEY_VAULT_NAME..." -ForegroundColor Cyan
az keyvault create --name $KEY_VAULT_NAME --resource-group $RESOURCE_GROUP --location $LOCATION --sku standard --output none 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "   Key Vault may already exist, continuing..." -ForegroundColor Yellow
}

# Create Container Registry (alphanumeric name only)
Write-Host "📦 Creating container registry: $CONTAINER_REGISTRY..." -ForegroundColor Cyan
az acr create --resource-group $RESOURCE_GROUP --name $CONTAINER_REGISTRY --sku Basic --admin-enabled true --location $LOCATION --output none 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "   Container Registry may already exist, continuing..." -ForegroundColor Yellow
}

# Build and push Docker image
Write-Host "🔨 Building and pushing Docker image..." -ForegroundColor Cyan
az acr build --registry $CONTAINER_REGISTRY --image "$IMAGE_NAME`:latest" --file Dockerfile . --output none

# Get ACR login server
$ACR_LOGIN_SERVER = az acr show --name $CONTAINER_REGISTRY --resource-group $RESOURCE_GROUP --query loginServer --output tsv

# Install Container Apps extension if needed
Write-Host "Checking Container Apps extension..." -ForegroundColor Yellow
az extension add --name containerapp --upgrade 2>$null

# Create Container Apps environment
Write-Host "🌐 Creating Container Apps environment: $CONTAINER_APP_ENV..." -ForegroundColor Cyan
az containerapp env create --name $CONTAINER_APP_ENV --resource-group $RESOURCE_GROUP --location $LOCATION --output none 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "   Container App Environment may already exist, continuing..." -ForegroundColor Yellow
}

# Get ACR credentials
$ACR_USERNAME = az acr credential show --name $CONTAINER_REGISTRY --query username --output tsv
$ACR_PASSWORD = az acr credential show --name $CONTAINER_REGISTRY --query passwords[0].value --output tsv

# Get PAT from environment or Key Vault
$PAT_VALUE = $env:AZURE_DEVOPS_PAT
if (-not $PAT_VALUE) {
    Write-Host "⚠️  AZURE_DEVOPS_PAT not set in environment." -ForegroundColor Yellow
    Write-Host "   You can:" -ForegroundColor Yellow
    Write-Host "   1. Set it: `$env:AZURE_DEVOPS_PAT = 'your_token'" -ForegroundColor White
    Write-Host "   2. Store in Key Vault: az keyvault secret set --vault-name $KEY_VAULT_NAME --name AzureDevOpsPAT --value 'your_token'" -ForegroundColor White
    Write-Host "   3. Update Container App environment variable after deployment" -ForegroundColor White
    Write-Host ""
    Write-Host "   Proceeding with deployment (you can add PAT later)..." -ForegroundColor Yellow
    $PAT_VALUE = "PLACEHOLDER_UPDATE_ME"
}

# Create Container App
Write-Host "🚀 Creating Container App: $CONTAINER_APP_NAME..." -ForegroundColor Cyan
az containerapp create `
  --name $CONTAINER_APP_NAME `
  --resource-group $RESOURCE_GROUP `
  --environment $CONTAINER_APP_ENV `
  --image "$ACR_LOGIN_SERVER/$IMAGE_NAME`:latest" `
  --registry-server $ACR_LOGIN_SERVER `
  --registry-username $ACR_USERNAME `
  --registry-password $ACR_PASSWORD `
  --cpu 0.25 `
  --memory 0.5Gi `
  --min-replicas 0 `
  --max-replicas 2 `
  --env-vars `
    "AZURE_DEVOPS_ORG=$($env:AZURE_DEVOPS_ORG ?? 'YourOrganization')" `
    "AZURE_DEVOPS_PROJECT=$($env:AZURE_DEVOPS_PROJECT ?? 'Integration')" `
    "AZURE_DEVOPS_PAT=$PAT_VALUE" `
    "NODE_ENV=production" `
  --output none 2>$null

if ($LASTEXITCODE -ne 0) {
    Write-Host "   Container App may already exist, updating..." -ForegroundColor Yellow
    az containerapp update `
      --name $CONTAINER_APP_NAME `
      --resource-group $RESOURCE_GROUP `
      --image "$ACR_LOGIN_SERVER/$IMAGE_NAME`:latest" `
      --set-env-vars `
        "AZURE_DEVOPS_ORG=$($env:AZURE_DEVOPS_ORG ?? 'YourOrganization')" `
        "AZURE_DEVOPS_PROJECT=$($env:AZURE_DEVOPS_PROJECT ?? 'Integration')" `
        "AZURE_DEVOPS_PAT=$PAT_VALUE" `
        "NODE_ENV=production" `
      --output none
}

Write-Host ""
Write-Host "✅ Deployment complete!" -ForegroundColor Green
Write-Host ""
Write-Host "📊 Resource Details:" -ForegroundColor Cyan
Write-Host "  Resource Group: $RESOURCE_GROUP"
Write-Host "  Container App: $CONTAINER_APP_NAME"
Write-Host "  Container Registry: $CONTAINER_REGISTRY"
Write-Host "  Key Vault: $KEY_VAULT_NAME"
Write-Host ""
Write-Host "📊 Cost Estimate: ~`$5-15/month" -ForegroundColor Cyan
Write-Host ""
if ($PAT_VALUE -eq "PLACEHOLDER_UPDATE_ME") {
    Write-Host "⚠️  IMPORTANT: Update PAT token!" -ForegroundColor Yellow
    Write-Host "   Store in Key Vault:" -ForegroundColor White
    Write-Host "     az keyvault secret set --vault-name $KEY_VAULT_NAME --name AzureDevOpsPAT --value 'your_pat_token'" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   Then update Container App:" -ForegroundColor White
    Write-Host "     az containerapp update --name $CONTAINER_APP_NAME --resource-group $RESOURCE_GROUP --set-env-vars 'AZURE_DEVOPS_PAT=@Microsoft.KeyVault(SecretUri=https://$KEY_VAULT_NAME.vault.azure.net/secrets/AzureDevOpsPAT/)'" -ForegroundColor Gray
    Write-Host ""
}

