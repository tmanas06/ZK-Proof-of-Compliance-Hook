# Environment Variables Setup Guide

This guide explains how to set up your `.env` file with all necessary keys and values.

## Quick Start

1. **Copy the example file:**
   ```bash
   cp .env.example .env
   ```

2. **Edit `.env` with your values** (see sections below)

3. **Verify `.env` is in `.gitignore`** (it should be already)

## Required Variables

### 1. PRIVATE_KEY

**What it is:** The private key of the Ethereum account that will deploy contracts.

**How to get it:**
- **Option A: Use MetaMask**
  1. Open MetaMask
  2. Click account icon → Account details
  3. Click "Show private key"
  4. Enter password
  5. Copy the key (starts with `0x`)

- **Option B: Generate new key**
  ```bash
  # Using Foundry's cast
  cast wallet new
  
  # Or use a secure random generator
  # ⚠️ Store securely and never share!
  ```

**Format:** `0x` followed by 64 hex characters
```
PRIVATE_KEY=0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef
```

**⚠️ SECURITY WARNING:**
- Never commit this to git
- Never share this key
- Use a separate account for testing
- Consider using a hardware wallet for mainnet

---

### 2. POOL_MANAGER_ADDRESS

**What it is:** The address of the Uniswap v4 PoolManager contract.

**How to get it:**

- **Mainnet:**
  - Check Uniswap v4 documentation
  - Or query Uniswap v4 factory contract
  - Currently: TBD (Uniswap v4 not yet on mainnet)

- **Testnet (Sepolia):**
  - Check Uniswap v4 testnet deployment
  - Or use Uniswap v4 testnet documentation
  - Currently: TBD

- **Local Development:**
  - Use mock address: `0x0000000000000000000000000000000000000000`
  - Or deploy local Uniswap v4 contracts

**Format:** Ethereum address (0x followed by 40 hex characters)
```
POOL_MANAGER_ADDRESS=0x1234567890123456789012345678901234567890
```

---

### 3. RPC URLs

**What they are:** Endpoints to connect to Ethereum networks.

#### MAINNET_RPC_URL

**How to get it:**

- **Option A: Infura (Recommended)**
  1. Go to https://infura.io
  2. Sign up for free account
  3. Create a new project
  4. Select "Ethereum" network
  5. Copy the HTTPS endpoint
  6. Format: `https://mainnet.infura.io/v3/YOUR_PROJECT_ID`

- **Option B: Alchemy**
  1. Go to https://www.alchemy.com
  2. Sign up for free account
  3. Create a new app
  4. Select "Ethereum" network
  5. Copy the HTTPS URL
  6. Format: `https://eth-mainnet.g.alchemy.com/v2/YOUR_API_KEY`

- **Option C: Public RPC (Not Recommended)**
  - `https://eth.llamarpc.com`
  - `https://rpc.ankr.com/eth`
  - ⚠️ Rate limited and unreliable

**Format:**
```
MAINNET_RPC_URL=https://mainnet.infura.io/v3/YOUR_INFURA_KEY
```

#### SEPOLIA_RPC_URL

**How to get it:**

- **Infura:**
  - Same as mainnet, but select "Sepolia" network
  - Format: `https://sepolia.infura.io/v3/YOUR_PROJECT_ID`

- **Alchemy:**
  - Same as mainnet, but select "Sepolia" network
  - Format: `https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY`

- **Public:**
  - `https://rpc.sepolia.org`

**Format:**
```
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/YOUR_INFURA_KEY
```

#### LOCAL_RPC_URL

**For local development:**
```
LOCAL_RPC_URL=http://localhost:8545
```

Start local node:
```bash
# Using Anvil (Foundry)
anvil

# Using Hardhat
npx hardhat node
```

---

### 4. ETHERSCAN_API_KEY

**What it is:** API key for verifying contracts on Etherscan.

**How to get it:**
1. Go to https://etherscan.io
2. Sign up for free account
3. Go to https://etherscan.io/apis
4. Click "Create API Key"
5. Name your key (e.g., "Uniswap Hook")
6. Copy the API key

**Format:**
```
ETHERSCAN_API_KEY=ABC123XYZ789...
```

**Note:** Not required for local development, only for testnet/mainnet deployment.

---

## Optional Variables

### 5. Contract Addresses (Auto-populated)

These are set automatically after deployment, but you can set them manually:

```
HOOK_ADDRESS=0x...
VERIFIER_ADDRESS=0x...
EIGENLAYER_AVS_ADDRESS=0x...
```

### 6. BREVIS_API_KEY

**What it is:** API key for Brevis Network services (if using production Brevis).

**How to get it:**
1. Go to Brevis Network website
2. Sign up for account
3. Navigate to API keys section
4. Generate new API key
5. Copy the key

