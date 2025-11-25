#!/bin/bash
# Generate Groth16 Verifier from compliance.circom circuit
# This script automates the trusted setup and verifier contract generation

set -e

echo "=========================================="
echo "Groth16 Verifier Generation Script"
echo "=========================================="
echo ""

CIRCUIT_DIR="circuits"
CIRCUIT_NAME="compliance"
OUTPUT_DIR="contracts/generated"
POWERS_OF_TAU_POWER=14

# Create output directory
mkdir -p $OUTPUT_DIR

# Step 1: Compile circuit
echo "[1/6] Compiling Circom circuit..."
circom $CIRCUIT_DIR/$CIRCUIT_NAME.circom --r1cs --wasm --sym -o $CIRCUIT_DIR
echo "✓ Circuit compiled: $CIRCUIT_DIR/$CIRCUIT_NAME.r1cs"
echo ""

# Step 2: Check if powers of tau exists, otherwise download
POTAU_FILE="pot${POWERS_OF_TAU_POWER}_final.ptau"
if [ ! -f "$CIRCUIT_DIR/$POTAU_FILE" ]; then
    echo "[2/6] Powers of tau file not found. Starting trusted setup..."
    echo "This will take some time..."
    
    # Generate initial powers of tau
    snarkjs powersoftau new bn128 $POWERS_OF_TAU_POWER $CIRCUIT_DIR/pot${POWERS_OF_TAU_POWER}_0000.ptau -v
    
    # First contribution (you can add more contributions for security)
    snarkjs powersoftau contribute $CIRCUIT_DIR/pot${POWERS_OF_TAU_POWER}_0000.ptau \
        $CIRCUIT_DIR/pot${POWERS_OF_TAU_POWER}_0001.ptau \
        --name="First contribution" -v
    
    # Prepare phase 2
    snarkjs powersoftau prepare phase2 $CIRCUIT_DIR/pot${POWERS_OF_TAU_POWER}_0001.ptau \
        $CIRCUIT_DIR/$POTAU_FILE -v
    
    echo "✓ Powers of tau generated: $CIRCUIT_DIR/$POTAU_FILE"
else
    echo "[2/6] Using existing powers of tau: $CIRCUIT_DIR/$POTAU_FILE"
fi
echo ""

# Step 3: Generate zkey
echo "[3/6] Generating zkey..."
snarkjs groth16 setup $CIRCUIT_DIR/$CIRCUIT_NAME.r1cs \
    $CIRCUIT_DIR/$POTAU_FILE \
    $CIRCUIT_DIR/${CIRCUIT_NAME}_0000.zkey -v

# Contribute to zkey (add randomness)
echo "[4/6] Contributing to zkey (adding randomness)..."
snarkjs zkey contribute $CIRCUIT_DIR/${CIRCUIT_NAME}_0000.zkey \
    $CIRCUIT_DIR/${CIRCUIT_NAME}_0001.zkey \
    --name="Second contribution" -v

# Export verification key
echo "[5/6] Exporting verification key..."
snarkjs zkey export verificationkey $CIRCUIT_DIR/${CIRCUIT_NAME}_0001.zkey \
    $CIRCUIT_DIR/${CIRCUIT_NAME}_vkey.json
echo "✓ Verification key exported"
echo ""

# Step 4: Generate Solidity verifier contract
echo "[6/6] Generating Groth16 Verifier Solidity contract..."
snarkjs zkey export solidityverifier $CIRCUIT_DIR/${CIRCUIT_NAME}_0001.zkey \
    $OUTPUT_DIR/Groth16Verifier.sol

# Update contract name and add SPDX license
sed -i '1i\// SPDX-License-Identifier: MIT\npragma solidity ^0.8.24;\n' $OUTPUT_DIR/Groth16Verifier.sol

echo "✓ Verifier contract generated: $OUTPUT_DIR/Groth16Verifier.sol"
echo ""

echo "=========================================="
echo "✓ Groth16 Verifier Generation Complete!"
echo "=========================================="
echo ""
echo "Generated files:"
echo "  - Verifier contract: $OUTPUT_DIR/Groth16Verifier.sol"
echo "  - Circuit WASM: $CIRCUIT_DIR/${CIRCUIT_NAME}_js/${CIRCUIT_NAME}.wasm"
echo "  - Final zkey: $CIRCUIT_DIR/${CIRCUIT_NAME}_0001.zkey"
echo "  - Verification key: $CIRCUIT_DIR/${CIRCUIT_NAME}_vkey.json"
echo ""
echo "Next steps:"
echo "  1. Review the generated Groth16Verifier.sol"
echo "  2. Deploy the verifier contract"
echo "  3. Update your Compliance Hook to use the deployed verifier address"
echo ""

