# Company-Specific Configuration

This file contains company-specific configuration that should be kept local and not committed to the repository.

## Local Configuration Files

The following files/directories are gitignored and should contain your company-specific information:

- `.env` - Environment variables with your Azure DevOps organization, project, and PAT token
- `company-config/` - Any company-specific configuration files (create this directory if needed)

## What to Configure Locally

1. **Azure DevOps Organization**: Your organization name
2. **Azure DevOps Project**: Your default project name
3. **PAT Token**: Your Personal Access Token
4. **Paths**: Any company-specific file paths
5. **Resource Names**: Azure resource names, resource groups, etc.

## Example .env File

Create a `.env` file in the root directory (it's gitignored):

```env
AZURE_DEVOPS_ORG=YourCompanyName
AZURE_DEVOPS_PROJECT=YourProjectName
AZURE_DEVOPS_PAT=your_pat_token_here
APPLICATIONINSIGHTS_CONNECTION_STRING=your_connection_string_here
```

## IDE Configuration

When configuring your IDE (Cursor, VS Code, etc.), use your actual paths and organization names in the settings.json file. These settings are local to your machine and won't be committed.

## Azure Deployment

For Azure deployment, keep company-specific values in:
- `azure/deploy-params.json` (if using)
- Azure Key Vault secrets
- Local environment variables

Do not commit sensitive information or company-specific resource names to the repository.

