# Build Docker image via ACR REST API
# This bypasses CLI SSL issues

$ACR_NAME = "acr00dvmcp001"
$IMAGE_NAME = "mcp-ado-server"
$IMAGE_TAG = "latest"
$SUBSCRIPTION_ID = "71ec4f78-f42e-41e1-96f4-b75a69a53851"
$RESOURCE_GROUP = "rg-00-integration-mcp-dv-eus2-001"

Write-Host "🔨 Building Docker image via ACR REST API..." -ForegroundColor Cyan

# Get access token
$token = az account get-access-token --query accessToken -o tsv
if (-not $token) {
    Write-Host "❌ Failed to get access token" -ForegroundColor Red
    exit 1
}

$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

# Create task run
$taskBody = @{
    type = "DockerBuildRequest"
    imageNames = @("${IMAGE_NAME}:${IMAGE_TAG}")
    isPushEnabled = $true
    noCache = $false
    dockerFilePath = "Dockerfile"
    sourceLocation = "."
} | ConvertTo-Json -Depth 10

# Note: ACR Tasks API requires file upload, which is complex via REST
# This is a placeholder - actual build needs to be done via Portal or CLI
Write-Host "⚠️  ACR build requires file upload which is complex via REST API" -ForegroundColor Yellow
Write-Host "   Please build the image via:" -ForegroundColor Yellow
Write-Host "   1. Azure Portal → ACR → Tasks → Quick Run" -ForegroundColor White
Write-Host "   2. Or use local Docker: docker build + docker push" -ForegroundColor White

