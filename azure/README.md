# Azure Deployment

This folder contains all files and scripts needed for deploying the MCP ADO Server to Azure Container Apps.

## ⚠️ Note

**This Azure deployment has not been tested yet.** Use at your own risk. For local development, see the main [README.md](../README.md).

## Contents

### Infrastructure as Code
- `azure-deploy.bicep` - Main Bicep template for Azure resources
- `deploy-params.json` - Deployment parameters

### Docker
- `Dockerfile` - Container image definition
- `build-and-push.ps1` - PowerShell script to build and push Docker image
- `build-image-via-rest.ps1` - Alternative REST API-based build script
- `build-source.zip` - Source code archive for builds

### Deployment Scripts
- `deploy.sh` - Bash deployment script
- `deploy-manual.ps1` - PowerShell manual deployment script

### Monitoring & Cost Management
- `setup-monitoring.ps1` - Set up Application Insights monitoring
- `setup-monitoring-rest.ps1` - REST API-based monitoring setup
- `setup-cost-alerts.ps1` - Configure cost alerts
- `setup-cost-alerts.sh` - Bash version of cost alerts setup
- `setup-cost-alerts-monitor.ps1` - Monitor cost alerts
- `mcp-monitoring-dashboard.json` - Azure Monitor dashboard definition

### Validation
- `validate-deployment.ps1` - Validate deployment (PowerShell)
- `validate-deployment.sh` - Validate deployment (Bash)

## Prerequisites

- Azure subscription
- Azure CLI installed and configured
- Docker (for local builds)
- Azure Container Registry (ACR)
- Azure Container Apps environment

## Quick Start

See the main [SETUP.md](../docs/SETUP.md) for detailed deployment instructions.

## Cost Estimate

Expected cost: **~$5-15/month** (perfect for Visual Studio credits)

## Related Documentation

- Main setup: [../docs/SETUP.md](../docs/SETUP.md)
- Client configuration: [../docs/CONFIGURE-MCP-CLIENT.md](../docs/CONFIGURE-MCP-CLIENT.md)
- Main README: [../README.md](../README.md)

