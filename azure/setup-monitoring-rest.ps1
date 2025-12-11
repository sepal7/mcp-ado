# Setup Azure Monitoring for MCP ADO Server using REST API
# This bypasses Azure CLI SSL certificate issues

param(
    [string]$ResourceGroup = "rg-00-integration-mcp-dv-eus2-001",
    [string]$Location = "eastus2",
    [string]$AppInsightsName = "appi-00-dv-mcp-001",
    [string]$DashboardName = "MCP-ADO-Server-Monitoring"
)

$ErrorActionPreference = "Stop"

Write-Host "Setting up Azure Monitoring for MCP ADO Server (REST API Method)" -ForegroundColor Cyan
Write-Host ""

# Get Azure access token
Write-Host "1. Getting Azure access token..." -ForegroundColor Yellow
try {
    $account = az account show --output json 2>$null | ConvertFrom-Json
    if (-not $account) {
        Write-Host "   ERROR: Not logged in. Please run: az login" -ForegroundColor Red
        exit 1
    }
    
    $subscriptionId = $account.id
    $tenantId = $account.tenantId
    
    Write-Host "   SUCCESS: Using subscription: $($account.name)" -ForegroundColor Green
    
    # Get access token
    $tokenResponse = az account get-access-token --output json 2>$null | ConvertFrom-Json
    if (-not $tokenResponse) {
        Write-Host "   ERROR: Failed to get access token" -ForegroundColor Red
        exit 1
    }
    
    $accessToken = $tokenResponse.accessToken
    Write-Host "   SUCCESS: Access token obtained" -ForegroundColor Green
} catch {
    Write-Host "   ERROR: Failed to authenticate. Error: $_" -ForegroundColor Red
    exit 1
}

# Check if resource group exists
Write-Host ""
Write-Host "2. Checking resource group..." -ForegroundColor Yellow
$rgUrl = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$ResourceGroup`?api-version=2021-04-01"
$rgHeaders = @{
    "Authorization" = "Bearer $accessToken"
    "Content-Type" = "application/json"
}

try {
    $rgCheck = Invoke-RestMethod -Uri $rgUrl -Method GET -Headers $rgHeaders -ErrorAction SilentlyContinue
    Write-Host "   SUCCESS: Resource group exists" -ForegroundColor Green
} catch {
    Write-Host "   Creating resource group: $ResourceGroup" -ForegroundColor Cyan
    $rgBody = @{
        location = $Location
    } | ConvertTo-Json
    
    try {
        Invoke-RestMethod -Uri $rgUrl -Method PUT -Headers $rgHeaders -Body $rgBody | Out-Null
        Write-Host "   SUCCESS: Resource group created" -ForegroundColor Green
    } catch {
        Write-Host "   ERROR: Failed to create resource group: $_" -ForegroundColor Red
        exit 1
    }
}

# Create Application Insights using REST API
Write-Host ""
Write-Host "3. Creating Application Insights..." -ForegroundColor Yellow
$appInsightsUrl = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.Insights/components/$AppInsightsName`?api-version=2020-02-02"

# Check if exists
try {
    $existing = Invoke-RestMethod -Uri $appInsightsUrl -Method GET -Headers $rgHeaders -ErrorAction SilentlyContinue
    Write-Host "   SUCCESS: Application Insights exists" -ForegroundColor Green
    $instrumentationKey = $existing.properties.InstrumentationKey
    $connectionString = $existing.properties.ConnectionString
} catch {
    Write-Host "   Creating Application Insights: $AppInsightsName" -ForegroundColor Cyan
    
    $appInsightsBody = @{
        kind = "web"
        location = $Location
        properties = @{
            Application_Type = "web"
            Flow_Type = "Redfield"
            Request_Source = "rest"
        }
    } | ConvertTo-Json -Depth 10
    
    try {
        $appInsights = Invoke-RestMethod -Uri $appInsightsUrl -Method PUT -Headers $rgHeaders -Body $appInsightsBody
        Write-Host "   SUCCESS: Application Insights created" -ForegroundColor Green
        $instrumentationKey = $appInsights.properties.InstrumentationKey
        $connectionString = $appInsights.properties.ConnectionString
    } catch {
        Write-Host "   ERROR: Failed to create Application Insights: $_" -ForegroundColor Red
        Write-Host "   Response: $($_.ErrorDetails.Message)" -ForegroundColor Yellow
        exit 1
    }
}