**Format:**
```
BREVIS_API_KEY=your_brevis_api_key_here
```

**Note:** Not required for local development with mock verifier.

### 7. EIGENLAYER_OPERATORS

**What it is:** Comma-separated list of EigenLayer AVS operator addresses.

**How to get it:**
1. Check EigenLayer documentation
2. Query EigenLayer registry
3. Or use test operators for development

**Format:**
```
EIGENLAYER_OPERATORS=0x1234...,0x5678...,0x9abc...
```

### 8. FHENIX_API_KEY

**What it is:** API key for Fhenix FHE services (if using production Fhenix).

**How to get it:**
1. Go to Fhenix website
2. Sign up for account
3. Navigate to API section
4. Generate API key
5. Copy the key

**Format:**
```
FHENIX_API_KEY=your_fhenix_api_key_here
```

**Note:** Currently placeholder, not required for development.

---

## Setup Steps

### Step 1: Create .env File

```bash
# Copy example file
cp .env.example .env

# Edit with your favorite editor
nano .env
# or
code .env
# or
notepad .env
```

### Step 2: Fill Required Variables

Minimum required for local development:
```
PRIVATE_KEY=0x...your_key...
POOL_MANAGER_ADDRESS=0x0000000000000000000000000000000000000000
LOCAL_RPC_URL=http://localhost:8545
```

For testnet deployment:
```
PRIVATE_KEY=0x...your_key...
POOL_MANAGER_ADDRESS=0x...testnet_pool_manager...
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/YOUR_KEY
ETHERSCAN_API_KEY=your_etherscan_key
```

For mainnet deployment:
```
PRIVATE_KEY=0x...your_key...  # Use hardware wallet!
POOL_MANAGER_ADDRESS=0x...mainnet_pool_manager...
MAINNET_RPC_URL=https://mainnet.infura.io/v3/YOUR_KEY
ETHERSCAN_API_KEY=your_etherscan_key
```

### Step 3: Verify Setup

```bash
# Check if .env is loaded (Foundry)
forge script script/Deploy.s.sol --dry-run

# Or test with a simple script
forge script script/TestEnv.s.sol
```

### Step 4: Security Check

✅ **Verify `.env` is in `.gitignore`:**
```bash
cat .gitignore | grep .env
# Should show: .env
```

✅ **Never commit `.env`:**
```bash
git status
# .env should NOT appear in changes
```

---

## Example .env Files

### Local Development
```env
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
POOL_MANAGER_ADDRESS=0x0000000000000000000000000000000000000000
LOCAL_RPC_URL=http://localhost:8545
```

### Sepolia Testnet
```env
PRIVATE_KEY=0x...your_testnet_key...
POOL_MANAGER_ADDRESS=0x...testnet_address...
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/YOUR_KEY
ETHERSCAN_API_KEY=your_etherscan_key
```

### Mainnet (Production)
```env
PRIVATE_KEY=0x...your_mainnet_key...  # Use hardware wallet!
POOL_MANAGER_ADDRESS=0x...mainnet_address...
MAINNET_RPC_URL=https://mainnet.infura.io/v3/YOUR_KEY
ETHERSCAN_API_KEY=your_etherscan_key
BREVIS_API_KEY=your_brevis_key
EIGENLAYER_OPERATORS=0x...,0x...
```

---

## Troubleshooting

### "PRIVATE_KEY not found"
- Make sure `.env` file exists
- Check variable name is exactly `PRIVATE_KEY`
- Verify no extra spaces or quotes

### "Invalid private key"
- Must start with `0x`
- Must be 66 characters total (0x + 64 hex)
- No spaces or newlines

### "RPC URL not working"
- Check your API key is correct
- Verify network (mainnet/testnet)
- Try a different RPC provider
- Check rate limits

### "Contract verification failed"
- Verify ETHERSCAN_API_KEY is correct
- Check network matches (mainnet vs testnet)
- Ensure contract is deployed first

---

## Security Best Practices

1. **Never commit `.env`** - Already in `.gitignore`
2. **Use separate keys for testnet/mainnet**
3. **Use hardware wallet for mainnet private keys**
4. **Rotate keys regularly**
5. **Use environment-specific files** (`.env.local`, `.env.production`)
6. **Limit API key permissions**
7. **Monitor API usage**

---

## Next Steps

After setting up `.env`:

1. **Test locally:**
   ```bash
   anvil
   # In another terminal
   forge script script/Deploy.s.sol --rpc-url http://localhost:8545
   ```

2. **Deploy to testnet:**
   ```bash
   forge script script/Deploy.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --verify
   ```

3. **Update frontend:**
   - Update contract addresses in `frontend/src/App.tsx`
   - Or use environment variables in frontend

