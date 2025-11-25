# Complete deployment script - Generates verifier and deploys everything
# This script automates the entire process from circuit to deployed contracts

$ErrorActionPreference = "Stop"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Complete ZK Compliance System Deployment" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Generate Groth16 Verifier
Write-Host "[Step 1/4] Generating Groth16 Verifier..." -ForegroundColor Yellow
Write-Host "This will take 5-10 minutes..." -ForegroundColor Yellow
Write-Host ""

powershell -ExecutionPolicy Bypass -File scripts\generate-groth16-verifier-auto.ps1
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Verifier generation failed!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[Step 1/4] ✓ Groth16 Verifier generated" -ForegroundColor Green
Write-Host ""

# Step 2: Check if Anvil is running
Write-Host "[Step 2/4] Checking blockchain connection..." -ForegroundColor Yellow
$rpcUrl = "http://localhost:8545"
try {
    $response = Invoke-WebRequest -Uri "$rpcUrl" -Method POST -Body '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' -ContentType "application/json" -TimeoutSec 5 -ErrorAction Stop
    Write-Host "✓ Anvil is running" -ForegroundColor Green
} catch {
    Write-Host "WARNING: Anvil not running. Starting Anvil..." -ForegroundColor Yellow
    Start-Process -NoNewWindow -FilePath "anvil" -ArgumentList "--host", "127.0.0.1", "--port", "8545"
    Start-Sleep -Seconds 3
    Write-Host "✓ Anvil started" -ForegroundColor Green
}
Write-Host ""

# Step 3: Deploy Groth16 Verifier
Write-Host "[Step 3/4] Deploying Groth16 Verifier..." -ForegroundColor Yellow
Write-Host "NOTE: You need to deploy the generated Groth16Verifier.sol contract manually" -ForegroundColor Yellow
Write-Host "or copy it to src/verifiers/ and update the deployment script." -ForegroundColor Yellow
Write-Host ""
Write-Host "For now, we'll use the MockGroth16Verifier for testing..." -ForegroundColor Yellow
Write-Host ""

# Step 4: Deploy Production Compliance Hook
Write-Host "[Step 4/4] Deploying Production Compliance Hook..." -ForegroundColor Yellow

# Check if .env has GROTH16_VERIFIER_ADDRESS
$envContent = Get-Content .env -ErrorAction SilentlyContinue
$hasVerifier = $envContent | Select-String -Pattern "GROTH16_VERIFIER_ADDRESS" | Select-String -Pattern "0x[0-9a-fA-F]{40}"

if (-not $hasVerifier) {
    Write-Host "WARNING: GROTH16_VERIFIER_ADDRESS not set in .env" -ForegroundColor Yellow
    Write-Host "The deployment will use MockGroth16Verifier for testing." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To use real verifier:" -ForegroundColor Cyan
    Write-Host "  1. Deploy Groth16Verifier.sol from contracts/generated/" -ForegroundColor White
    Write-Host "  2. Add GROTH16_VERIFIER_ADDRESS=0x... to .env" -ForegroundColor White
    Write-Host "  3. Re-run this script" -ForegroundColor White
    Write-Host ""
}

# Deploy using Foundry
Write-Host "Deploying contracts..." -ForegroundColor Yellow
forge script script/DeployProductionHook.s.sol:DeployProductionHook --rpc-url $rpcUrl --broadcast -vv
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Deployment failed!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "✓ Deployment Complete!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Check deployment output for contract addresses" -ForegroundColor White
Write-Host "  2. Update .env with deployed addresses" -ForegroundColor White
Write-Host "  3. Test proof submission" -ForegroundColor White
Write-Host ""