# Get connection string if not already retrieved
if (-not $connectionString) {
    Write-Host ""
    Write-Host "4. Getting connection string..." -ForegroundColor Yellow
    try {
        $appInsights = Invoke-RestMethod -Uri $appInsightsUrl -Method GET -Headers $rgHeaders
        $connectionString = $appInsights.properties.ConnectionString
        if (-not $connectionString) {
            # Construct connection string from instrumentation key
            $ingestionEndpoint = "https://$Location.in.applicationinsights.azure.com/"
            $connectionString = "InstrumentationKey=$instrumentationKey;IngestionEndpoint=$ingestionEndpoint"
        }
        Write-Host "   SUCCESS: Connection string retrieved" -ForegroundColor Green
    } catch {
        Write-Host "   WARNING: Could not retrieve connection string. You can get it from Azure Portal." -ForegroundColor Yellow
    }
}

if ($connectionString) {
    Write-Host ""
    Write-Host "   Connection String:" -ForegroundColor Cyan
    Write-Host "   $connectionString" -ForegroundColor White
    Write-Host ""
    Write-Host "   WARNING: Save this connection string! You'll need it to configure the MCP server." -ForegroundColor Yellow
    Write-Host ""
    
    # Save to file
    $connectionString | Out-File -FilePath "appinsights-connection-string.txt" -Encoding utf8
    Write-Host "   Connection string saved to: appinsights-connection-string.txt" -ForegroundColor Green
}

# Dashboard creation - provide manual instructions
Write-Host ""
Write-Host "5. Dashboard Setup..." -ForegroundColor Yellow
Write-Host "   Dashboard creation via REST API is complex." -ForegroundColor Cyan
Write-Host "   Please create it manually in Azure Portal or use the provided JSON file." -ForegroundColor Cyan
Write-Host ""
Write-Host "   Dashboard JSON file: mcp-monitoring-dashboard.json" -ForegroundColor White
Write-Host "   Instructions: MCP-MONITORING-SETUP.md" -ForegroundColor White

# Summary
Write-Host ""
Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host "SUCCESS: Monitoring Setup Complete!" -ForegroundColor Green
Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Configure MCP Server with Application Insights:" -ForegroundColor White
Write-Host "   Set environment variable:" -ForegroundColor Gray
if ($connectionString) {
    Write-Host "   APPLICATIONINSIGHTS_CONNECTION_STRING='$connectionString'" -ForegroundColor Cyan
} else {
    Write-Host "   Get connection string from Azure Portal" -ForegroundColor Cyan
}
Write-Host ""
Write-Host "2. Update Cursor settings.json:" -ForegroundColor White
Write-Host "   Add APPLICATIONINSIGHTS_CONNECTION_STRING to the env section" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Create Dashboard (Manual):" -ForegroundColor White
Write-Host "   a. Go to Azure Portal -> Dashboards" -ForegroundColor Gray
Write-Host "   b. Click 'New dashboard'" -ForegroundColor Gray
Write-Host "   c. Click 'Upload' and select: mcp-monitoring-dashboard.json" -ForegroundColor Gray
Write-Host "   d. Update Application Insights name in queries if needed" -ForegroundColor Gray
Write-Host ""
Write-Host "4. View Application Insights:" -ForegroundColor White
$appInsightsUrl = "https://portal.azure.com/#@/resource/subscriptions/$subscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.Insights/components/$AppInsightsName"
Write-Host "   $appInsightsUrl" -ForegroundColor Cyan
Write-Host ""
Write-Host "Resources Created:" -ForegroundColor Yellow
Write-Host "   - Application Insights: $AppInsightsName" -ForegroundColor White
Write-Host "   - Resource Group: $ResourceGroup" -ForegroundColor White
Write-Host "   - Dashboard: Create manually (see step 3)" -ForegroundColor White
Write-Host ""

