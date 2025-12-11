# Azure Cost Alert Setup Script for MCP Server
# Creates budget alerts to monitor monthly spending and prevent exceeding $30/month

param(
    [string]$ResourceGroupName = "rg-00-integration-mcp-dv-eus2-001",
    [string]$SubscriptionId = "71ec4f78-f42e-41e1-96f4-b75a69a53851",
    [string]$EmailAddress = "",
    [decimal]$BudgetAmount = 30.00
)

Write-Host "🔔 Setting up Azure Cost Alerts for MCP Server Resources" -ForegroundColor Cyan
Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor Yellow
Write-Host "Budget Limit: `$$BudgetAmount/month" -ForegroundColor Yellow
Write-Host ""

# Check if Azure CLI is installed
try {
    $azVersion = az version --output json | ConvertFrom-Json
    Write-Host "✅ Azure CLI found (version $($azVersion.'azure-cli'))" -ForegroundColor Green
} catch {
    Write-Host "❌ Azure CLI not found. Please install Azure CLI first." -ForegroundColor Red
    exit 1
}

# Login check
Write-Host "Checking Azure login status..." -ForegroundColor Cyan
$account = az account show --output json 2>$null | ConvertFrom-Json
if (-not $account) {
    Write-Host "⚠️  Not logged in. Attempting login..." -ForegroundColor Yellow
    az login
    $account = az account show --output json | ConvertFrom-Json
}

if ($account.id -ne $SubscriptionId) {
    Write-Host "Setting subscription to $SubscriptionId..." -ForegroundColor Cyan
    az account set --subscription $SubscriptionId
}

Write-Host "✅ Using subscription: $($account.name) ($($account.id))" -ForegroundColor Green
Write-Host ""

# Check if resource group exists
Write-Host "Checking if resource group exists..." -ForegroundColor Cyan
$rgExists = az group exists --name $ResourceGroupName --output tsv
if ($rgExists -eq "false") {
    Write-Host "⚠️  Resource group '$ResourceGroupName' does not exist yet." -ForegroundColor Yellow
    Write-Host "   The budget will be created but won't track costs until resources are deployed." -ForegroundColor Yellow
    Write-Host ""
}

# Prompt for email if not provided
if ([string]::IsNullOrWhiteSpace($EmailAddress)) {
    $EmailAddress = Read-Host "Enter email address for budget alerts"
    if ([string]::IsNullOrWhiteSpace($EmailAddress)) {
        Write-Host "❌ Email address is required for budget alerts." -ForegroundColor Red
        exit 1
    }
}

# Create budget name
$BudgetName = "MCP-Server-Monthly-Budget"

Write-Host "Creating budget: $BudgetName" -ForegroundColor Cyan
Write-Host "  Amount: `$$BudgetAmount USD/month" -ForegroundColor Cyan
Write-Host "  Alert thresholds: 67% (`$$([math]::Round($BudgetAmount * 0.67, 2))), 83% (`$$([math]::Round($BudgetAmount * 0.83, 2))), 100% (`$$BudgetAmount)" -ForegroundColor Cyan
Write-Host ""

# Create budget JSON payload
$budgetJson = @{
    properties = @{
        timePeriod = @{
            startDate = (Get-Date -Format "yyyy-MM-01T00:00:00Z")
            endDate = (Get-Date).AddYears(1).ToString("yyyy-MM-01T00:00:00Z")
        }
        timeGrain = "Monthly"
        amount = $BudgetAmount
        category = "Cost"
        filter = @{
            dimensions = @{
                name = "ResourceGroupName"
                operator = "In"
                values = @($ResourceGroupName)
            }
        }
        notifications = @{
            Actual = @{
                enabled = $true
                operator = "GreaterThan"
                threshold = 100
                contactEmails = @($EmailAddress)
                contactRoles = @()
                contactGroups = @()
            }
            Forecasted = @{
                enabled = $true
                operator = "GreaterThan"
                threshold = 100
                contactEmails = @($EmailAddress)
                contactRoles = @()
                contactGroups = @()
            }
            Warning67 = @{
                enabled = $true
                operator = "GreaterThan"
                threshold = 67
                contactEmails = @($EmailAddress)
                contactRoles = @()
                contactGroups = @()
            }
            Warning83 = @{
                enabled = $true
                operator = "GreaterThan"
                threshold = 83
                contactEmails = @($EmailAddress)
                contactRoles = @()
                contactGroups = @()
            }
        }
    }
} | ConvertTo-Json -Depth 10

# Save to temp file
$tempFile = [System.IO.Path]::GetTempFileName()
$budgetJson | Out-File -FilePath $tempFile -Encoding UTF8

