# PowerShell script to generate Groth16 Verifier from compliance.circom
# For Windows systems

$ErrorActionPreference = "Stop"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Groth16 Verifier Generation Script" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

$CIRCUIT_DIR = "circuits"
$CIRCUIT_NAME = "compliance"
$OUTPUT_DIR = "contracts/generated"
$POWERS_OF_TAU_POWER = 14

# Create output directory
New-Item -ItemType Directory -Force -Path $OUTPUT_DIR | Out-Null

# Step 1: Compile circuit
Write-Host "[1/6] Compiling Circom circuit..." -ForegroundColor Yellow
$circuitFile = Join-Path $CIRCUIT_DIR "$CIRCUIT_NAME.circom"
circom $circuitFile --r1cs --wasm --sym -o $CIRCUIT_DIR
if ($LASTEXITCODE -ne 0) { throw "Circuit compilation failed" }
$r1csPath = Join-Path $CIRCUIT_DIR "$CIRCUIT_NAME.r1cs"
Write-Host "Circuit compiled: $r1csPath" -ForegroundColor Green
Write-Host ""

# Step 2: Check if powers of tau exists
$potauBase = "pot" + $POWERS_OF_TAU_POWER.ToString()
$potauFile = $potauBase + "_final.ptau"
$potauPath = Join-Path $CIRCUIT_DIR $potauFile

if (-not (Test-Path $potauPath)) {
    Write-Host "[2/6] Powers of tau file not found. Starting trusted setup..." -ForegroundColor Yellow
    Write-Host "This will take some time..." -ForegroundColor Yellow
    
    $potau0000 = Join-Path $CIRCUIT_DIR ($potauBase + "_0000.ptau")
    $potau0001 = Join-Path $CIRCUIT_DIR ($potauBase + "_0001.ptau")
    
    # Generate initial powers of tau
    snarkjs powersoftau new bn128 $POWERS_OF_TAU_POWER $potau0000 -v
    if ($LASTEXITCODE -ne 0) { throw "Powers of tau generation failed" }
    
    # First contribution
    snarkjs powersoftau contribute $potau0000 $potau0001 --name="First contribution" -v
    if ($LASTEXITCODE -ne 0) { throw "Powers of tau contribution failed" }
    
    # Prepare phase 2
    snarkjs powersoftau prepare phase2 $potau0001 $potauPath -v
    if ($LASTEXITCODE -ne 0) { throw "Phase 2 preparation failed" }
    
    Write-Host "Powers of tau generated: $potauPath" -ForegroundColor Green
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
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Review the generated Groth16Verifier.sol" -ForegroundColor White
Write-Host "  2. Deploy the verifier contract" -ForegroundColor White
Write-Host "  3. Update your Compliance Hook to use the deployed verifier address" -ForegroundColor White
Write-Host ""
