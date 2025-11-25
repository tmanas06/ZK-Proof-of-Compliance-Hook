# PowerShell script to generate Groth16 Verifier - FAST VERSION (Power 12 for testing)
# This uses a smaller power of tau for faster generation (suitable for testing)

$ErrorActionPreference = "Stop"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Groth16 Verifier Generation (Fast Mode)" -ForegroundColor Cyan
Write-Host "Using Power 12 for faster generation" -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

$CIRCUIT_DIR = "circuits"
$CIRCUIT_NAME = "compliance"
$OUTPUT_DIR = "contracts/generated"
$POWERS_OF_TAU_POWER = 12  # Smaller power for faster generation

# Create output directory
New-Item -ItemType Directory -Force -Path $OUTPUT_DIR | Out-Null

# Step 1: Compile circuit (if not already compiled)
Write-Host "[1/6] Checking circuit compilation..." -ForegroundColor Yellow
$r1csPath = Join-Path $CIRCUIT_DIR "$CIRCUIT_NAME.r1cs"
if (-not (Test-Path $r1csPath)) {
    Write-Host "Compiling circuit..." -ForegroundColor Yellow
    $circuitFile = Join-Path $CIRCUIT_DIR "$CIRCUIT_NAME.circom"
    circom $circuitFile --r1cs --wasm --sym -o $CIRCUIT_DIR
    if ($LASTEXITCODE -ne 0) { throw "Circuit compilation failed" }
}
Write-Host "Circuit ready: $r1csPath" -ForegroundColor Green
Write-Host ""

# Step 2: Download pre-generated powers of tau (much faster!)
Write-Host "[2/6] Setting up powers of tau..." -ForegroundColor Yellow
$potauBase = "pot" + $POWERS_OF_TAU_POWER.ToString()
$potauFile = $potauBase + "_final.ptau"
$potauPath = Join-Path $CIRCUIT_DIR $potauFile

if (-not (Test-Path $potauPath)) {
    Write-Host "Powers of tau not found. Downloading pre-generated file..." -ForegroundColor Yellow
    Write-Host "This is much faster than generating from scratch!" -ForegroundColor Green
    
    # Try to download from snarkjs trusted setup ceremony
    $downloadUrl = "https://hermez.s3-eu-west-1.amazonaws.com/powersOfTau28_hez_final.ptau"
    $tempPtau = Join-Path $CIRCUIT_DIR "powersOfTau28_hez_final.ptau"
    
    Write-Host "Attempting to download pre-generated powers of tau..." -ForegroundColor Yellow
    try {
        Invoke-WebRequest -Uri $downloadUrl -OutFile $tempPtau -TimeoutSec 300
        Write-Host "Downloaded powers of tau file" -ForegroundColor Green
        
        # For power 12, we can use a smaller file or generate quickly
        # Since power 12 is small, let's generate it (should take ~5-10 minutes)
        Write-Host "Generating power 12 powers of tau (this will take ~5-10 minutes)..." -ForegroundColor Yellow
        $potau0000 = Join-Path $CIRCUIT_DIR ($potauBase + "_0000.ptau")
        $potau0001 = Join-Path $CIRCUIT_DIR ($potauBase + "_0001.ptau")
        
        snarkjs powersoftau new bn128 $POWERS_OF_TAU_POWER $potau0000 -v
        if ($LASTEXITCODE -ne 0) { throw "Powers of tau generation failed" }
        
        snarkjs powersoftau contribute $potau0000 $potau0001 --name="First contribution" -v
        if ($LASTEXITCODE -ne 0) { throw "Powers of tau contribution failed" }
        
        snarkjs powersoftau prepare phase2 $potau0001 $potauPath -v
        if ($LASTEXITCODE -ne 0) { throw "Phase 2 preparation failed" }
        
        Write-Host "Powers of tau generated: $potauPath" -ForegroundColor Green
    } catch {
        Write-Host "Download failed or generation needed. Generating locally..." -ForegroundColor Yellow
        $potau0000 = Join-Path $CIRCUIT_DIR ($potauBase + "_0000.ptau")
        $potau0001 = Join-Path $CIRCUIT_DIR ($potauBase + "_0001.ptau")
        
        snarkjs powersoftau new bn128 $POWERS_OF_TAU_POWER $potau0000 -v
        if ($LASTEXITCODE -ne 0) { throw "Powers of tau generation failed" }
        
        snarkjs powersoftau contribute $potau0000 $potau0001 --name="First contribution" -v
        if ($LASTEXITCODE -ne 0) { throw "Powers of tau contribution failed" }
        
        snarkjs powersoftau prepare phase2 $potau0001 $potauPath -v
        if ($LASTEXITCODE -ne 0) { throw "Phase 2 preparation failed" }
    }
} else {
    Write-Host "[2/6] Using existing powers of tau: $potauPath" -ForegroundColor Green
}
Write-Host ""

