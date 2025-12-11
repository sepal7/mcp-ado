# Configure MCP Client - Final Step!

## ✅ Deployment Complete!

Your MCP ADO Server is now running in Azure! 🎉

## 🎯 Next: Configure Your MCP Client

Since the Container App uses stdio (not HTTP), you'll use the **local server** for your MCP client. The Azure deployment is ready for team sharing, but for local use, configure the client to run the server locally.

### For Cursor

1. **Open Cursor Settings**
   - Go to: Settings → Features → Model Context Protocol
   - Or edit config file directly

2. **Add MCP Server Configuration**

   **Windows**: Edit `%APPDATA%\Cursor\User\globalStorage\saoudrizwan.claude-dev\settings\cline_mcp_settings.json`

   Add this configuration:
   ```json
   {
     "mcpServers": {
       "ado": {
         "command": "node",
         "args": ["C:\\AdoAzure\\mcp-ado\\server.js"],
         "env": {
           "AZURE_DEVOPS_ORG": "YourOrganization",
           "AZURE_DEVOPS_PROJECT": "YourProject",
           "AZURE_DEVOPS_PAT": "your_pat_token_here"
         }
       }
     }
   }
   ```

3. **Get PAT Token from Key Vault**:
   ```powershell
   az keyvault secret show --vault-name your-key-vault --name AzureDevOpsPAT --query value -o tsv
   ```
   Copy the output and use it in the config above.

4. **Restart Cursor**

### For Claude Desktop

1. **Find Config File**:
   - **Windows**: `%APPDATA%\Claude\claude_desktop_config.json`
   - **macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`

2. **Edit Config File**:
   ```json
   {
     "mcpServers": {
       "ado": {
         "command": "node",
         "args": ["C:\\AdoAzure\\mcp-ado\\server.js"],
         "env": {
           "AZURE_DEVOPS_ORG": "YourOrganization",
           "AZURE_DEVOPS_PROJECT": "YourProject",
           "AZURE_DEVOPS_PAT": "your_pat_token_here"
         }
       }
     }
   }
   ```

3. **Get PAT Token**:
   ```powershell
   az keyvault secret show --vault-name your-key-vault --name AzureDevOpsPAT --query value -o tsv
   ```

4. **Restart Claude Desktop**

## 🧪 Test the Connection

After configuring and restarting your MCP client, test it:

1. **Ask a question** like:
   - "List all repositories in the YourProject project"
   - "Show me work items from Azure DevOps"
   - "Get the wiki page about YourProject Application Design"

2. **The MCP server should respond** with data from Azure DevOps!

## 📊 Verify Everything

### Check Container App Status
```powershell
az containerapp show `
  --name your-container-app `
  --resource-group your-resource-group `
  --query "{Status:properties.provisioningState, Running:properties.runningStatus}" -o table
```

### Check Logs
```powershell
az containerapp logs show `
  --name your-container-app `
  --resource-group your-resource-group `
  --tail 50
```

You should see: **"MCP Azure DevOps Server running on stdio"**

## 🎉 Deployment Summary

✅ **All Resources Created**:
- Resource Group ✅
- Key Vault ✅
- Container Registry ✅
- Container App Environment ✅
- Container App ✅
- Docker Image ✅

✅ **Configuration Complete**:
- PAT Token stored ✅
- Container App running ✅
- Environment variables set ✅

## 📚 Available MCP Tools

Your MCP server provides access to:

- **Wiki**: Get pages, list pages, search
- **Repositories**: List repos, get files, search code
- **Work Items**: Get items, query with WIQL, create/update
- **Pull Requests**: List PRs, get PR details
- **Builds**: List builds, get build details
- **Pipelines**: List pipelines, get run details
- **Releases**: List releases, get release details
- **Test Plans**: List test plans, get plan details
- **Generic API**: Make any ADO REST API call

## 💰 Cost Monitoring

Monitor your costs:
```powershell
az consumption usage list `
  --start-date (Get-Date).AddDays(-30).ToString("yyyy-MM-dd") `
  --end-date (Get-Date).ToString("yyyy-MM-dd") `
  --query "[?instanceName=='rg-00-YourProject-mcp-dv-eus2-001'].{Cost:pretaxCost}" `
  --output table
```

Expected: **~$5-15/month** ✅

---

**🎊 Congratulations! Your MCP ADO Server is fully deployed and ready to use!**

Just configure your MCP client and start querying Azure DevOps! 🚀


