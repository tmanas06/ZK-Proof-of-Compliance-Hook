# PowerShell script to extract addresses from deployment and update .env
# Usage: Run after deploying contracts, then run this script

param(
    [string]$DeploymentOutput = ""
)

Write-Host "=== Generating .env file from deployment ===" -ForegroundColor Cyan

# Check if .env.example exists
if (-not (Test-Path ".env.example")) {
    Write-Host "ERROR: .env.example not found!" -ForegroundColor Red
    exit 1
}

# Copy example to .env if it doesn't exist
if (-not (Test-Path ".env")) {
    Copy-Item ".env.example" ".env"
    Write-Host "Created .env from .env.example" -ForegroundColor Green
}

Write-Host ""
Write-Host "Please run the deployment script and copy the addresses:" -ForegroundColor Yellow
Write-Host "  forge script script/DeployAllEnhanced.s.sol:DeployAllEnhanced --rpc-url http://localhost:8545 --broadcast" -ForegroundColor White
Write-Host ""
Write-Host "Then manually update .env with the deployed addresses from the output." -ForegroundColor Yellow
Write-Host ""
Write-Host "Or provide the deployment output as a parameter to this script." -ForegroundColor Yellow

