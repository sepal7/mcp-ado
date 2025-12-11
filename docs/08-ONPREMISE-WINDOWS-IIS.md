# On-Premise Windows IIS Deployment Guide

This guide covers deploying the MCP ADO Server on a Windows IIS server or Windows CI/CD server for on-premise/enterprise environments.

## Prerequisites

- Windows Server with IIS installed
- Node.js 18+ installed on the server
- Administrative access to the server
- Azure DevOps PAT token with appropriate permissions

## Option 1: IIS with iisnode (Recommended)

### Step 1: Install iisnode

1. **Download iisnode:**
   - Download from: https://github.com/Azure/iisnode/releases
   - Install the appropriate version for your Windows Server

2. **Verify Installation:**
   - Open IIS Manager
   - You should see "iisnode" in the Features View

### Step 2: Prepare the Application

1. **Copy Files to Server:**
   ```powershell
   # On your development machine
   cd C:\adoAzure\Github\mcp-ado
   
   # Copy to server (adjust path as needed)
   # Option A: Copy entire folder
   robocopy . \\your-server\c$\inetpub\mcp-ado /E /XD node_modules
   
   # Option B: Use deployment script
   ```

2. **Install Dependencies on Server:**
   ```powershell
   # On the server
   cd C:\inetpub\mcp-ado
   npm install --production
   ```

3. **Create .env File:**
   ```powershell
   # On the server
   cd C:\inetpub\mcp-ado
   copy .env.example .env
   # Edit .env with your actual values
   ```

### Step 3: Configure IIS Application

1. **Create New IIS Application:**
   - Open IIS Manager
   - Right-click "Sites" → "Add Website"
   - Site name: `mcp-ado`
   - Physical path: `C:\inetpub\mcp-ado`
   - Binding: Choose port (e.g., 8080) or use existing site
   - Click OK

2. **Create web.config:**
   Create `C:\inetpub\mcp-ado\web.config`:

   ```xml
   <?xml version="1.0" encoding="utf-8"?>
   <configuration>
     <system.webServer>
       <handlers>
         <add name="iisnode" path="server.js" verb="*" modules="iisnode"/>
       </handlers>
       <rewrite>
         <rules>
           <rule name="NodeInspector" patternSyntax="ECMAScript" stopProcessing="true">
             <match url="^server.js\/debug[\/]?" />
           </rule>
           <rule name="StaticContent">
             <action type="Rewrite" url="public{REQUEST_URI}"/>
           </rule>
           <rule name="DynamicContent">
             <conditions>
               <add input="{REQUEST_FILENAME}" matchType="IsFile" negate="True"/>
             </conditions>
             <action type="Rewrite" url="server.js"/>
           </rule>
         </rules>
       </rewrite>
       <security>
         <requestFiltering>
           <hiddenSegments>
             <remove segment="bin"/>
           </hiddenSegments>
         </requestFiltering>
       </security>
       <httpErrors existingResponse="PassThrough" />
       <iisnode 
         node_env="production"
         nodeProcessCountPerApplication="1"
         maxConcurrentRequestsPerProcess="1024"
         maxNamedPipeConnectionRetry="100"
         namedPipeConnectionRetryDelay="250"
         maxNamedPipeConnectionPoolSize="512"
         maxNamedPipePooledConnectionAge="30000"
         asyncCompletionThreadCount="0"
         initialRequestBufferSize="4096"
         maxRequestBufferSize="65536"
         watchedFiles="*.js"
         uncFileChangesPollingInterval="5000"
         gracefulShutdownTimeout="60000"
         loggingEnabled="true"
         logDirectory="iisnode"
         debuggingEnabled="false"
         debugHeaderEnabled="false"
         debuggerPortRange="5058-6058"
         debuggerPathSegment="debug"
         maxLogFileSizeInKB="128"
         maxTotalLogFileSizeInKB="1024"
         maxLogFiles="20"
         devErrorsEnabled="false"
         flushResponse="false"
         enableXFF="false"
         promoteServerVars=""
         configOverrides="iisnode.yml"
       />
     </system.webServer>
   </configuration>
   ```

3. **Set Application Pool:**
   - Select your application in IIS Manager
   - Click "Basic Settings" → "Select"
   - Choose or create an Application Pool
   - Set .NET CLR Version to "No Managed Code"
   - Set Managed Pipeline Mode to "Integrated"

4. **Configure Environment Variables:**
   - In IIS Manager, select your application
   - Double-click "Configuration Editor"
   - Navigate to `system.webServer/iisnode`
   - Add environment variables or use web.config:

   ```xml
   <iisnode>
     <environmentVariables>
       <add name="AZURE_DEVOPS_ORG" value="YourOrganization" />
       <add name="AZURE_DEVOPS_PROJECT" value="YourProject" />
       <add name="AZURE_DEVOPS_PAT" value="your_pat_token" />
     </environmentVariables>
   </iisnode>
   ```

### Step 4: Set Permissions

```powershell
# Grant IIS_IUSRS read/execute permissions
icacls "C:\inetpub\mcp-ado" /grant "IIS_IUSRS:(OI)(CI)RX" /T

# Grant Application Pool identity permissions
$appPoolName = "mcp-ado"
$appPool = Get-IISAppPool -Name $appPoolName
icacls "C:\inetpub\mcp-ado" /grant "${env:COMPUTERNAME}\$($appPool.ProcessModel.IdentityType):(OI)(CI)RX" /T
```

### Step 5: Test the Deployment

