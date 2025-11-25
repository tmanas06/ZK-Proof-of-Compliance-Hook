# Complete .env Setup Guide

## ✅ What's Been Done

1. **Circom 2.2.3** - Installed and configured globally
2. **Circuit Compiled** - `compliance.circom` successfully compiled
3. **Deployment Script** - `script/DeployAllEnhanced.s.sol` created
4. **Mock Groth16 Verifier** - Created for testing
5. **All Contracts** - Ready to deploy

## 🚀 Next Steps to Complete .env Setup

### Step 1: Start Anvil (Local Blockchain)

```powershell
anvil
```

Keep this running in a separate terminal.

### Step 2: Deploy All Contracts

In a new terminal, run:

```powershell
forge script script/DeployAllEnhanced.s.sol:DeployAllEnhanced --rpc-url http://localhost:8545 --broadcast
```

This will deploy:
- ✅ MockGroth16Verifier (or use existing if GROTH16_VERIFIER_ADDRESS is set)
- ✅ RealBrevisVerifier
- ✅ RealEigenLayerAVS
- ✅ RealFhenixFHE
- ✅ ZKProofOfComplianceFull Hook

### Step 3: Copy Addresses to .env

After deployment, the script will output all addresses. Copy them to your `.env` file:

```bash
GROTH16_VERIFIER_ADDRESS=<deployed_address>
BREVIS_VERIFIER_ADDRESS=<deployed_address>
EIGENLAYER_AVS_ADDRESS=<deployed_address>
FHENIX_FHE_ADDRESS=0x1111111111111111111111111111111111111111  # Placeholder - get from Fhenix docs
FHENIX_SERVICE_ADDRESS=<deployed_address>
HOOK_ADDRESS=<deployed_address>
```

### Step 4: Update FHENIX_FHE_ADDRESS (Optional)

For production, get the official Fhenix FHE contract address from:
- https://docs.fhenix.io

Replace the placeholder address in `.env`.

### Step 5: Generate Real Groth16 Verifier (For Production)

For production use (not required for testing):

```powershell
# Complete the trusted setup (if not done)
snarkjs powersoftau contribute pot14_0000.ptau pot14_0001.ptau --name="First contribution" -v
snarkjs powersoftau prepare phase2 pot14_0001.ptau pot14_final.ptau -v

# Generate zkey
snarkjs groth16 setup compliance.r1cs pot14_final.ptau compliance_0000.zkey
snarkjs zkey contribute compliance_0000.zkey compliance_0001.zkey --name="Second contribution" -v

# Export verifier contract
snarkjs zkey export solidityverifier compliance_0001.zkey verifier.sol

# Deploy verifier.sol (using Remix, Hardhat, or Foundry)
# Then update GROTH16_VERIFIER_ADDRESS in .env
```

## 📋 Current .env Status

Your `.env` file has been created from `.env.example` with:
- ✅ All required variables defined
- ✅ Default values for local testing
- ✅ Placeholder addresses (0x0) that will be filled after deployment

## 🔍 Verify Setup

After deployment, verify your `.env` file has:
- ✅ All addresses filled (not 0x0 except FHENIX_FHE_ADDRESS if using placeholder)
- ✅ PRIVATE_KEY set (Anvil default for local testing)
- ✅ RPC_URL set to http://localhost:8545
- ✅ All EigenLayer configuration values set

## 📝 Example Deployment Output

When you run the deployment script, you'll see output like:

```
=== DEPLOYMENT SUMMARY ===
Copy these addresses to your .env file:

GROTH16_VERIFIER_ADDRESS= 0x5FbDB2315678afecb367f032d93F642f64180aa3
BREVIS_VERIFIER_ADDRESS= 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
EIGENLAYER_AVS_ADDRESS= 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0
FHENIX_FHE_ADDRESS= 0x1111111111111111111111111111111111111111
FHENIX_SERVICE_ADDRESS= 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9
HOOK_ADDRESS= 0xDc64a140Aa3E981100a9becA8Ee6F8554b3b357D
```

Copy these addresses to your `.env` file!

## ⚠️ Important Notes

1. **For Testing**: The MockGroth16Verifier will be deployed automatically
2. **For Production**: Generate and deploy the real Groth16Verifier using snarkjs
3. **FHENIX_FHE_ADDRESS**: Get from Fhenix documentation or use placeholder for testing
4. **Never commit `.env`**: It contains private keys and should be in `.gitignore`

## 🎯 Quick Start

1. Start Anvil: `anvil`
2. Deploy: `forge script script/DeployAllEnhanced.s.sol:DeployAllEnhanced --rpc-url http://localhost:8545 --broadcast`
3. Copy addresses from output to `.env`
4. Done! Your contracts are deployed and configured.

