# Fix: Insufficient Funds Error

## Problem

When deploying, you see:
```
Error: Failed to send transaction after 4 attempts 
Err(server returned an error response: error code -32003: Insufficient funds for gas * price + value)
```

## Solution

Your account in `.env` doesn't have ETH on the local Anvil node. Here are two solutions:

### Solution 1: Use Anvil's Default Account (Easiest)

Anvil provides 10 pre-funded accounts. Use the first one:

**Update your `.env`:**
```env
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

This account has **10,000 ETH** on Anvil.

**Then deploy:**
```bash
forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --broadcast
```

### Solution 2: Use Alternative Deployment Script

I've created a script that automatically uses Anvil's default account:

```bash
forge script script/DeployWithAnvilAccount.s.sol --rpc-url http://localhost:8545 --broadcast
```

This script uses Anvil's first account (which has 10,000 ETH) automatically.

### Solution 3: Fund Your Account Manually

If you want to use your own account:

1. **Get Anvil's default account address:**
   ```bash
   cast wallet address --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
   ```

2. **Send ETH from Anvil account to your account:**
   ```bash
   cast send YOUR_ACCOUNT_ADDRESS --value 100ether \
     --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
     --rpc-url http://localhost:8545
   ```

3. **Then deploy with your account:**
   ```bash
   forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --broadcast
   ```

## Quick Fix (Recommended)

**Just use Anvil's default account for local testing:**

```bash
# Update .env PRIVATE_KEY to:
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

# Then deploy
forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --broadcast
```

Or use the alternative script:
```bash
forge script script/DeployWithAnvilAccount.s.sol --rpc-url http://localhost:8545 --broadcast
```

## Anvil Default Accounts

Anvil provides these accounts (all have 10,000 ETH):

| Index | Address | Private Key |
|-------|---------|-------------|
| 0 | 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 | 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 |
| 1 | 0x70997970C51812dc3A010C7d01b50e0d17dc79C8 | 0x59c6995e998f97a5a0044966f0945389ac9e75b7d30b4795d05a844933977c9c |
| ... | ... | ... |

You can use any of these for local testing.

## Verify Account Balance

Check your account balance:
```bash
cast balance YOUR_ADDRESS --rpc-url http://localhost:8545
```

Check Anvil's default account:
```bash
cast balance 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 --rpc-url http://localhost:8545
# Should show: 10000000000000000000000 (10,000 ETH)
```

## Important Notes

- **Local Only**: These private keys are ONLY for local Anvil testing
- **Never Use on Mainnet**: Never use these keys on mainnet or testnet
- **Reset Anvil**: If you restart Anvil, all accounts reset to 10,000 ETH
- **Separate Keys**: Use different keys for testnet/mainnet deployment