1. **Start the Application:**
   - In IIS Manager, right-click your site → "Manage Website" → "Start"

2. **Test the Endpoint:**
   ```powershell
   # Test if server is responding
   Invoke-WebRequest -Uri "http://localhost:8080" -Method GET
   ```

3. **Check Logs:**
   - Logs are in: `C:\inetpub\mcp-ado\iisnode\`
   - Check Windows Event Viewer for IIS errors

## Option 2: Windows Service (Alternative)

### Step 1: Install node-windows

```powershell
npm install -g node-windows
```

### Step 2: Create Service Script

Create `install-service.js`:

```javascript
const Service = require('node-windows').Service;
const path = require('path');

const svc = new Service({
  name: 'MCP ADO Server',
  description: 'MCP Server for Azure DevOps',
  script: path.join(__dirname, 'server.js'),
  env: [
    {
      name: "AZURE_DEVOPS_ORG",
      value: "YourOrganization"
    },
    {
      name: "AZURE_DEVOPS_PROJECT",
      value: "YourProject"
    },
    {
      name: "AZURE_DEVOPS_PAT",
      value: "your_pat_token"
    }
  ]
});

svc.on('install', function() {
  console.log('Service installed successfully');
  svc.start();
});

svc.install();
```

### Step 3: Install and Start Service

```powershell
# Run as Administrator
node install-service.js

# Or manually:
sc create "MCP ADO Server" binPath= "node C:\inetpub\mcp-ado\server.js" start= auto
sc start "MCP ADO Server"
```

## Option 3: Windows Task Scheduler

### Step 1: Create Startup Script

Create `start-server.bat`:

```batch
@echo off
cd /d C:\inetpub\mcp-ado
set AZURE_DEVOPS_ORG=YourOrganization
set AZURE_DEVOPS_PROJECT=YourProject
set AZURE_DEVOPS_PAT=your_pat_token
node server.js
```

### Step 2: Create Scheduled Task

```powershell
$action = New-ScheduledTaskAction -Execute "C:\inetpub\mcp-ado\start-server.bat"
$trigger = New-ScheduledTaskTrigger -AtStartup
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
Register-ScheduledTask -TaskName "MCP ADO Server" -Action $action -Trigger $trigger -Principal $principal
```

## Configuration for MCP Clients

Once deployed, configure your MCP clients to connect to the server:

### For Cursor/VS Code (Local MCP Client)

Since the server runs on-premise, you can still use local server configuration:

```json
{
  "mcp": {
    "servers": {
      "ado": {
        "command": "node",
        "args": ["C:\\inetpub\\mcp-ado\\server.js"],
        "env": {
          "AZURE_DEVOPS_ORG": "YourOrganization",
          "AZURE_DEVOPS_PROJECT": "YourProject",
          "AZURE_DEVOPS_PAT": "your_pat_token"
        }
      }
    }
  }
}
```

### For Team Access

If the server is on a shared network location:

```json
{
  "mcp": {
    "servers": {
      "ado": {
        "command": "node",
        "args": ["\\\\your-server\\share\\mcp-ado\\server.js"],
        "env": {
          "AZURE_DEVOPS_ORG": "YourOrganization",
          "AZURE_DEVOPS_PROJECT": "YourProject",
          "AZURE_DEVOPS_PAT": "your_pat_token"
        }
      }
    }
  }
}
```

## Security Considerations

1. **PAT Token Security:**
   - Store PAT tokens securely (Windows Credential Manager or encrypted config)
   - Use service accounts with minimal permissions
   - Rotate tokens regularly

2. **Network Security:**
   - Use Windows Firewall to restrict access
   - Consider using HTTPS if exposing externally
   - Use VPN for remote team access

3. **File Permissions:**
   - Restrict access to .env file
   - Use Windows ACLs to protect sensitive files

## Troubleshooting

### Server Not Starting

1. **Check Node.js:**
   ```powershell
   node --version  # Should be 18+
   ```

2. **Check Logs:**
   - IIS: `C:\inetpub\mcp-ado\iisnode\`
   - Windows Service: Event Viewer → Windows Logs → Application
   - Task Scheduler: Task Scheduler → Task History

3. **Check Permissions:**
   ```powershell
   # Verify IIS can access the folder
   icacls "C:\inetpub\mcp-ado"
   ```

### Connection Issues

1. **Test Server Manually:**
   ```powershell
   cd C:\inetpub\mcp-ado
   node server.js
   ```

2. **Check Firewall:**
   ```powershell
   # Allow Node.js through firewall
   New-NetFirewallRule -DisplayName "MCP ADO Server" -Direction Inbound -Program "C:\Program Files\nodejs\node.exe" -Action Allow
   ```

## Monitoring

### Windows Performance Monitor

Monitor Node.js process:
- Process → Node.exe → CPU, Memory
- Process → Node.exe → Handle Count

### Event Viewer

Check Windows Event Viewer for:
- Application errors
- Service start/stop events
- IIS errors

## Maintenance

### Updating the Server

```powershell
# Stop the service/application
# Copy new files
# Restart the service/application
```

### Log Rotation

Configure log rotation in web.config or use Windows log management tools.

## Related Documentation

- [01-SETUP.md](01-SETUP.md) - General setup guide
- [02-CURSOR-SETUP.md](02-CURSOR-SETUP.md) - Cursor configuration
- [03-VSCODE-SETUP.md](03-VSCODE-SETUP.md) - VS Code configuration
- [azure/README.md](../azure/README.md) - Azure cloud deployment