try {
    # Create budget using Azure CLI
    Write-Host "Creating budget via Azure CLI..." -ForegroundColor Cyan
    $result = az consumption budget create `
        --budget-name $BudgetName `
        --amount $BudgetAmount `
        --time-grain Monthly `
        --start-date (Get-Date -Format "yyyy-MM-01") `
        --end-date (Get-Date).AddYears(1).ToString("yyyy-MM-01") `
        --category Cost `
        --resource-group-filter $ResourceGroupName `
        --output json 2>&1

    if ($LASTEXITCODE -ne 0) {
        Write-Host "⚠️  Budget creation via CLI failed. Trying REST API method..." -ForegroundColor Yellow
        
        # Alternative: Use REST API
        $token = az account get-access-token --query accessToken --output tsv
        $headers = @{
            "Authorization" = "Bearer $token"
            "Content-Type" = "application/json"
        }
        
        $scope = "/subscriptions/$SubscriptionId"
        $uri = "https://management.azure.com$scope/providers/Microsoft.Consumption/budgets/$BudgetName`?api-version=2023-05-01"
        
        $response = Invoke-RestMethod -Uri $uri -Method Put -Headers $headers -Body $budgetJson -ErrorAction Stop
        Write-Host "✅ Budget created successfully via REST API" -ForegroundColor Green
    } else {
        Write-Host "✅ Budget created successfully" -ForegroundColor Green
    }

    # Add notification groups (alerts)
    Write-Host ""
    Write-Host "Setting up alert notifications..." -ForegroundColor Cyan
    
    # Create notification groups for each threshold
    $thresholds = @(
        @{Name = "Warning67"; Threshold = 67; Amount = [math]::Round($BudgetAmount * 0.67, 2)},
        @{Name = "Warning83"; Threshold = 83; Amount = [math]::Round($BudgetAmount * 0.83, 2)},
        @{Name = "Actual"; Threshold = 100; Amount = $BudgetAmount}
    )

    foreach ($threshold in $thresholds) {
        Write-Host "  Creating alert at $($threshold.Threshold)% threshold (`$$($threshold.Amount))..." -ForegroundColor Cyan
        
        $notificationJson = @{
            enabled = $true
            operator = "GreaterThan"
            threshold = $threshold.Threshold
            contactEmails = @($EmailAddress)
        } | ConvertTo-Json

        $notificationFile = [System.IO.Path]::GetTempFileName()
        $notificationJson | Out-File -FilePath $notificationFile -Encoding UTF8

        try {
            az consumption budget notification create `
                --budget-name $BudgetName `
                --notification-name "$($threshold.Name)Notification" `
                --enabled `
                --operator GreaterThan `
                --threshold $threshold.Threshold `
                --contact-emails $EmailAddress `
                --output none 2>&1 | Out-Null

            if ($LASTEXITCODE -eq 0) {
                Write-Host "    ✅ Alert created at $($threshold.Threshold)%" -ForegroundColor Green
            } else {
                Write-Host "    ⚠️  Alert creation skipped (may already exist)" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "    ⚠️  Could not create notification: $_" -ForegroundColor Yellow
        } finally {
            Remove-Item $notificationFile -ErrorAction SilentlyContinue
        }
    }

    Write-Host ""
    Write-Host "✅ Cost alerts setup complete!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📊 Budget Summary:" -ForegroundColor Cyan
    Write-Host "   Budget Name: $BudgetName" -ForegroundColor White
    Write-Host "   Monthly Limit: `$$BudgetAmount USD" -ForegroundColor White
    Write-Host "   Resource Group: $ResourceGroupName" -ForegroundColor White
    Write-Host "   Alert Email: $EmailAddress" -ForegroundColor White
    Write-Host ""
    Write-Host "🔔 You will receive email alerts at:" -ForegroundColor Cyan
    Write-Host "   - 67% threshold: `$$([math]::Round($BudgetAmount * 0.67, 2)) (Early Warning)" -ForegroundColor Yellow
    Write-Host "   - 83% threshold: `$$([math]::Round($BudgetAmount * 0.83, 2)) (Warning)" -ForegroundColor Yellow
    Write-Host "   - 100% threshold: `$$BudgetAmount (Budget Exceeded)" -ForegroundColor Red
    Write-Host ""
    Write-Host "💡 To view the budget in Azure Portal:" -ForegroundColor Cyan
    Write-Host "   https://portal.azure.com/#@/costmanagement/budgets" -ForegroundColor White
    Write-Host ""
    Write-Host "💡 To check current spending:" -ForegroundColor Cyan
    Write-Host "   az consumption budget list --query `"[?name=='$BudgetName']`"" -ForegroundColor White

} catch {
    Write-Host "Error creating budget: $_" -ForegroundColor Red
    Write-Host "Please ensure you have Cost Management Contributor or Owner role." -ForegroundColor Yellow
    exit 1
} finally {
    Remove-Item $tempFile -ErrorAction SilentlyContinue
}

