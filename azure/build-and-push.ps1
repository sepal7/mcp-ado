# Build and push Docker image to ACR
# This script builds locally and pushes to avoid SSL issues with ACR build

$ErrorActionPreference = "Stop"

$ACR_NAME = "acr00dvmcp001"
$IMAGE_NAME = "mcp-ado-server"
$IMAGE_TAG = "latest"
$FULL_IMAGE = "${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${IMAGE_TAG}"

Write-Host "🐳 Building Docker image locally..." -ForegroundColor Cyan

# Check if Docker is available
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Docker is not installed or not in PATH" -ForegroundColor Red
    Write-Host "   Please install Docker Desktop or use Azure Portal to build the image" -ForegroundColor Yellow
    exit 1
}

# Build image
Write-Host "Building image: $FULL_IMAGE" -ForegroundColor Yellow
docker build -t $FULL_IMAGE .

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Docker build failed" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Image built successfully" -ForegroundColor Green

# Login to ACR
Write-Host "🔐 Logging into Azure Container Registry..." -ForegroundColor Cyan
az acr login --name $ACR_NAME

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to login to ACR" -ForegroundColor Red
    exit 1
}

# Push image
Write-Host "📤 Pushing image to registry..." -ForegroundColor Cyan
docker push $FULL_IMAGE

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to push image" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Image pushed successfully!" -ForegroundColor Green
Write-Host "   Image: $FULL_IMAGE" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next step: Create Container App using this image" -ForegroundColor Yellow

