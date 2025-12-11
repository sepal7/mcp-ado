# PowerShell script to update Azure DevOps PAT token
# This script updates the PAT in both .env file and Cursor settings.json

param(
    [Parameter(Mandatory=$true)]
    [string]$NewPAT,
    
    [string]$Org = "",
    [string]$Project = ""
)

Write-Host "Updating Azure DevOps PAT token..." -ForegroundColor Cyan

# Update .env file (in parent directory)
$envFile = Join-Path (Split-Path $PSScriptRoot -Parent) ".env"
if (Test-Path $envFile) {
    $content = Get-Content $envFile
    $currentOrg = ""
    $currentProject = ""
    
    # Read current values
    $content | ForEach-Object {
        if ($_ -match "^AZURE_DEVOPS_ORG=(.+)") {
            $currentOrg = $matches[1]
        } elseif ($_ -match "^AZURE_DEVOPS_PROJECT=(.+)") {
            $currentProject = $matches[1]
        }
    }
    
    # Use provided values or keep existing
    $finalOrg = if ($Org) { $Org } else { $currentOrg }
    $finalProject = if ($Project) { $Project } else { $currentProject }
    
    # If no existing values and none provided, use defaults
    if (-not $finalOrg) { $finalOrg = "YourOrganization" }
    if (-not $finalProject) { $finalProject = "YourProject" }
    
    $updated = $content | ForEach-Object {
        if ($_ -match "^AZURE_DEVOPS_PAT=") {
            "AZURE_DEVOPS_PAT=$NewPAT"
        } elseif ($_ -match "^AZURE_DEVOPS_ORG=") {
            "AZURE_DEVOPS_ORG=$finalOrg"
        } elseif ($_ -match "^AZURE_DEVOPS_PROJECT=") {
            "AZURE_DEVOPS_PROJECT=$finalProject"
        } else {
            $_
        }
    }
    $updated | Set-Content $envFile
    Write-Host "[OK] Updated .env file" -ForegroundColor Green
} else {
    Write-Host "Creating .env file..." -ForegroundColor Yellow
    $finalOrg = if ($Org) { $Org } else { "YourOrganization" }
    $finalProject = if ($Project) { $Project } else { "YourProject" }
    @"
AZURE_DEVOPS_ORG=$finalOrg
AZURE_DEVOPS_PROJECT=$finalProject
AZURE_DEVOPS_PAT=$NewPAT
"@ | Set-Content $envFile
    Write-Host "[OK] Created .env file" -ForegroundColor Green
}

# Update Cursor settings.json
$settingsPath = "$env:APPDATA\Cursor\User\settings.json"
if (Test-Path $settingsPath) {
    try {
        $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
        
        # Ensure mcp.servers.ado structure exists
        if (-not $settings.mcp) {
            $settings | Add-Member -MemberType NoteProperty -Name "mcp" -Value @{}
        }
        if (-not $settings.mcp.servers) {
            $settings.mcp | Add-Member -MemberType NoteProperty -Name "servers" -Value @{}
        }
        if (-not $settings.mcp.servers.ado) {
            $serverPath = Join-Path (Split-Path $PSScriptRoot -Parent) "server.js"
            $settings.mcp.servers | Add-Member -MemberType NoteProperty -Name "ado" -Value @{
                command = "node"
                args = @($serverPath)
                env = @{}
            }
        }
        
        # Update PAT and other env vars
        if (-not $settings.mcp.servers.ado.env) {
            $settings.mcp.servers.ado | Add-Member -MemberType NoteProperty -Name "env" -Value @{}
        }
        
        # Preserve existing org/project if not provided, otherwise use provided or existing
        $currentOrg = $settings.mcp.servers.ado.env.AZURE_DEVOPS_ORG
        $currentProject = $settings.mcp.servers.ado.env.AZURE_DEVOPS_PROJECT
        
        $finalOrg = if ($Org) { $Org } elseif ($currentOrg) { $currentOrg } else { "YourOrganization" }
        $finalProject = if ($Project) { $Project } elseif ($currentProject) { $currentProject } else { "YourProject" }
        
        $settings.mcp.servers.ado.env.AZURE_DEVOPS_ORG = $finalOrg
        $settings.mcp.servers.ado.env.AZURE_DEVOPS_PROJECT = $finalProject
        $settings.mcp.servers.ado.env.AZURE_DEVOPS_PAT = $NewPAT
        
        # Ensure server path is correct
        $serverPath = Join-Path (Split-Path $PSScriptRoot -Parent) "server.js"
        $settings.mcp.servers.ado.args = @($serverPath)
        
        # Preserve Application Insights connection string if it exists
        if ($settings.mcp.servers.ado.env.APPLICATIONINSIGHTS_CONNECTION_STRING) {
            # Keep existing value
        }
        
        # Convert back to JSON with proper formatting
        $json = $settings | ConvertTo-Json -Depth 10
        $json | Set-Content $settingsPath -Encoding UTF8
        
        Write-Host "[OK] Updated Cursor settings.json" -ForegroundColor Green
    } catch {
        Write-Host "[ERROR] Error updating Cursor settings.json: $_" -ForegroundColor Red
        Write-Host "Please manually update the PAT in Cursor settings.json" -ForegroundColor Yellow
    }
} else {
    Write-Host "[WARNING] Cursor settings.json not found at: $settingsPath" -ForegroundColor Yellow
    Write-Host "Please manually configure MCP server in Cursor settings" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "PAT update complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Restart Cursor/VS Code completely" -ForegroundColor White
Write-Host "2. If running locally, restart the MCP server (npm start)" -ForegroundColor White
Write-Host "3. Test the connection by trying to access a work item" -ForegroundColor White

