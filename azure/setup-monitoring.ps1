# Setup Azure Monitoring for MCP ADO Server
# This script creates Application Insights and Azure Dashboard for monitoring MCP server activity
# If SSL certificate issues occur, it will fall back to REST API method

param(
    [string]$ResourceGroup = "rg-00-integration-mcp-dv-eus2-001",
    [string]$Location = "eastus2",
    [string]$AppInsightsName = "appi-00-dv-mcp-001",
    [string]$DashboardName = "MCP-ADO-Server-Monitoring",
    [switch]$UseRestApi = $false
)

$ErrorActionPreference = "Stop"

Write-Host "Setting up Azure Monitoring for MCP ADO Server" -ForegroundColor Cyan
Write-Host ""

# Check if REST API method should be used
if ($UseRestApi -or $env:AZURE_CLI_SSL_ISSUE -eq "true") {
    Write-Host "Using REST API method (bypassing CLI SSL issues)..." -ForegroundColor Yellow
    & "$PSScriptRoot\setup-monitoring-rest.ps1" -ResourceGroup $ResourceGroup -Location $Location -AppInsightsName $AppInsightsName -DashboardName $DashboardName
    exit $LASTEXITCODE
}

Write-Host ""

# Check Azure login
Write-Host "1. Checking Azure login..." -ForegroundColor Yellow
$account = az account show 2>$null
if (-not $account) {
    Write-Host "   WARNING: Not logged in. Please login:" -ForegroundColor Yellow
    Write-Host "      az login" -ForegroundColor White
    exit 1
}
Write-Host "   SUCCESS: Logged into Azure" -ForegroundColor Green

# Check if resource group exists
Write-Host ""
Write-Host "2. Checking resource group..." -ForegroundColor Yellow
$rg = az group show --name $ResourceGroup 2>$null
if (-not $rg) {
    Write-Host "   Creating resource group: $ResourceGroup" -ForegroundColor Cyan
    az group create --name $ResourceGroup --location $Location
    Write-Host "   SUCCESS: Resource group created" -ForegroundColor Green
} else {
    Write-Host "   SUCCESS: Resource group exists" -ForegroundColor Green
}

# Create Application Insights
Write-Host ""
Write-Host "3. Creating Application Insights..." -ForegroundColor Yellow
try {
    $appInsights = az monitor app-insights component show --app $AppInsightsName --resource-group $ResourceGroup 2>&1
    if ($LASTEXITCODE -ne 0 -or $appInsights -match "SSL|CERTIFICATE|certificate verify") {
        throw "SSL Certificate Error"
    }
    $appInsights = $appInsights | ConvertFrom-Json
    Write-Host "   SUCCESS: Application Insights exists" -ForegroundColor Green
} catch {
    if ($_.Exception.Message -match "SSL|CERTIFICATE" -or $appInsights -match "SSL|CERTIFICATE") {
        Write-Host "   WARNING: SSL certificate issue detected. Switching to REST API method..." -ForegroundColor Yellow
        Write-Host ""
        & "$PSScriptRoot\setup-monitoring-rest.ps1" -ResourceGroup $ResourceGroup -Location $Location -AppInsightsName $AppInsightsName -DashboardName $DashboardName
        exit $LASTEXITCODE
    }
    
    Write-Host "   Creating Application Insights: $AppInsightsName" -ForegroundColor Cyan
    try {
        $appInsights = az monitor app-insights component create `
            --app $AppInsightsName `
            --location $Location `
            --resource-group $ResourceGroup `
            --application-type web `
            --kind web `
            --retention-time 90 2>&1 | ConvertFrom-Json
        
        if ($LASTEXITCODE -ne 0 -or $appInsights -match "SSL|CERTIFICATE") {
            throw "SSL Certificate Error"
        }
        Write-Host "   SUCCESS: Application Insights created" -ForegroundColor Green
    } catch {
        if ($_.Exception.Message -match "SSL|CERTIFICATE" -or $appInsights -match "SSL|CERTIFICATE") {
            Write-Host "   WARNING: SSL certificate issue. Switching to REST API method..." -ForegroundColor Yellow
            Write-Host ""
            & "$PSScriptRoot\setup-monitoring-rest.ps1" -ResourceGroup $ResourceGroup -Location $Location -AppInsightsName $AppInsightsName -DashboardName $DashboardName
            exit $LASTEXITCODE
        }
        throw
    }
}

