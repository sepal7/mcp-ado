#!/bin/bash

# Pre-deployment validation script
# Checks all prerequisites before deploying to Azure

set -e

echo "🔍 Validating deployment prerequisites..."
echo ""

ERRORS=0

# Check Azure CLI
echo "1. Checking Azure CLI..."
if command -v az &> /dev/null; then
    AZ_VERSION=$(az --version | head -n 1)
    echo "   ✅ Azure CLI installed: $AZ_VERSION"
else
    echo "   ❌ Azure CLI not found. Please install: https://docs.microsoft.com/cli/azure/install-azure-cli"
    ERRORS=$((ERRORS + 1))
fi

# Check Azure login
echo "2. Checking Azure login..."
if az account show &> /dev/null; then
    SUBSCRIPTION=$(az account show --query name -o tsv)
    SUBSCRIPTION_ID=$(az account show --query id -o tsv)
    echo "   ✅ Logged into Azure"
    echo "      Subscription: $SUBSCRIPTION"
    echo "      ID: $SUBSCRIPTION_ID"
    
    # Check if correct subscription
    if [ "$SUBSCRIPTION_ID" = "71ec4f78-f42e-41e1-96f4-b75a69a53851" ]; then
        echo "   ✅ Correct subscription selected"
    else
        echo "   ⚠️  Warning: Different subscription selected"
        echo "      Expected: 71ec4f78-f42e-41e1-96f4-b75a69a53851"
        echo "      Current: $SUBSCRIPTION_ID"
    fi
else
    echo "   ❌ Not logged into Azure. Run: az login"
    ERRORS=$((ERRORS + 1))
fi

# Check Node.js
echo "3. Checking Node.js..."
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    NODE_MAJOR=$(echo $NODE_VERSION | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$NODE_MAJOR" -ge 18 ]; then
        echo "   ✅ Node.js installed: $NODE_VERSION"
    else
        echo "   ❌ Node.js version too old: $NODE_VERSION (need 18+)"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo "   ❌ Node.js not found. Please install Node.js 18+"
    ERRORS=$((ERRORS + 1))
fi

# Check npm packages
echo "4. Checking npm packages..."
if [ -d "node_modules" ]; then
    echo "   ✅ node_modules directory exists"
    if [ -f "node_modules/@modelcontextprotocol/sdk/package.json" ]; then
        echo "   ✅ MCP SDK installed"
    else
        echo "   ⚠️  MCP SDK not found. Run: npm install"
    fi
else
    echo "   ⚠️  node_modules not found. Run: npm install"
fi

# Check environment variables
echo "5. Checking environment variables..."
if [ -n "$AZURE_DEVOPS_PAT" ]; then
    PAT_LENGTH=${#AZURE_DEVOPS_PAT}
    if [ "$PAT_LENGTH" -ge 20 ]; then
        echo "   ✅ AZURE_DEVOPS_PAT is set (length: $PAT_LENGTH)"
    else
        echo "   ⚠️  AZURE_DEVOPS_PAT seems too short"
    fi
else
    echo "   ⚠️  AZURE_DEVOPS_PAT not set (will use Key Vault if available)"
fi

if [ -n "$AZURE_DEVOPS_ORG" ]; then
    echo "   ✅ AZURE_DEVOPS_ORG: $AZURE_DEVOPS_ORG"
else
    echo "   ℹ️  AZURE_DEVOPS_ORG not set (will use default: YourOrganization)"
fi

if [ -n "$AZURE_DEVOPS_PROJECT" ]; then
    echo "   ✅ AZURE_DEVOPS_PROJECT: $AZURE_DEVOPS_PROJECT"
else
    echo "   ℹ️  AZURE_DEVOPS_PROJECT not set (will use default: Integration)"
fi

# Check configuration
echo "6. Checking deployment configuration..."
PROJECT_CODE="${PROJECT_CODE:-mcp}"
ENVIRONMENT="${ENVIRONMENT:-dv}"
LOCATION_CODE="${LOCATION_CODE:-eus2}"
INSTANCE_NUMBER="${INSTANCE_NUMBER:-001}"

RESOURCE_GROUP="rg-00-integration-${PROJECT_CODE}-${ENVIRONMENT}-${LOCATION_CODE}-${INSTANCE_NUMBER}"
CONTAINER_APP="cap-00-${ENVIRONMENT}-${PROJECT_CODE}-${INSTANCE_NUMBER}"
KEY_VAULT="kyt-00-${ENVIRONMENT}-${PROJECT_CODE}-${INSTANCE_NUMBER}"

echo "   Project Code: $PROJECT_CODE"
echo "   Environment: $ENVIRONMENT"
echo "   Location Code: $LOCATION_CODE"
echo "   Instance Number: $INSTANCE_NUMBER"
echo ""
echo "   Resource Group: $RESOURCE_GROUP"
echo "   Container App: $CONTAINER_APP"
echo "   Key Vault: $KEY_VAULT"

# Check if resources already exist
echo ""
echo "7. Checking for existing resources..."
if az group show --name "$RESOURCE_GROUP" &> /dev/null; then
    echo "   ⚠️  Resource group already exists: $RESOURCE_GROUP"
    echo "      Deployment will update existing resources"
else
    echo "   ✅ Resource group does not exist (will be created)"
fi

# Check deployment files
echo ""
echo "8. Checking deployment files..."
if [ -f "deploy.sh" ]; then
    echo "   ✅ deploy.sh exists"
    if [ -x "deploy.sh" ]; then
        echo "   ✅ deploy.sh is executable"
    else
        echo "   ⚠️  deploy.sh is not executable. Run: chmod +x deploy.sh"
    fi
else
    echo "   ❌ deploy.sh not found"
    ERRORS=$((ERRORS + 1))
fi

if [ -f "azure-deploy.bicep" ]; then
    echo "   ✅ azure-deploy.bicep exists"
else
    echo "   ❌ azure-deploy.bicep not found"
    ERRORS=$((ERRORS + 1))
fi

if [ -f "Dockerfile" ]; then
    echo "   ✅ Dockerfile exists"
else
    echo "   ❌ Dockerfile not found"
    ERRORS=$((ERRORS + 1))
fi

# Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ $ERRORS -eq 0 ]; then
    echo "✅ Validation complete! Ready to deploy."
    echo ""
    echo "To deploy, run:"
    echo "  ./deploy.sh"
    exit 0
else
    echo "❌ Validation found $ERRORS error(s). Please fix before deploying."
    exit 1
fi

