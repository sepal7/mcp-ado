# VS Code + GitHub Copilot Setup Guide

This guide will help you configure this MCP server to work with VS Code and GitHub Copilot Chat.

## Prerequisites

- ✅ VS Code installed
- ✅ GitHub Copilot Chat extension installed
- ✅ Active GitHub Copilot subscription
- ✅ Node.js 18+ installed
- ✅ MCP server cloned and dependencies installed (`npm install`)

## Step 1: Configure VS Code Settings

1. **Open VS Code Settings:**
   - Press `Ctrl+,` (or `Cmd+,` on Mac)
   - Or go to: `File → Preferences → Settings`

2. **Open Settings JSON:**
   - Click the `{}` icon in the top right (Open Settings JSON)
   - Or use: `Ctrl+Shift+P` → "Preferences: Open User Settings (JSON)"

3. **Add MCP Server Configuration:**

   Add this configuration to your `settings.json`:

   ```json
   {
     "chat.mcp.servers": {
       "ado": {
         "command": "node",
         "args": [
           "C:\\adoAzure\\Github\\mcp-ado\\server.js"
         ],
         "env": {
           "AZURE_DEVOPS_ORG": "YourOrganization",
           "AZURE_DEVOPS_PROJECT": "YourProject",
           "AZURE_DEVOPS_PAT": "your_pat_token_here"
         }
       }
     }
   }
   ```

   **Important Notes:**
   - Replace `C:\\adoAzure\\Github\\mcp-ado\\server.js` with your actual path
   - Replace `your_pat_token_here` with your Azure DevOps PAT token
   - Use double backslashes (`\\`) for Windows paths
   - On Mac/Linux, use forward slashes: `/path/to/mcp-ado/server.js`

4. **Save the file** (`Ctrl+S`)

## Step 2: Get Your PAT Token

1. Go to: https://dev.azure.com/YourOrganization/_usersSettings/tokens
2. Click "New Token"
3. Name: `MCP Server Token`
4. Expiration: 90 days (or custom)
5. **Scopes (Select these):**
   - ✅ Code (Read & write)
   - ✅ Work Items (Read & write)
   - ✅ Wiki (Read)
   - ✅ Build (Read)
   - ✅ Release (Read)
6. Click "Create"
7. **Copy the token immediately** (you won't see it again!)

## Step 3: Update PAT Token (Optional Helper Script)

If you need to update your PAT token later, use the helper script:

```powershell
cd C:\\path\\to\\mcp-ado
   .\scripts\update-pat.ps1 -NewPAT "your_new_token_here"
```

This will update both `.env` and VS Code settings automatically.

## Step 4: Restart VS Code

**CRITICAL:** You must completely restart VS Code for MCP configuration to take effect:

1. Close all VS Code windows
2. Make sure VS Code is fully closed (check Task Manager if needed)
3. Reopen VS Code

## Step 5: Verify MCP Tools Are Available

1. **Open GitHub Copilot Chat:**
   - Press `Ctrl+L` (or `Cmd+L` on Mac)
   - Or click the Copilot icon in the sidebar

2. **Check for MCP Tools:**
   - In the chat, you should see MCP tools available
   - Try asking: "What Azure DevOps tools are available?"

3. **Test the Connection:**
   - Ask: "Get work item 12345 from Azure DevOps"
   - Or: "List repositories in the YourProject project"

## Troubleshooting

### MCP Tools Not Appearing

1. **Check Server Path:**
   - Verify the path in `settings.json` is correct
   - Use absolute path, not relative
   - Check file exists: `Test-Path "C:\\path\\to\\mcp-ado\server.js"`

2. **Check Node.js:**
   - Open terminal: `node --version` (should be 18+)
   - Verify Node.js is in PATH

3. **Check VS Code Output:**
   - Go to: `View → Output`
   - Select "GitHub Copilot" from dropdown
   - Look for MCP-related errors

4. **Verify Settings JSON Syntax:**
   - Use a JSON validator to check syntax
   - Ensure no trailing commas
   - Ensure all strings are properly quoted

5. **Restart VS Code:**
   - Fully close and reopen VS Code
   - This is often the solution!

### Authentication Errors

If you see "401 Unauthorized" or "Access Denied":

1. **Check PAT Token:**
   - Verify token hasn't expired
   - Regenerate if needed: https://dev.azure.com/YourOrganization/_usersSettings/tokens

2. **Update Token:**
   ```powershell
   .\update-pat.ps1 -NewPAT "new_token"
   ```

3. **Restart VS Code** after updating

### Server Not Starting

1. **Test Server Manually:**
   ```powershell
   cd C:\\path\\to\\mcp-ado
   node server.js
   ```
   You should see: "MCP Azure DevOps Server running on stdio"

2. **Check Dependencies:**
   ```powershell
   npm install
   ```

3. **Check .env File:**
   - Ensure `.env` exists with correct values
   - Or use environment variables in `settings.json`

## Available MCP Tools

Once configured, you can use these tools in GitHub Copilot Chat:

- **Wiki**: Get pages, list pages, search pages
- **Repositories**: List repos, get files, search code, list branches
- **Work Items**: Get items, query with WIQL, create/update items
- **Pull Requests**: List PRs, get PR details, get comments
- **Builds**: List builds, get build details
- **Pipelines**: List pipelines, get run details
- **Releases**: List releases, get release details
- **Test Plans**: List test plans, get plan details
- **Generic API**: Make any Azure DevOps REST API call

## Example Queries

Try these in GitHub Copilot Chat:

- "Get work item 12345"
- "List all repositories in YourProject project"
- "Show me pull requests in repository X"
- "Search wiki pages for 'YourProject'"
- "Create a new work item with title 'Test Task'"

## Need Help?

- Check the main [README.md](README.md) for more details
- See [UPDATE-PAT.md](UPDATE-PAT.md) for PAT token management
- Review [FIX-PAT-QUICK.md](FIX-PAT-QUICK.md) for quick troubleshooting

