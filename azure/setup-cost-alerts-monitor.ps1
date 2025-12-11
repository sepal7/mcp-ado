# Azure Monitor Cost Alert Setup for MCP Server
# Alternative approach when Cost Management budgets are not available

param(
    [string]$ResourceGroupName = "rg-00-integration-mcp-dv-eus2-001",
    [string]$SubscriptionId = "71ec4f78-f42e-41e1-96f4-b75a69a53851",
    [string]$EmailAddress = "your-email@example.com"
)

Write-Host "Setting up Azure Monitor Cost Alerts for MCP Server" -ForegroundColor Cyan
Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor Yellow
Write-Host ""

# Set subscription
az account set --subscription $SubscriptionId

# Create Action Group for email notifications
$ActionGroupName = "MCP-Server-Cost-Alerts-AG"
Write-Host "Creating Action Group: $ActionGroupName" -ForegroundColor Cyan

az monitor action-group create `
    --name $ActionGroupName `
    --resource-group $ResourceGroupName `
    --short-name "MCPCost" `
    --email-receivers name="CostAlertEmail" email-address=$EmailAddress `
    --output none

if ($LASTEXITCODE -eq 0) {
    Write-Host "Action Group created successfully" -ForegroundColor Green
} else {
    Write-Host "Action Group may already exist, continuing..." -ForegroundColor Yellow
}

# Get Action Group ID
$ActionGroupId = az monitor action-group show --name $ActionGroupName --resource-group $ResourceGroupName --query id --output tsv

Write-Host ""
Write-Host "Setting up cost alerts via Azure Portal instructions..." -ForegroundColor Cyan
Write-Host ""
Write-Host "Since Cost Management budgets require Enterprise Agreement subscription," -ForegroundColor Yellow
Write-Host "please set up cost alerts manually in Azure Portal:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Go to: https://portal.azure.com/#view/Microsoft_Azure_CostManagement/Menu/~/CostAlerts" -ForegroundColor White
Write-Host "2. Click 'Add' to create a new cost alert" -ForegroundColor White
Write-Host "3. Configure:" -ForegroundColor White
Write-Host "   - Alert name: MCP-Server-Monthly-Budget" -ForegroundColor White
Write-Host "   - Scope: Resource Group = $ResourceGroupName" -ForegroundColor White
Write-Host "   - Condition: Cost threshold = `$30" -ForegroundColor White
Write-Host "   - Action Group: $ActionGroupName" -ForegroundColor White
Write-Host ""
Write-Host "Alternative: Use Azure Advisor Cost Recommendations" -ForegroundColor Cyan
Write-Host "https://portal.azure.com/#view/Microsoft_Azure_Expert/AdvisorMenuBlade/~/cost" -ForegroundColor White
Write-Host ""
Write-Host "Action Group ID: $ActionGroupId" -ForegroundColor Green

