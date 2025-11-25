# .env File Update Guide

## What to Update in Your .env File

With the enhanced system (real Brevis, EigenLayer AVS, and Fhenix FHE integrations), you need to add several new environment variables to your `.env` file.

## Quick Reference

### ✅ Existing Variables (Keep These)
- `PRIVATE_KEY` - Your deployment account private key
- `POOL_MANAGER_ADDRESS` - Uniswap v4 PoolManager address
- `LOCAL_RPC_URL` - Local RPC URL (default: http://localhost:8545)
- `MAINNET_RPC_URL` - Mainnet RPC URL (optional)
- `SEPOLIA_RPC_URL` - Sepolia RPC URL (optional)
- `ETHERSCAN_API_KEY` - Etherscan API key (optional)
- `ROUTER_ADDRESS` - Router address (optional, for frontend)

### 🆕 New Variables to Add

#### 1. Real ZK Proof Integration (Brevis)
```bash
# Groth16 verifier contract address (deploy after compiling circuit)
GROTH16_VERIFIER_ADDRESS=0x0000000000000000000000000000000000000000

# RealBrevisVerifier contract address (deploy after Groth16 verifier)
BREVIS_VERIFIER_ADDRESS=0x0000000000000000000000000000000000000000
```

#### 2. EigenLayer AVS Integration
```bash
# RealEigenLayerAVS contract address
EIGENLAYER_AVS_ADDRESS=0x0000000000000000000000000000000000000000

# Operator addresses (comma-separated, minimum 2)
EIGENLAYER_OPERATORS=0x70997970C51812dc3A010C7d01b50e0d17dc79C8,0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC

# Configuration
EIGENLAYER_MIN_CONFIRMATIONS=2
EIGENLAYER_TIMEOUT=300
EIGENLAYER_MAX_RETRIES=3
EIGENLAYER_RETRY_DELAY=60
```

#### 3. Fhenix FHE Integration
```bash
# RealFhenixFHE contract address
FHENIX_FHE_ADDRESS=0x0000000000000000000000000000000000000000

# Fhenix service address (authorized to submit results)
FHENIX_SERVICE_ADDRESS=0x0000000000000000000000000000000000000000
```

#### 4. Enhanced Hook Configuration
```bash
# ZKProofOfComplianceFull hook address
HOOK_ADDRESS=0x0000000000000000000000000000000000000000

# Verification mode (0-5, see below)
VERIFICATION_MODE=0

# Allow fallback (true/false)
ALLOW_FALLBACK=true
```

#### 5. Circuit Configuration (Optional)
```bash
# Paths to circuit files (defaults shown)
CIRCUIT_WASM_PATH=circuits/compliance_js/compliance.wasm
PROVING_KEY_PATH=circuits/compliance_0001.zkey
VERIFICATION_KEY_PATH=circuits/verification_key.json
```

## Complete .env Example

```bash
# ============================================
# Deployment Configuration
# ============================================
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
POOL_MANAGER_ADDRESS=0x0000000000000000000000000000000000000000

# ============================================
# Real ZK Proof Integration (Brevis)
# ============================================
GROTH16_VERIFIER_ADDRESS=0x0000000000000000000000000000000000000000
BREVIS_VERIFIER_ADDRESS=0x0000000000000000000000000000000000000000

# ============================================
# EigenLayer AVS Integration
# ============================================
EIGENLAYER_AVS_ADDRESS=0x0000000000000000000000000000000000000000
EIGENLAYER_OPERATORS=0x70997970C51812dc3A010C7d01b50e0d17dc79C8,0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC
EIGENLAYER_MIN_CONFIRMATIONS=2
EIGENLAYER_TIMEOUT=300
EIGENLAYER_MAX_RETRIES=3
EIGENLAYER_RETRY_DELAY=60

# ============================================
# Fhenix FHE Integration
# ============================================
FHENIX_FHE_ADDRESS=0x0000000000000000000000000000000000000000
FHENIX_SERVICE_ADDRESS=0x0000000000000000000000000000000000000000

# ============================================
# Enhanced Hook Configuration
# ============================================
HOOK_ADDRESS=0x0000000000000000000000000000000000000000
VERIFICATION_MODE=0
ALLOW_FALLBACK=true

# ============================================
# RPC URLs (Optional)
# ============================================
LOCAL_RPC_URL=http://localhost:8545
MAINNET_RPC_URL=
SEPOLIA_RPC_URL=

# ============================================
# Optional Configuration
# ============================================
ETHERSCAN_API_KEY=
ROUTER_ADDRESS=0x0000000000000000000000000000000000000000
```

## Verification Mode Options

Set `VERIFICATION_MODE` to one of these values:

- `0` = **BrevisOnly** - Only ZK proof verification (simplest, recommended for testing)
- `1` = **EigenLayerOnly** - Only EigenLayer AVS verification
- `2` = **FhenixOnly** - Only Fhenix FHE verification
- `3` = **HybridBrevisEigen** - Brevis primary, EigenLayer fallback
- `4` = **HybridEigenBrevis** - EigenLayer primary, Brevis fallback
- `5` = **HybridAll** - All three methods with fallback chain (most robust)

**Recommended for testing:** `0` (BrevisOnly)  
**Recommended for production:** `3` or `5` (Hybrid modes)

## Step-by-Step Setup

### Step 1: Copy .env.example
```bash
cp .env.example .env
```

### Step 2: Set Basic Variables
```bash
# For local testing with Anvil
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
POOL_MANAGER_ADDRESS=0x0000000000000000000000000000000000000000
```

### Step 3: Deploy Contracts (Addresses will be filled automatically)

After deploying each contract, update the corresponding address:

1. **Deploy Groth16 Verifier** → Update `GROTH16_VERIFIER_ADDRESS`
2. **Deploy RealBrevisVerifier** → Update `BREVIS_VERIFIER_ADDRESS`
3. **Deploy RealEigenLayerAVS** → Update `EIGENLAYER_AVS_ADDRESS`
4. **Deploy RealFhenixFHE** → Update `FHENIX_FHE_ADDRESS`
5. **Deploy ZKProofOfComplianceFull** → Update `HOOK_ADDRESS`

### Step 4: Configure EigenLayer Operators

For local testing, use Anvil accounts:
```bash
EIGENLAYER_OPERATORS=0x70997970C51812dc3A010C7d01b50e0d17dc79C8,0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC
```

For production, use actual EigenLayer operator addresses.

### Step 5: Set Verification Mode

For testing, start with:
```bash
VERIFICATION_MODE=0
ALLOW_FALLBACK=true
```

## Quick Start for Local Testing

If you just want to test locally with minimal setup:

```bash
# Minimal .env for local testing
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
POOL_MANAGER_ADDRESS=0x0000000000000000000000000000000000000000
LOCAL_RPC_URL=http://localhost:8545

# Set to 0x0 initially, will be updated after deployment
GROTH16_VERIFIER_ADDRESS=0x0000000000000000000000000000000000000000
BREVIS_VERIFIER_ADDRESS=0x0000000000000000000000000000000000000000
EIGENLAYER_AVS_ADDRESS=0x0000000000000000000000000000000000000000
FHENIX_FHE_ADDRESS=0x0000000000000000000000000000000000000000
HOOK_ADDRESS=0x0000000000000000000000000000000000000000

# Use Anvil accounts for operators
EIGENLAYER_OPERATORS=0x70997970C51812dc3A010C7d01b50e0d17dc79C8,0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC
EIGENLAYER_MIN_CONFIRMATIONS=2
EIGENLAYER_TIMEOUT=300
EIGENLAYER_MAX_RETRIES=3
EIGENLAYER_RETRY_DELAY=60

FHENIX_SERVICE_ADDRESS=0x0000000000000000000000000000000000000000

VERIFICATION_MODE=0
ALLOW_FALLBACK=true
```

## Verify Your .env File

After setting up, verify your configuration:

```bash
forge script script/CheckEnv.s.sol
```

This will check all required variables and report any issues.

## Additional Resources

- **Complete guide:** See `docs/ENV_SETUP_ENHANCED.md` for detailed instructions
- **Integration guide:** See `docs/REAL_INTEGRATIONS.md` for deployment steps
- **Example file:** See `.env.example` for a complete template

## Notes

1. **All addresses start with `0x0` initially** - They will be updated after deployment
2. **For local testing**, you can use Anvil's default accounts
3. **For production**, use secure key management and real operator addresses
4. **Never commit `.env` to git** - It's already in `.gitignore`

