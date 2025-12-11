# Setup Guide for MCP ADO Server

## Prerequisites

1. **Azure DevOps Personal Access Token (PAT)**
   - Go to: https://dev.azure.com/YourOrganization/_usersSettings/tokens
   - Create new token with:
     - **Scope**: Custom defined
     - **Permissions**: 
       - Wiki: Read
       - Code: Read
       - Work Items: Read, Write (if creating/updating)
       - Build: Read
       - Pull Requests: Read
       - Release: Read
       - Test Plans: Read
   - **Expiration**: Set as needed
   - **Copy the token** (you won't see it again!)

2. **Azure CLI**
   ```bash
   az --version  # Should be 2.50.0 or later
   az login
   ```

3. **Node.js 18+**
   ```bash
   node --version  # Should be 18.0.0 or later
   ```

## Naming Convention

The deployment follows standard naming conventions:

- **Resource Group**: `rg-00-YourProject-{projectCode}-{environment}-{locationCode}-{instanceNumber}`
  - Example: `rg-00-YourProject-mcp-dv-eus2-001`
- **Container App**: `cap-00-{environment}-{projectCode}-{instanceNumber}`
  - Example: `your-container-app`
- **Key Vault**: `kyt-00-{environment}-{projectCode}-{instanceNumber}`
  - Example: `your-key-vault`
- **Container Registry**: `acr-00-{environment}-{projectCode}-{instanceNumber}`
  - Example: `acr-00-dv-mcp-001`

### Configuration Variables

- `PROJECT_CODE`: Project code (e.g., "mcp", "ado") - defaults to "mcp"
- `ENVIRONMENT`: Environment code (e.g., "dv" = dev, "qa" = qa, "pr" = prod) - defaults to "dv"
- `LOCATION_CODE`: Location code (e.g., "eus2" = eastus2) - defaults to "eus2"
- `INSTANCE_NUMBER`: Instance number (e.g., "001", "002") - defaults to "001"

## Local Setup

1. **Clone and install**
   ```bash
   git clone https://github.com/sepal7/mcp-ado.git
   cd mcp-ado
   npm install
   ```

2. **Configure environment**
   ```bash
   cp .env.example .env
   # Edit .env and add your PAT token
   ```

3. **Test locally**
   ```bash
   npm test  # Test API connectivity
   npm start  # Start MCP server
   ```

## Azure Deployment

### Option 1: Using deploy.sh (Recommended)

```bash
# Set configuration variables (optional - defaults provided)
export PROJECT_CODE="mcp"          # Change to your project code
export ENVIRONMENT="dv"            # dv = dev, qa = qa, pr = prod
export LOCATION_CODE="eus2"        # eus2 = eastus2
export INSTANCE_NUMBER="001"       # Instance number

# Set Azure DevOps configuration
export AZURE_DEVOPS_PAT="your_pat_token_here"
export AZURE_DEVOPS_ORG="YourOrganization"
export AZURE_DEVOPS_PROJECT="YourProject"

# Make script executable
chmod +x deploy.sh

# Deploy
./deploy.sh
```

### Option 2: Using Bicep Template

```bash
# Set subscription
az account set --subscription 71ec4f78-f42e-41e1-96f4-b75a69a53851

# Create resource group with proper naming
az group create \
  --name rg-00-YourProject-mcp-dv-eus2-001 \
  --location eastus2

# Deploy using Bicep
az deployment group create \
  --resource-group rg-00-YourProject-mcp-dv-eus2-001 \
  --template-file azure-deploy.bicep \
  --parameters \
    projectCode=mcp \
    environment=dv \
    locationCode=eus2 \
    instanceNumber=001 \
    orgName=YourOrganization \
    projectName=YourProject \
    adoPat="your_pat_token_here" \
    location=eastus2
```

### Option 3: Using Bicep with Key Vault Reference

```bash
# First, create Key Vault and store PAT
az keyvault create \
  --name your-key-vault \
  --resource-group rg-00-YourProject-mcp-dv-eus2-001 \
  --location eastus2 \
  --sku standard

az keyvault secret set \
  --vault-name your-key-vault \
  --name AzureDevOpsPAT \
  --value "your_pat_token_here"

# Then deploy using parameters file (update deploy-params.json first)
az deployment group create \
  --resource-group rg-00-YourProject-mcp-dv-eus2-001 \
  --template-file azure-deploy.bicep \
  --parameters @deploy-params.json
```

## MCP Client Configuration

### For Cursor/Claude Desktop

Add to your MCP configuration file:

**macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`
**Windows**: `%APPDATA%\Claude\claude_desktop_config.json`

#### Local Configuration
```json
{
  "mcpServers": {
    "ado": {
      "command": "node",
      "args": ["/path/to/mcp-ado/server.js"],
      "env": {
        "AZURE_DEVOPS_ORG": "YourOrganization",
        "AZURE_DEVOPS_PROJECT": "YourProject",
        "AZURE_DEVOPS_PAT": "your_pat_token_here"
      }
    }
  }
}
```

#### Azure Deployment Configuration
If deploying to Azure with external ingress enabled:
```json
{
  "mcpServers": {
    "ado": {
      "url": "https://your-container-app.azurecontainerapps.io",
      "env": {
        "AZURE_DEVOPS_ORG": "YourOrganization",
        "AZURE_DEVOPS_PROJECT": "YourProject"
      }
    }
  }
}
```

## Cost Monitoring

Monitor your Azure costs:

```bash
# Check current month's cost
az consumption usage list \
  --start-date $(date -u -d '1 month ago' +%Y-%m-%d) \
  --end-date $(date -u +%Y-%m-%d) \
  --query "[?instanceName=='rg-00-YourProject-mcp-dv-eus2-001'].{Cost:pretaxCost,Service:instanceName}" \
  --output table
```

Expected costs:
- **Container Registry (Basic)**: ~$5/month
- **Container Apps (Consumption)**: ~$0-10/month (only when active)
- **Key Vault (Standard)**: ~$0.03/month
- **Total**: ~$5-15/month

## Available Tools

The server provides access to:

- **Wiki**: Get pages, list pages, search
- **Repositories**: List repos, get files, browse branches, search code
- **Work Items**: Get items, query with WIQL, create/update items
- **Pull Requests**: List PRs, get PR details, review comments
- **Builds**: List builds, get build details
- **Pipelines**: List pipelines, get pipeline run details
- **Releases**: List releases, get release details
- **Test Plans**: List test plans, get plan details
- **Generic API**: Make any ADO REST API call

## Troubleshooting

### PAT Token Issues
- Ensure token has required permissions
- Check token hasn't expired
- Verify org/project names are correct
- If using Key Vault, verify secret exists: `az keyvault secret show --vault-name your-key-vault --name AzureDevOpsPAT`

### Deployment Issues
- Check Azure subscription has sufficient credits
- Verify you're logged into correct Azure account
- Check resource names don't conflict (must be globally unique for some resources)
- Verify naming convention follows your organization's standards

### MCP Connection Issues
- Verify Node.js version (18+)
- Check environment variables are set correctly
- Test API connectivity: `npm test`
- Check Container App logs: `az containerapp logs show --name your-container-app --resource-group rg-00-YourProject-mcp-dv-eus2-001 --follow`

## Security Best Practices

1. **Never commit PAT tokens to git**
   - Use `.env` file (already in `.gitignore`)
   - Use Azure Key Vault for production deployments

2. **Rotate tokens regularly**
   - Set expiration dates
   - Regenerate tokens periodically
   - Update in Key Vault: `az keyvault secret set --vault-name your-key-vault --name AzureDevOpsPAT --value "new_token"`

3. **Use minimal permissions**
   - Only grant necessary read permissions
   - Don't grant write permissions unless needed

4. **Key Vault Access**
   - Limit access to Key Vault
   - Use managed identity where possible
   - Enable soft delete and retention

## Support

For issues or questions:
- Open an issue on GitHub: https://github.com/sepal7/mcp-ado
- Check Azure Container Apps logs: `az containerapp logs show --name your-container-app --resource-group rg-00-YourProject-mcp-dv-eus2-001 --follow`