# Step 3: Generate zkey
Write-Host "[3/6] Generating zkey..." -ForegroundColor Yellow
$zkey0000 = Join-Path $CIRCUIT_DIR ($CIRCUIT_NAME + "_0000.zkey")
$zkey0001 = Join-Path $CIRCUIT_DIR ($CIRCUIT_NAME + "_0001.zkey")
$vkeyFile = Join-Path $CIRCUIT_DIR ($CIRCUIT_NAME + "_vkey.json")

snarkjs groth16 setup $r1csPath $potauPath $zkey0000 -v
if ($LASTEXITCODE -ne 0) { throw "Zkey generation failed" }

# Contribute to zkey
Write-Host "[4/6] Contributing to zkey (adding randomness)..." -ForegroundColor Yellow
snarkjs zkey contribute $zkey0000 $zkey0001 --name="Second contribution" -v
if ($LASTEXITCODE -ne 0) { throw "Zkey contribution failed" }

# Export verification key
Write-Host "[5/6] Exporting verification key..." -ForegroundColor Yellow
snarkjs zkey export verificationkey $zkey0001 $vkeyFile
if ($LASTEXITCODE -ne 0) { throw "Verification key export failed" }
Write-Host "Verification key exported" -ForegroundColor Green
Write-Host ""

# Step 4: Generate Solidity verifier contract
Write-Host "[6/6] Generating Groth16 Verifier Solidity contract..." -ForegroundColor Yellow
$verifierOutput = Join-Path $OUTPUT_DIR "Groth16Verifier.sol"
snarkjs zkey export solidityverifier $zkey0001 $verifierOutput
if ($LASTEXITCODE -ne 0) { throw "Verifier contract generation failed" }

# Add SPDX license and pragma
$header = "// SPDX-License-Identifier: MIT`npragma solidity ^0.8.24;`n`n"
$content = Get-Content $verifierOutput -Raw
Set-Content $verifierOutput -Value ($header + $content)

Write-Host "Verifier contract generated: $verifierOutput" -ForegroundColor Green
Write-Host ""

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Groth16 Verifier Generation Complete!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Generated files:" -ForegroundColor Yellow
Write-Host "  - Verifier contract: $verifierOutput" -ForegroundColor White
$wasmDir = Join-Path $CIRCUIT_DIR ($CIRCUIT_NAME + "_js")
$wasmPath = Join-Path $wasmDir ($CIRCUIT_NAME + ".wasm")
Write-Host "  - Circuit WASM: $wasmPath" -ForegroundColor White
Write-Host "  - Final zkey: $zkey0001" -ForegroundColor White
Write-Host "  - Verification key: $vkeyFile" -ForegroundColor White
Write-Host ""
Write-Host "NOTE: This used Power 12 for faster generation." -ForegroundColor Yellow
Write-Host "For production, use Power 14+ with the full script." -ForegroundColor Yellow
Write-Host ""

