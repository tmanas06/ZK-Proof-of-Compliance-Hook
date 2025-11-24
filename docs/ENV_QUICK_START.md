# Quick Start: Environment Variables

## Step 1: Create .env File

Create a file named `.env` in the project root:

```bash
# In Git Bash or terminal
touch .env
```

## Step 2: Add Required Variables

Copy this template into your `.env` file and fill in your values:

```env
# Required for deployment
PRIVATE_KEY=0x0000000000000000000000000000000000000000000000000000000000000000
POOL_MANAGER_ADDRESS=0x0000000000000000000000000000000000000000

# RPC URLs (choose based on network)
LOCAL_RPC_URL=http://localhost:8545
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/YOUR_KEY
MAINNET_RPC_URL=https://mainnet.infura.io/v3/YOUR_KEY

# Optional: For contract verification
ETHERSCAN_API_KEY=your_key_here
```

## Step 3: Get Your Keys

### PRIVATE_KEY
- **From MetaMask:** Account → Account details → Show private key
- **Generate new:** `cast wallet new` (Foundry)
- **Format:** Must start with `0x` and be 66 characters

### RPC URLs
- **Infura:** https://infura.io → Create project → Copy endpoint
- **Alchemy:** https://alchemy.com → Create app → Copy URL
- **Format:** `https://network.infura.io/v3/YOUR_KEY`

### ETHERSCAN_API_KEY
- **Get it:** https://etherscan.io/apis → Create API key
- **Optional:** Only needed for contract verification

## Step 4: Test Your Setup

```bash
forge script script/TestEnv.s.sol
```

This will verify your `.env` file is configured correctly.

## Full Guide

See [docs/ENV_SETUP.md](docs/ENV_SETUP.md) for complete instructions.

