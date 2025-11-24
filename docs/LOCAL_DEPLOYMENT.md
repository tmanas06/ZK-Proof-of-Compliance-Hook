# Local Deployment Guide

## Starting a Local Node

Before deploying contracts locally, you need to start a local blockchain node.

### Option 1: Using Anvil (Foundry) - Recommended

**In Git Bash:**
```bash
# Start Anvil in a separate terminal
anvil

# Or run in background
anvil &
```

**In PowerShell:**
```powershell
# Anvil doesn't work in PowerShell, use Git Bash instead
# Or use WSL
```

**Anvil will:**
- Start on `http://localhost:8545`
- Create 10 test accounts with 10,000 ETH each
- Show private keys and addresses
- Run on chain ID 31337

### Option 2: Using Hardhat Node

```bash
# Install Hardhat (if not already installed)
npm install --save-dev hardhat

# Start node
npx hardhat node
```

## Deploying to Local Node

Once your local node is running:

### Step 1: Start Anvil (in separate terminal)

```bash
# In Git Bash
anvil
```

You should see output like:
```
Available Accounts
==================
(0) 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 (10000 ETH)
...

Private Keys
==================
0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
...
```

### Step 2: Update .env (if needed)

For local deployment, you can use one of Anvil's private keys:

```env
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
POOL_MANAGER_ADDRESS=0x0000000000000000000000000000000000000000
LOCAL_RPC_URL=http://localhost:8545
```

### Step 3: Deploy Contracts

```bash
# In Git Bash (not PowerShell)
forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --broadcast
```

### Step 4: Verify Deployment

After deployment, you'll see:
- Contract addresses
- Transaction hashes
- Gas used

## Troubleshooting

### "Connection refused" Error

**Problem:** No local node is running

**Solution:**
1. Start Anvil: `anvil`
2. Wait for it to fully start
3. Verify it's running: Check terminal output for "Listening on 127.0.0.1:8545"

### "Insufficient funds" Error

**Problem:** Account doesn't have enough ETH

**Solution:**
- Use one of Anvil's default accounts (they have 10,000 ETH)
- Or fund your account from another Anvil account

### "Invalid private key" Error

**Problem:** PRIVATE_KEY format is wrong

**Solution:**
- Must start with `0x`
- Must be 66 characters total (0x + 64 hex)
- No spaces or newlines

## Quick Start Commands

```bash
# Terminal 1: Start Anvil
anvil

# Terminal 2: Deploy
forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --broadcast

# Terminal 2: Run tests (uses Anvil automatically)
forge test
```

## Using Anvil Accounts

Anvil provides 10 pre-funded accounts. You can:

1. **Use default account:**
   ```env
   PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
   ```

2. **Or use any other account from Anvil output**

3. **Or create new account:**
   ```bash
   cast wallet new
   ```

## Next Steps

After local deployment:
1. Test your contracts: `forge test`
2. Interact with contracts using `cast` or frontend
3. Deploy to testnet when ready

