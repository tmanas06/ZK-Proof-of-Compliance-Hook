# Enhanced Environment Variables Setup Guide

This guide explains all environment variables needed for the enhanced ZK Proof-of-Compliance Hook system with real Brevis, EigenLayer AVS, and Fhenix FHE integrations.

## Quick Start

1. **Copy the example file:**
   ```bash
   cp .env.example .env
   ```

2. **Edit `.env` with your values** (see sections below)

3. **Verify `.env` is in `.gitignore`** (it should be already)

## Required Variables

### 1. Deployment Configuration

#### PRIVATE_KEY
**What it is:** The private key of the Ethereum account that will deploy contracts.

**How to get it:**
- **For local testing (Anvil):**
  ```
  PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
  ```
  This is Anvil's default first account with 10,000 ETH.

- **For production:**
  - Use MetaMask: Account details → Show private key
  - Or generate: `cast wallet new`
  - ⚠️ **NEVER share or commit this key!**

**Format:** `0x` followed by 64 hex characters

#### POOL_MANAGER_ADDRESS
**What it is:** The address of the Uniswap v4 PoolManager contract.

**Values:**
- **Local testing:** `0x0000000000000000000000000000000000000000`
- **Mainnet/Testnet:** Check Uniswap v4 documentation

---

### 2. Real ZK Proof Integration (Brevis)

#### GROTH16_VERIFIER_ADDRESS
**What it is:** The address of the Groth16 verifier contract that verifies zk-SNARK proofs on-chain.

**How to get it:**
1. **Generate the verifier contract:**
   ```bash
   # Compile your circuit
   circom circuits/compliance.circom --r1cs --wasm --sym
   
   # Generate trusted setup
   snarkjs powersoftau new bn128 14 pot14_0000.ptau -v
   snarkjs powersoftau contribute pot14_0000.ptau pot14_0001.ptau --name="First contribution" -v
   snarkjs powersoftau prepare phase2 pot14_0001.ptau pot14_final.ptau -v
   snarkjs groth16 setup compliance.r1cs pot14_final.ptau compliance_0000.zkey
   snarkjs zkey contribute compliance_0000.zkey compliance_0001.zkey --name="Second contribution" -v
   
   # Generate verifier contract
   snarkjs zkey export solidityverifier compliance_0001.zkey verifier.sol
   ```
   This creates `verifier.sol` (usually named `Groth16Verifier.sol`)

2. **Deploy the verifier contract:**
   - Use **Remix**, **Hardhat**, **Foundry**, or your preferred tool
   - Deploy `Groth16Verifier.sol` to your chain (Sepolia, Holesky, Base Sepolia, Anvil, etc.)
   - Copy the deployed contract address

3. **Add to .env:**
   ```bash
   GROTH16_VERIFIER_ADDRESS=0xYourDeployedVerifierAddress
   ```

**⚠️ Important:** You must deploy this yourself — it doesn't come from anywhere else.

**Format:** `0x` followed by 40 hex characters

#### BREVIS_VERIFIER_ADDRESS
**What it is:** The address of the `RealBrevisVerifier` contract.

**How to get it:**
- This will be output when you deploy `RealBrevisVerifier`
- Or check deployment logs
- Leave as `0x0` if not yet deployed

---

### 3. EigenLayer AVS Integration

#### EIGENLAYER_AVS_ADDRESS
**What it is:** The address of your EigenLayer AVS (Actively Validated Service) contract for off-chain verification.

**How to get it:**

**Option A: Use EigenLayer AVS Template (Recommended)**
1. Clone the EigenLayer AVS template:
   ```bash
   git clone https://github.com/Layr-Labs/eigenlayer-contracts
   cd eigenlayer-contracts
   ```

2. Deploy your AVS contracts:
   - Deploy `ServiceManager` contract
   - Deploy `Registry` contract
   - Set up operators

3. The `ServiceManager` address is your AVS address:
   ```bash
   EIGENLAYER_AVS_ADDRESS=0xYourServiceManagerAddress
   ```

**Option B: Use RealEigenLayerAVS Contract**
- Deploy `RealEigenLayerAVS.sol` from this project
- This will be output when you deploy
- Or check deployment logs
- Leave as `0x0` if not yet deployed

**⚠️ Important:** You must deploy this yourself using EigenLayer templates or our custom contract.

#### EIGENLAYER_OPERATORS
**What it is:** Comma-separated list of EigenLayer operator addresses.

**How to get it:**
- **For testing:** Use test addresses (e.g., Anvil accounts)
- **For production:** Use actual EigenLayer operator addresses

**Format:** `address1,address2,address3`
```
EIGENLAYER_OPERATORS=0x70997970C51812dc3A010C7d01b50e0d17dc79C8,0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC
```

**Recommendations:**
- Minimum 2 operators for testing
- 5+ operators for production
- Use reputable operators with stake

