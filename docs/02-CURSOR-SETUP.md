# Cursor IDE Setup Guide

This guide will help you configure this MCP server to work with Cursor IDE.

## Prerequisites

- ✅ Cursor IDE installed
- ✅ Node.js 18+ installed and in PATH
- ✅ MCP server directory cloned and dependencies installed (`npm install`)

## Step 1: Configure Cursor Settings

1. **Open Cursor Settings:**
   - Press `Ctrl+,` (or `Cmd+,` on Mac)
   - Or go to: `File → Preferences → Settings`

2. **Open Settings JSON:**
   - Click the `{}` icon in the top right (Open Settings JSON)
   - Or use: `Ctrl+Shift+P` → "Preferences: Open User Settings (JSON)"

3. **Add MCP Server Configuration:**

   Add this configuration to your `settings.json`:

   ```json
   {
     "mcp": {
       "servers": {
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
3. Name it "MCP Server Token"
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

This will update both `.env` and Cursor settings automatically.

## Step 4: Restart Cursor

**CRITICAL:** You must completely restart Cursor for MCP configuration to take effect:

1. Close all Cursor windows
2. Make sure Cursor is fully closed (check Task Manager if needed)
3. Reopen Cursor

## Step 5: Verify MCP Tools Are Available

1. **Open Cursor Chat:**
   - Press `Ctrl+L` (or `Cmd+L` on Mac)
   - Or click the chat icon in the sidebar

2. **Test the Connection:**
   - Ask: "Get work item 12345 from Azure DevOps"
   - Or: "List repositories in the YourProject project"

3. **The MCP server should respond** with data from Azure DevOps!

## Troubleshooting

### MCP Tools Not Appearing

1. **Check Server Path:**
   - Verify the path in `settings.json` is correct
   - Use absolute path, not relative
   - Check file exists: `Test-Path "C:\\path\\to\\mcp-ado\server.js"`

2. **Check Node.js:**
   - Open terminal: `node --version` (should be 18+)
   - Verify Node.js is in PATH

3. **Check Cursor Output:**
   - Go to: `View → Output`
   - Select "MCP" or "Cursor" from dropdown
   - Look for MCP-related errors

4. **Verify Settings JSON Syntax:**
   - Use a JSON validator to check syntax
   - Ensure no trailing commas
   - Ensure all strings are properly quoted

5. **Restart Cursor:**
   - Fully close and reopen Cursor
   - This is often the solution!

### Authentication Errors

If you see "401 Unauthorized" or "Access Denied":

1. **Check PAT Token:**
   - Verify token hasn't expired
   - Regenerate if needed: https://dev.azure.com/YourOrganization/_usersSettings/tokens

2. **Update Token:**
   ```powershell
   .\scripts\update-pat.ps1 -NewPAT "new_token"
   ```

3. **Restart Cursor** after updating

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

Once configured, you can use these tools in Cursor:

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

Try these in Cursor's chat:

- "Get work item 12345"
- "List all repositories in YourProject project"
- "Show me pull requests in repository X"
- "Search wiki pages for 'YourProject'"
- "Create a new work item with title 'Test Task'"

## Related Documentation

- Main setup: [01-SETUP.md](01-SETUP.md)
- PAT management: [04-PAT-MANAGEMENT.md](04-PAT-MANAGEMENT.md)
- Restart server: [05-RESTART-SERVER.md](05-RESTART-SERVER.md)