# Get connection string
Write-Host ""
Write-Host "4. Getting Application Insights connection string..." -ForegroundColor Yellow
$connectionString = az monitor app-insights component show `
    --app $AppInsightsName `
    --resource-group $ResourceGroup `
    --query connectionString `
    --output tsv

if ($connectionString) {
    Write-Host "   SUCCESS: Connection string retrieved" -ForegroundColor Green
    Write-Host ""
    Write-Host "   Connection String:" -ForegroundColor Cyan
    Write-Host "   $connectionString" -ForegroundColor White
    Write-Host ""
    Write-Host "   WARNING: Save this connection string! You'll need it to configure the MCP server." -ForegroundColor Yellow
    Write-Host ""
    
    # Save to file
    $connectionString | Out-File -FilePath "appinsights-connection-string.txt" -Encoding utf8
    Write-Host "   Connection string saved to: appinsights-connection-string.txt" -ForegroundColor Green
} else {
    Write-Host "   ERROR: Failed to get connection string" -ForegroundColor Red
    exit 1
}

# Create Dashboard
Write-Host ""
Write-Host "5. Creating Azure Dashboard..." -ForegroundColor Yellow

# Read dashboard template
$dashboardPath = Join-Path $PSScriptRoot "mcp-monitoring-dashboard.json"
if (-not (Test-Path $dashboardPath)) {
    Write-Host "   ERROR: Dashboard template not found: $dashboardPath" -ForegroundColor Red
    Write-Host "   Please ensure mcp-monitoring-dashboard.json exists" -ForegroundColor Yellow
    exit 1
}

# Get subscription ID
$subscriptionId = (az account show --query id --output tsv)

# Update dashboard JSON with actual resource IDs
$dashboardJson = Get-Content $dashboardPath -Raw | ConvertFrom-Json
$dashboardJson.name = $DashboardName
$dashboardJson.properties.lenses[0].order = 0
$dashboardJson.properties.lenses[0].parts[0].metadata.settings.content.definition.query = $dashboardJson.properties.lenses[0].parts[0].metadata.settings.content.definition.query -replace "YOUR_APPINSIGHTS_NAME", $AppInsightsName

# Create dashboard
Write-Host "   Creating dashboard: $DashboardName" -ForegroundColor Cyan
$dashboardJsonString = $dashboardJson | ConvertTo-Json -Depth 100 -Compress

# Use Azure CLI to create dashboard
$dashboardId = "/subscriptions/$subscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.Portal/dashboards/$DashboardName"
az portal dashboard create `
    --name $DashboardName `
    --resource-group $ResourceGroup `
    --location $Location `
    --input-path $dashboardPath 2>$null

if ($LASTEXITCODE -eq 0) {
    Write-Host "   SUCCESS: Dashboard created" -ForegroundColor Green
} else {
    Write-Host "   WARNING: Dashboard creation may have failed. You can create it manually in Azure Portal." -ForegroundColor Yellow
    Write-Host "   Dashboard JSON saved to: $dashboardPath" -ForegroundColor Cyan
}

# Summary
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "SUCCESS: Monitoring Setup Complete!" -ForegroundColor Green
Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Configure MCP Server with Application Insights:" -ForegroundColor White
Write-Host "   Set environment variable:" -ForegroundColor Gray
Write-Host "   APPLICATIONINSIGHTS_CONNECTION_STRING='$connectionString'" -ForegroundColor Cyan
Write-Host ""
Write-Host "2. Update Cursor settings.json:" -ForegroundColor White
Write-Host "   Add APPLICATIONINSIGHTS_CONNECTION_STRING to the env section" -ForegroundColor Gray
Write-Host ""
Write-Host "3. View Dashboard:" -ForegroundColor White
$dashboardUrl = "https://portal.azure.com/#@/dashboard/arm/subscriptions/$subscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.Portal/dashboards/$DashboardName"
Write-Host "   $dashboardUrl" -ForegroundColor Cyan
Write-Host ""
Write-Host "4. View Application Insights:" -ForegroundColor White
$appInsightsUrl = "https://portal.azure.com/#@/resource/subscriptions/$subscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.Insights/components/$AppInsightsName"
Write-Host "   $appInsightsUrl" -ForegroundColor Cyan
Write-Host ""
Write-Host "Resources Created:" -ForegroundColor Yellow
Write-Host "   - Application Insights: $AppInsightsName" -ForegroundColor White
Write-Host "   - Dashboard: $DashboardName" -ForegroundColor White
Write-Host "   - Resource Group: $ResourceGroup" -ForegroundColor White
Write-Host ""

