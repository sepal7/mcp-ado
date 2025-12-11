#!/bin/bash

# Azure Deployment Script for MCP ADO Server
# Cost-optimized for Visual Studio subscription (< $30/month)
# Designed for team sharing - deploy once, everyone uses it
# Follows standard naming conventions

set -e

# Configuration - Update these values
PROJECT_CODE="${PROJECT_CODE:-mcp}"  # Change 'mcp' to your project code (xx in naming)
ENVIRONMENT="${ENVIRONMENT:-dv}"      # dv = dev, qa, pr = prod, etc.
LOCATION_CODE="${LOCATION_CODE:-eus2}"  # eus2 = eastus2
INSTANCE_NUMBER="${INSTANCE_NUMBER:-001}"

# Naming following TMNAS conventions
RESOURCE_GROUP="rg-00-integration-${PROJECT_CODE}-${ENVIRONMENT}-${LOCATION_CODE}-${INSTANCE_NUMBER}"
CONTAINER_APP_NAME="cap-00-${ENVIRONMENT}-${PROJECT_CODE}-${INSTANCE_NUMBER}"
# ACR names can only contain alphanumeric (no dashes)
CONTAINER_REGISTRY="acr00${ENVIRONMENT}${PROJECT_CODE}${INSTANCE_NUMBER}"
KEY_VAULT_NAME="kyt-00-${ENVIRONMENT}-${PROJECT_CODE}-${INSTANCE_NUMBER}"
IMAGE_NAME="mcp-ado-server"
SUBSCRIPTION_ID="71ec4f78-f42e-41e1-96f4-b75a69a53851"
LOCATION="eastus2"  # eus2
ENABLE_EXTERNAL_INGRESS="${ENABLE_EXTERNAL_INGRESS:-false}"

echo "🚀 Deploying MCP ADO Server to Azure (Team Shared Service)..."
echo "   Resource Group: $RESOURCE_GROUP"
echo "   Container App: $CONTAINER_APP_NAME"
echo "   Key Vault: $KEY_VAULT_NAME"
echo "   Location: $LOCATION"
echo ""

# Set subscription
az account set --subscription $SUBSCRIPTION_ID

# Create resource group
echo "📦 Creating resource group: $RESOURCE_GROUP..."
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION \
  --output none

# Create Key Vault for storing PAT token securely
echo "🔐 Creating Key Vault: $KEY_VAULT_NAME..."
az keyvault create \
  --name $KEY_VAULT_NAME \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --sku standard \
  --output none || echo "Key Vault may already exist, continuing..."

# Store PAT in Key Vault if provided
if [ -n "$AZURE_DEVOPS_PAT" ]; then
  echo "🔐 Storing PAT in Key Vault..."
  az keyvault secret set \
    --vault-name $KEY_VAULT_NAME \
    --name "AzureDevOpsPAT" \
    --value "$AZURE_DEVOPS_PAT" \
    --output none || echo "PAT may already exist in Key Vault"
fi

# Create Azure Container Registry (Basic tier - $5/month)
echo "📦 Creating container registry: $CONTAINER_REGISTRY..."
az acr create \
  --resource-group $RESOURCE_GROUP \
  --name $CONTAINER_REGISTRY \
  --sku Basic \
  --admin-enabled true \
  --location $LOCATION \
  --output none || echo "Container Registry may already exist, continuing..."

# Build and push Docker image
echo "🔨 Building and pushing Docker image..."
az acr build \
  --registry $CONTAINER_REGISTRY \
  --image $IMAGE_NAME:latest \
  --file Dockerfile . \
  --output none

# Get ACR login server
ACR_LOGIN_SERVER=$(az acr show --name $CONTAINER_REGISTRY --resource-group $RESOURCE_GROUP --query loginServer --output tsv)

# Create Container Apps environment (consumption plan - pay per use)
echo "🌐 Creating Container Apps environment..."
az containerapp env create \
  --name "cae-00-${ENVIRONMENT}-${PROJECT_CODE}-${INSTANCE_NUMBER}" \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --output none || echo "Container App Environment may already exist, continuing..."

# Get ACR credentials
ACR_USERNAME=$(az acr credential show --name $CONTAINER_REGISTRY --query username --output tsv)
ACR_PASSWORD=$(az acr credential show --name $CONTAINER_REGISTRY --query passwords[0].value --output tsv)

# Get PAT from Key Vault or use environment variable
PAT_VALUE="${AZURE_DEVOPS_PAT}"
if [ -z "$PAT_VALUE" ]; then
  echo "⚠️  AZURE_DEVOPS_PAT not set, attempting to retrieve from Key Vault..."
  PAT_VALUE=$(az keyvault secret show --vault-name $KEY_VAULT_NAME --name "AzureDevOpsPAT" --query value -o tsv 2>/dev/null || echo "")
fi

if [ -z "$PAT_VALUE" ]; then
  echo "❌ Error: Azure DevOps PAT not found. Please set AZURE_DEVOPS_PAT or store it in Key Vault."
  exit 1
fi

# Create Container App (consumption plan - minimal resources, scales to zero)
echo "🚀 Creating Container App: $CONTAINER_APP_NAME..."
az containerapp create \
  --name $CONTAINER_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --environment "cae-00-${ENVIRONMENT}-${PROJECT_CODE}-${INSTANCE_NUMBER}" \
  --image "${ACR_LOGIN_SERVER}/${IMAGE_NAME}:latest" \
  --registry-server $ACR_LOGIN_SERVER \
  --registry-username $ACR_USERNAME \
  --registry-password $ACR_PASSWORD \
  --cpu 0.25 \
  --memory 0.5Gi \
  --min-replicas 0 \
  --max-replicas 2 \
  --env-vars \
    "AZURE_DEVOPS_ORG=${AZURE_DEVOPS_ORG:-YourOrganization}" \
    "AZURE_DEVOPS_PROJECT=${AZURE_DEVOPS_PROJECT:-Integration}" \
    "AZURE_DEVOPS_PAT=$PAT_VALUE" \
    "NODE_ENV=production" \
  --output none || echo "Container App may already exist, updating..."

echo ""
echo "✅ Deployment complete!"
echo ""
echo "📊 Resource Details:"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  Container App: $CONTAINER_APP_NAME"
echo "  Container Registry: $CONTAINER_REGISTRY"
echo "  Key Vault: $KEY_VAULT_NAME"
echo ""
echo "📊 Cost Estimate:"
echo "  - Azure Container Registry (Basic): ~\$5/month"
echo "  - Container Apps (Consumption): ~\$0-10/month (pay per use, scales to zero)"
echo "  - Key Vault (Standard): ~\$0.03/month"
echo "  - Total: ~\$5-15/month"
echo ""
echo "👥 Team Sharing:"
echo "  This server is now available for your entire team!"
echo "  Configure your MCP clients to connect to this shared service."
echo ""
echo "🔗 Useful Commands:"
echo "  View logs:"
echo "    az containerapp logs show --name $CONTAINER_APP_NAME --resource-group $RESOURCE_GROUP --follow"
echo ""
echo "  Check status:"
echo "    az containerapp show --name $CONTAINER_APP_NAME --resource-group $RESOURCE_GROUP --query 'properties.runningStatus'"
echo ""
echo "  Update PAT in Key Vault:"
echo "    az keyvault secret set --vault-name $KEY_VAULT_NAME --name AzureDevOpsPAT --value \"your_new_pat\""