#### EIGENLAYER_MIN_CONFIRMATIONS
**What it is:** Minimum number of operator confirmations required for verification.

**Recommended values:**
- **Testing:** `2`
- **Production:** `5` or more

#### EIGENLAYER_TIMEOUT
**What it is:** Verification timeout in seconds.

**Default:** `300` (5 minutes)

**Adjust based on:**
- Network latency
- Operator response times
- Your requirements

#### EIGENLAYER_MAX_RETRIES
**What it is:** Maximum number of retry attempts for failed verifications.

**Default:** `3`

#### EIGENLAYER_RETRY_DELAY
**What it is:** Delay between retries in seconds.

**Default:** `60` (1 minute)

---

### 4. Fhenix FHE Integration

#### FHENIX_FHE_ADDRESS
**What it is:** The address of Fhenix's official FHE (Fully Homomorphic Encryption) contract on the Fhenix chain.

**How to get it:**
1. **Go to Fhenix documentation:**
   - Visit: https://docs.fhenix.io
   - Look for official contract addresses

2. **Find the FHE contract addresses:**
   - **FHE Library precompile** address
   - **Global FHE contract** address
   - These are official Fhenix contracts (not something you deploy)

3. **For Fhenix testnet:**
   - Check Fhenix testnet documentation
   - Use the official FHE contract address provided by Fhenix

4. **Add to .env:**
   ```bash
   FHENIX_FHE_ADDRESS=0xFhenixOfficialFHEContractAddress
   ```

**⚠️ Important:** This comes from Fhenix's official contracts — you don't deploy this yourself.

**Note:** If using `RealFhenixFHE.sol` from this project as a wrapper, you would deploy that and use its address instead.

#### FHENIX_SERVICE_ADDRESS
**What it is:** The address of your external service contract that processes encrypted data off-chain using FHE.

**How to get it:**

**⚠️ This is OPTIONAL** — Only needed if you build an external service for off-chain FHE computation.

**If building an external FHE service:**
1. Deploy a service contract that:
   - Receives encrypted compliance data
   - Processes it using FHE (off-chain)
   - Submits computation results back on-chain

2. This service contract communicates with Fhenix's FHE contracts

3. Copy the deployed service contract address:
   ```bash
   FHENIX_SERVICE_ADDRESS=0xYourServiceContractAddress
   ```

**If NOT building external service:**
- Leave as `0x0`
- The system will work without it (using on-chain FHE verification only)

**⚠️ Important:** You must deploy this yourself if you need off-chain FHE processing.

---

### 5. Enhanced Hook Configuration

#### HOOK_ADDRESS
**What it is:** The address of your Uniswap v4 Hook contract (e.g., `ZKProofOfComplianceFull.sol`).

**How to get it:**
1. **Deploy your Hook contract:**
   - Deploy `ZKProofOfComplianceFull.sol` (or your custom hook)
   - Use Remix, Hardhat, Foundry, or your preferred tool
   - Deploy to your chain (Sepolia, Holesky, Base Sepolia, Anvil, etc.)

2. **Copy the deployed address:**
   ```bash
   HOOK_ADDRESS=0xYourDeployedHookAddress
   ```

3. **This will be output when you deploy:**
   - Check deployment logs
   - Or query the deployment transaction

**⚠️ Important:** You must deploy this yourself — this is your main compliance hook contract.

**Format:** `0x` followed by 40 hex characters

#### VERIFICATION_MODE
**What it is:** The verification mode to use.

**Options:**
- `0` = BrevisOnly (ZK proof only)
- `1` = EigenLayerOnly (EigenLayer AVS only)
- `2` = FhenixOnly (Fhenix FHE only)
- `3` = HybridBrevisEigen (Brevis primary, EigenLayer fallback)
- `4` = HybridEigenBrevis (EigenLayer primary, Brevis fallback)
- `5` = HybridAll (Brevis → EigenLayer → Fhenix)

**Recommended:**
- **Testing:** `0` (BrevisOnly) - simplest
- **Production:** `3` or `5` (Hybrid modes) - more robust

#### ALLOW_FALLBACK
**What it is:** Whether to allow fallback verification methods.

**Values:**
- `true` - Try fallback methods if primary fails
- `false` - Fail immediately if primary fails

**Recommended:** `true` for production

---

## Optional Variables

### RPC URLs

#### LOCAL_RPC_URL
**Default:** `http://localhost:8545` (Anvil default)

#### MAINNET_RPC_URL
**How to get it:**
- **Infura:** https://infura.io → Create project → Copy HTTPS URL
- **Alchemy:** https://www.alchemy.com → Create app → Copy URL
- **Format:** `https://mainnet.infura.io/v3/YOUR_PROJECT_ID`

#### SEPOLIA_RPC_URL
**How to get it:**
- Same as mainnet, but select "Sepolia" network
- **Format:** `https://sepolia.infura.io/v3/YOUR_PROJECT_ID`

