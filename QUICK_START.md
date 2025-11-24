# 🚀 Quick Start Guide

## What is This Project?

A **Uniswap v4 Hook** that requires users to submit **zero-knowledge compliance proofs** before they can swap tokens or add liquidity. This ensures regulatory compliance while preserving user privacy.

## ⚡ 5-Minute Setup

### Step 1: Start Local Blockchain

```bash
# In one terminal, start Anvil
anvil
```

### Step 2: Deploy Contracts

```bash
# Deploy router and pool manager
forge script script/DeployRouter.s.sol --rpc-url http://localhost:8545 --broadcast
```

**Note the addresses** from the output:
- Router: `0x09635F643e140090A9A8Dcd712eD6285858ceBef`
- PoolManager: `0x7a2088a1bFc9d81c55368AE168C2C02570cB814F`
- Hook: `0x67d269191c92caf3cd7723f116c85e6e9bf55933`
- Verifier: `0xc5a5c42992decbae36851359345fe25997f5c42d`

### Step 3: Set User as Compliant

**⚠️ IMPORTANT:** You must set your wallet address as compliant before you can submit proofs!

```bash
# Update script/InteractWithContracts.s.sol with new addresses first
# Then run:
forge script script/InteractWithContracts.s.sol --rpc-url http://localhost:8545 --broadcast
```

**If you see "UserNotCompliant" error:** This means your address isn't marked as compliant. Run the script above to fix it.

### Step 4: Start Frontend

```bash
cd frontend
npm install --legacy-peer-deps  # First time only (fixes dependency conflicts)
npm run dev
```

### Step 5: Use the App!

1. Open `http://localhost:5173` in your browser
2. Connect MetaMask (add localhost:8545 network)
3. Click "Connect Wallet"
4. Click "Generate Proof"
5. Click "Submit Proof"
6. **Now you can swap and add liquidity!** 🎉
   - Enter amount and click "Swap"
   - Or enter amount and click "Add Liquidity"

## 📚 Documentation

- **[USER_GUIDE.md](docs/USER_GUIDE.md)**: Complete user guide
- **[PROJECT_EXPLANATION.md](docs/PROJECT_EXPLANATION.md)**: Deep dive into how it works
- **[FRONTEND_SETUP.md](docs/FRONTEND_SETUP.md)**: Frontend setup details
- **[UNISWAP_V4_INTEGRATION.md](docs/UNISWAP_V4_INTEGRATION.md)**: Full integration guide
- **[README.md](README.md)**: Full project documentation

## 🎯 Current Deployment

**Latest Contract Addresses:**
- **Router**: `0x09635F643e140090A9A8Dcd712eD6285858ceBef`
- **PoolManager**: `0x7a2088a1bFc9d81c55368AE168C2C02570cB814F`
- **Hook**: `0x67d269191c92caf3cd7723f116c85e6e9bf55933`
- **Verifier**: `0xc5a5c42992decbae36851359345fe25997f5c42d`

**These are already set in the frontend!** But you can override them in the UI if needed.

## 🔍 Quick Test

```bash
# Test that everything works
forge test --match-test test_CompliantUserCanSubmitProof -vv
```

## ✅ What's Working

- ✅ **Full Uniswap v4 Integration** - Router and PoolManager deployed
- ✅ **Working Swaps** - Execute swaps through the frontend
- ✅ **Working Liquidity** - Add liquidity through the frontend
- ✅ **Hook Verification** - Compliance checks enforced
- ✅ **Proof Submission** - Submit and verify proofs
- ✅ **Frontend UI** - Complete React interface

## ❓ Need Help?

- Check the [USER_GUIDE.md](docs/USER_GUIDE.md) for detailed instructions
- See [PROJECT_EXPLANATION.md](docs/PROJECT_EXPLANATION.md) to understand the system
- Review [UNISWAP_V4_INTEGRATION.md](docs/UNISWAP_V4_INTEGRATION.md) for integration details
- Review [FRONTEND_SETUP.md](docs/FRONTEND_SETUP.md) for frontend issues

---

**Happy Building! 🚀**
