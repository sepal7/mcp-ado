# How to Restart MCP Server in Cursor

## Quick Method: Restart Cursor IDE

The easiest way to restart the MCP server is to restart Cursor IDE:

1. **Close Cursor completely:**
   - Click `File → Exit` (or press `Alt+F4`)
   - Make sure all Cursor windows are closed
   - Check Task Manager to ensure no Cursor processes are running

2. **Reopen Cursor:**
   - Launch Cursor from your Start menu or desktop shortcut
   - Wait for it to fully load

3. **Verify MCP Server is Running:**
   - The MCP server will automatically start when Cursor loads
   - Try using an MCP tool to verify it's working

## Alternative: Reload Window (May Work)

If you want to try without fully restarting:

1. Press `Ctrl+Shift+P` to open Command Palette
2. Type: `Developer: Reload Window`
3. Press Enter

**Note:** This may not always reload MCP servers, so a full restart is more reliable.

## Verify MCP Server is Working

After restarting, test the MCP server:

1. Open Cursor Chat (`Ctrl+L`)
2. Ask: "List repositories in the YourProject project"
3. If it works, the MCP server has restarted successfully!

## Troubleshooting

If the MCP server still doesn't work after restarting:

1. **Check MCP Configuration:**
   - Settings → Features → Model Context Protocol
   - Verify the server path is correct: `C:\\path\\to\\mcp-ado\server.js`

2. **Check Node.js:**
   - Open terminal in Cursor
   - Run: `node --version` (should be 18+)

3. **Check Server File:**
   - Verify `C:\\path\\to\\mcp-ado\server.js` exists
   - Verify the file was saved with your changes

4. **Check Output Logs:**
   - View → Output
   - Look for MCP-related errors


