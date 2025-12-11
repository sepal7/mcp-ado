# 🔧 Quick Fix for Expired PAT Token

## Step 1: Get a New PAT Token

1. **Open Azure DevOps:**
   - Go to: https://dev.azure.com/YourOrganization/_usersSettings/tokens
   - Or: Azure DevOps → User Settings → Personal Access Tokens

2. **Create New Token:**
   - Click **"New Token"**
   - Name: `MCP Server Token`
   - Organization: `YourOrganization`
   - Expiration: Choose 90 days or custom
   - **Scopes (IMPORTANT - Select these):**
     - ✅ Code (Read & write)
     - ✅ Work Items (Read & write)
     - ✅ Wiki (Read)
     - ✅ Build (Read)
     - ✅ Release (Read)
   - Click **"Create"**
   - **COPY THE TOKEN IMMEDIATELY** (you won't see it again!)

## Step 2: Update the Token

Run this command in PowerShell (replace `YOUR_NEW_TOKEN` with the token you copied):

```powershell
cd C:\\path\\to\\mcp-ado
.\scripts\update-pat.ps1 -NewPAT "YOUR_NEW_TOKEN"
```

**Example:**
```powershell
.\update-pat.ps1 -NewPAT "9CoCmOPVCKjxAzZQLTsPcvUNhJrOPIbJjCxMhtfee1Wad6lqcbATJQQJ99BFACAAAAAAv6vNAAASAZDO3Lwm"
```

## Step 3: Restart Everything

1. **Close Cursor/VS Code completely** (not just the window - fully exit)
2. **Reopen Cursor/VS Code**
3. **If running MCP server locally**, restart it:
   ```powershell
   cd C:\\path\\to\\mcp-ado
   npm start
   ```

## Step 4: Test It Works

Try this in Cursor's chat:
```
Get work item 12345 from Azure DevOps
```

If it works, you're all set! ✅

## Troubleshooting

**Still getting errors?**
- Make sure you copied the entire token (no spaces)
- Verify token has correct scopes
- Check that Cursor was fully restarted
- If running locally, ensure `npm start` is running

**Need help?**
- Check `UPDATE-PAT.md` for detailed instructions
- Check Cursor Output panel for MCP errors

