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
# In another terminal
forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --broadcast
```

**Note the addresses** from the output (or check `broadcast/Deploy.s.sol/31337/run-latest.json`)

### Step 3: Set User as Compliant

```bash
# Update script/InteractWithContracts.s.sol with new addresses first
forge script script/InteractWithContracts.s.sol --rpc-url http://localhost:8545 --broadcast
```

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
6. You're ready to trade! 🎉

## 📚 Documentation

- **[USER_GUIDE.md](docs/USER_GUIDE.md)**: Complete user guide
- **[PROJECT_EXPLANATION.md](docs/PROJECT_EXPLANATION.md)**: Deep dive into how it works
- **[FRONTEND_SETUP.md](docs/FRONTEND_SETUP.md)**: Frontend setup details
- **[README.md](README.md)**: Full project documentation

## 🎯 Current Deployment

**Latest Contract Addresses:**
- Hook: `0xa513E6E4b8f2a923D98304ec87F64353C4D5C853`
- Verifier: `0x0165878A594ca255338adfa4d48449f69242Eb8F`

**Update these in `frontend/src/App.tsx` before using the frontend!**

## 🔍 Quick Test

```bash
# Test that everything works
forge test --match-test test_CompliantUserCanSubmitProof -vv
```

## ❓ Need Help?

- Check the [USER_GUIDE.md](docs/USER_GUIDE.md) for detailed instructions
- See [PROJECT_EXPLANATION.md](docs/PROJECT_EXPLANATION.md) to understand the system
- Review [FRONTEND_SETUP.md](docs/FRONTEND_SETUP.md) for frontend issues

---

**Happy Building! 🚀**