### Contract Verification

#### ETHERSCAN_API_KEY
**How to get it:**
1. Go to https://etherscan.io/apis
2. Sign up / Log in
3. Create API key
4. Copy the key

**Used for:** Verifying contracts on Etherscan after deployment

### Frontend Configuration

#### ROUTER_ADDRESS
**What it is:** The address of the `UniswapV4Router` contract.

**How to get it:**
- This will be output when you deploy `UniswapV4Router`
- Or check deployment logs
- Can also be set in the frontend UI

### Circuit Configuration

#### CIRCUIT_WASM_PATH
**Default:** `circuits/compliance_js/compliance.wasm`

**What it is:** Path to the compiled circuit WASM file.

#### PROVING_KEY_PATH
**Default:** `circuits/compliance_0001.zkey`

**What it is:** Path to the proving key for generating proofs.

#### VERIFICATION_KEY_PATH
**Default:** `circuits/verification_key.json`

**What it is:** Path to the verification key for verifying proofs.

---

## Deployment Order

When deploying contracts, follow this order:

1. **Deploy Groth16 Verifier** (from circuit compilation)
   - Update `GROTH16_VERIFIER_ADDRESS`

2. **Deploy RealBrevisVerifier**
   - Uses `GROTH16_VERIFIER_ADDRESS`
   - Update `BREVIS_VERIFIER_ADDRESS`

3. **Deploy RealEigenLayerAVS**
   - Uses `EIGENLAYER_OPERATORS`, `EIGENLAYER_MIN_CONFIRMATIONS`, etc.
   - Update `EIGENLAYER_AVS_ADDRESS`

4. **Deploy RealFhenixFHE**
   - Uses `FHENIX_SERVICE_ADDRESS`
   - Update `FHENIX_FHE_ADDRESS`

5. **Deploy ZKProofOfComplianceFull**
   - Uses all above addresses
   - Uses `VERIFICATION_MODE` and `ALLOW_FALLBACK`
   - Update `HOOK_ADDRESS`

6. **Deploy UniswapV4Router** (optional, for frontend)
   - Update `ROUTER_ADDRESS`

---

## Example .env File

```bash
# Deployment
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
POOL_MANAGER_ADDRESS=0x0000000000000000000000000000000000000000

# Brevis
GROTH16_VERIFIER_ADDRESS=0x0000000000000000000000000000000000000000
BREVIS_VERIFIER_ADDRESS=0x0000000000000000000000000000000000000000

# EigenLayer
EIGENLAYER_AVS_ADDRESS=0x0000000000000000000000000000000000000000
EIGENLAYER_OPERATORS=0x70997970C51812dc3A010C7d01b50e0d17dc79C8,0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC
EIGENLAYER_MIN_CONFIRMATIONS=2
EIGENLAYER_TIMEOUT=300
EIGENLAYER_MAX_RETRIES=3
EIGENLAYER_RETRY_DELAY=60

# Fhenix
FHENIX_FHE_ADDRESS=0x0000000000000000000000000000000000000000
FHENIX_SERVICE_ADDRESS=0x0000000000000000000000000000000000000000

# Hook
HOOK_ADDRESS=0x0000000000000000000000000000000000000000
VERIFICATION_MODE=0
ALLOW_FALLBACK=true

# RPC URLs
LOCAL_RPC_URL=http://localhost:8545
MAINNET_RPC_URL=
SEPOLIA_RPC_URL=

# Optional
ETHERSCAN_API_KEY=
ROUTER_ADDRESS=0x0000000000000000000000000000000000000000
```

---

## Verification

After setting up your `.env` file, verify it's correct:

```bash
forge script script/CheckEnv.s.sol
```

This will check all required variables and report any issues.

---

## Security Notes

1. **Never commit `.env` to git** - It's in `.gitignore`
2. **Never share your PRIVATE_KEY** - Keep it secure
3. **Use separate keys for testing and production**
4. **Consider hardware wallets for production**
5. **Rotate keys if compromised**

---

## Troubleshooting

### "Environment variable not found"
- Make sure `.env` file exists in project root
- Check variable name spelling (case-sensitive)
- Ensure no extra spaces around `=`

### "Invalid address format"
- Addresses must start with `0x`
- Must be 42 characters total (0x + 40 hex chars)
- Use checksummed addresses when possible

### "Invalid private key"
- Private key must start with `0x`
- Must be 66 characters total (0x + 64 hex chars)
- No spaces or special characters

---

## Additional Resources

- [Original ENV_SETUP.md](./ENV_SETUP.md) - Basic setup guide
- [REAL_INTEGRATIONS.md](./REAL_INTEGRATIONS.md) - Integration details
- [ARCHITECTURE_ENHANCED.md](./ARCHITECTURE_ENHANCED.md) - System architecture

