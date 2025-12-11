# How to Update Your Azure DevOps PAT Token

If you're seeing an error like "Access Denied: The Personal Access Token used has expired", follow these steps:

## Quick Fix

1. **Generate a new PAT token:**
   - Go to: https://dev.azure.com/YourOrganization/_usersSettings/tokens
   - Click "New Token"
   - Give it a name (e.g., "MCP Server Token")
   - Set expiration (recommend 90 days or custom)
   - Select scopes: **Code (read & write)**, **Work Items (read & write)**, **Wiki (read)**
   - Click "Create"
   - **Copy the token immediately** (you won't see it again!)

2. **Update the PAT using the helper script:**
   ```powershell
   cd C:\\path\\to\\mcp-ado
   .\scripts\update-pat.ps1 -NewPAT "your_new_token_here"
   ```

3. **Restart Cursor/VS Code:**
   - Close Cursor/VS Code completely
   - Reopen it

4. **If running locally, restart the MCP server:**
   ```powershell
   cd C:\\path\\to\\mcp-ado
   npm start
   ```

## Manual Update (if script doesn't work)

### Update .env file:
Edit `C:\\path\\to\\mcp-ado\.env`:
```
AZURE_DEVOPS_ORG=YourOrganization
AZURE_DEVOPS_PROJECT=YourProject
AZURE_DEVOPS_PAT=your_new_token_here
```

### Update Cursor settings.json:
1. Open Cursor settings: `Ctrl+,` or `File > Preferences > Settings`
2. Click the `{}` icon (Open Settings JSON)
3. Find the `mcp.servers.ado.env.AZURE_DEVOPS_PAT` value
4. Replace the old token with your new token
5. Save and restart Cursor

## Verify It Works

Try accessing a work item:
```
Get work item 12345
```

If you still get errors, check:
- Token has correct permissions
- Token hasn't expired
- Cursor/VS Code was restarted
- MCP server is running (if local)

