# Pre-deployment validation script for Windows PowerShell
# Checks all prerequisites before deploying to Azure

Write-Host "🔍 Validating deployment prerequisites..." -ForegroundColor Cyan
Write-Host ""

$Errors = 0

# Check Azure CLI
Write-Host "1. Checking Azure CLI..."
try {
    $azVersion = az --version 2>$null | Select-Object -First 1
    if ($azVersion) {
        Write-Host "   ✅ Azure CLI installed: $azVersion" -ForegroundColor Green
    } else {
        throw "Not found"
    }
} catch {
    Write-Host "   ❌ Azure CLI not found. Please install: https://docs.microsoft.com/cli/azure/install-azure-cli" -ForegroundColor Red
    $Errors++
}

# Check Azure login
Write-Host "2. Checking Azure login..."
try {
    $account = az account show 2>$null | ConvertFrom-Json
    if ($account) {
        Write-Host "   ✅ Logged into Azure" -ForegroundColor Green
        Write-Host "      Subscription: $($account.name)"
        Write-Host "      ID: $($account.id)"
        
        if ($account.id -eq "71ec4f78-f42e-41e1-96f4-b75a69a53851") {
            Write-Host "   ✅ Correct subscription selected" -ForegroundColor Green
        } else {
            Write-Host "   ⚠️  Warning: Different subscription selected" -ForegroundColor Yellow
            Write-Host "      Expected: 71ec4f78-f42e-41e1-96f4-b75a69a53851"
            Write-Host "      Current: $($account.id)"
        }
    } else {
        throw "Not logged in"
    }
} catch {
    Write-Host "   ❌ Not logged into Azure. Run: az login" -ForegroundColor Red
    $Errors++
}

# Check Node.js
Write-Host "3. Checking Node.js..."
try {
    $nodeVersion = node --version
    $nodeMajor = [int]($nodeVersion -replace 'v(\d+)\..*', '$1')
    if ($nodeMajor -ge 18) {
        Write-Host "   ✅ Node.js installed: $nodeVersion" -ForegroundColor Green
    } else {
        Write-Host "   ❌ Node.js version too old: $nodeVersion (need 18+)" -ForegroundColor Red
        $Errors++
    }
} catch {
    Write-Host "   ❌ Node.js not found. Please install Node.js 18+" -ForegroundColor Red
    $Errors++
}

# Check npm packages
Write-Host "4. Checking npm packages..."
if (Test-Path "node_modules") {
    Write-Host "   ✅ node_modules directory exists" -ForegroundColor Green
    if (Test-Path "node_modules\@modelcontextprotocol\sdk\package.json") {
        Write-Host "   ✅ MCP SDK installed" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  MCP SDK not found. Run: npm install" -ForegroundColor Yellow
    }
} else {
    Write-Host "   ⚠️  node_modules not found. Run: npm install" -ForegroundColor Yellow
}

# Check environment variables
Write-Host "5. Checking environment variables..."
if ($env:AZURE_DEVOPS_PAT) {
    $patLength = $env:AZURE_DEVOPS_PAT.Length
    if ($patLength -ge 20) {
        Write-Host "   ✅ AZURE_DEVOPS_PAT is set (length: $patLength)" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  AZURE_DEVOPS_PAT seems too short" -ForegroundColor Yellow
    }
} else {
    Write-Host "   ⚠️  AZURE_DEVOPS_PAT not set (will use Key Vault if available)" -ForegroundColor Yellow
}

if ($env:AZURE_DEVOPS_ORG) {
    Write-Host "   ✅ AZURE_DEVOPS_ORG: $env:AZURE_DEVOPS_ORG" -ForegroundColor Green
} else {
    Write-Host "   ℹ️  AZURE_DEVOPS_ORG not set (will use default: YourOrganization)" -ForegroundColor Gray
}

if ($env:AZURE_DEVOPS_PROJECT) {
    Write-Host "   ✅ AZURE_DEVOPS_PROJECT: $env:AZURE_DEVOPS_PROJECT" -ForegroundColor Green
} else {
    Write-Host "   ℹ️  AZURE_DEVOPS_PROJECT not set (will use default: Integration)" -ForegroundColor Gray
}

# Check configuration
Write-Host "6. Checking deployment configuration..."
$projectCode = if ($env:PROJECT_CODE) { $env:PROJECT_CODE } else { "mcp" }
$environment = if ($env:ENVIRONMENT) { $env:ENVIRONMENT } else { "dv" }
$locationCode = if ($env:LOCATION_CODE) { $env:LOCATION_CODE } else { "eus2" }
$instanceNumber = if ($env:INSTANCE_NUMBER) { $env:INSTANCE_NUMBER } else { "001" }

$resourceGroup = "rg-00-integration-$projectCode-$environment-$locationCode-$instanceNumber"
$containerApp = "cap-00-$environment-$projectCode-$instanceNumber"
$keyVault = "kyt-00-$environment-$projectCode-$instanceNumber"

Write-Host "   Project Code: $projectCode"
Write-Host "   Environment: $environment"
Write-Host "   Location Code: $locationCode"
Write-Host "   Instance Number: $instanceNumber"
Write-Host ""
Write-Host "   Resource Group: $resourceGroup"
Write-Host "   Container App: $containerApp"
Write-Host "   Key Vault: $keyVault"

# Check if resources already exist
Write-Host ""
Write-Host "7. Checking for existing resources..."
try {
    $rg = az group show --name $resourceGroup 2>$null | ConvertFrom-Json
    if ($rg) {
        Write-Host "   ⚠️  Resource group already exists: $resourceGroup" -ForegroundColor Yellow
        Write-Host "      Deployment will update existing resources"
    }
} catch {
    Write-Host "   ✅ Resource group does not exist (will be created)" -ForegroundColor Green
}

# Check deployment files
Write-Host ""
Write-Host "8. Checking deployment files..."
$files = @("deploy.sh", "azure-deploy.bicep", "Dockerfile", "server.js", "package.json")
foreach ($file in $files) {
    if (Test-Path $file) {
        Write-Host "   ✅ $file exists" -ForegroundColor Green
    } else {
        Write-Host "   ❌ $file not found" -ForegroundColor Red
        $Errors++
    }
}

# Summary
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if ($Errors -eq 0) {
    Write-Host "✅ Validation complete! Ready to deploy." -ForegroundColor Green
    Write-Host ""
    Write-Host "To deploy, run:" -ForegroundColor Cyan
    Write-Host "  .\deploy.sh" -ForegroundColor White
    exit 0
} else {
    Write-Host "❌ Validation found $Errors error(s). Please fix before deploying." -ForegroundColor Red
    exit 1
}

