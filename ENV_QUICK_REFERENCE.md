# .env File Quick Reference

## 🎯 Quick Summary

Based on your clarifications, here's what each address is and where it comes from:

### ✅ You Deploy Yourself

| Variable | What It Is | How to Get It |
|----------|-----------|---------------|
| `GROTH16_VERIFIER_ADDRESS` | Your Groth16 verifier contract | 1. Generate: `snarkjs zkey export solidityverifier`<br>2. Deploy `verifier.sol` in Remix/Hardhat/Foundry<br>3. Copy deployed address |
| `EIGENLAYER_AVS_ADDRESS` | Your EigenLayer AVS contract | 1. Clone: https://github.com/Layr-Labs/eigenlayer-contracts<br>2. Deploy ServiceManager<br>3. Use ServiceManager address |
| `HOOK_ADDRESS` | Your Uniswap v4 Hook contract | 1. Deploy `ZKProofOfComplianceFull.sol`<br>2. Copy deployed address |
| `FHENIX_SERVICE_ADDRESS` | Your external FHE service (optional) | 1. Build service contract<br>2. Deploy it<br>3. Copy address (or leave as 0x0) |

### 📍 From Official Sources

| Variable | What It Is | How to Get It |
|----------|-----------|---------------|
| `FHENIX_FHE_ADDRESS` | Fhenix's official FHE contract | 1. Visit: https://docs.fhenix.io<br>2. Find official FHE contract address<br>3. Copy address |

### 🔧 Auto-Generated (After Deployment)

| Variable | What It Is | How to Get It |
|----------|-----------|---------------|
| `BREVIS_VERIFIER_ADDRESS` | RealBrevisVerifier contract | Deploy after Groth16 verifier → copy address |

---

## 📝 Minimal .env for Local Testing

```bash
# Deployment
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
POOL_MANAGER_ADDRESS=0x0000000000000000000000000000000000000000

# Step 1: Deploy Groth16 Verifier (you deploy)
GROTH16_VERIFIER_ADDRESS=0x0000000000000000000000000000000000000000

# Step 2: Deploy RealBrevisVerifier (auto-generated after Step 1)
BREVIS_VERIFIER_ADDRESS=0x0000000000000000000000000000000000000000

# Step 3: Deploy EigenLayer AVS (you deploy)
EIGENLAYER_AVS_ADDRESS=0x0000000000000000000000000000000000000000
EIGENLAYER_OPERATORS=0x70997970C51812dc3A010C7d01b50e0d17dc79C8,0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC
EIGENLAYER_MIN_CONFIRMATIONS=2
EIGENLAYER_TIMEOUT=300
EIGENLAYER_MAX_RETRIES=3
EIGENLAYER_RETRY_DELAY=60

# Step 4: Get Fhenix FHE address (from Fhenix docs)
FHENIX_FHE_ADDRESS=0x0000000000000000000000000000000000000000

# Step 5: Deploy Fhenix Service (optional - you deploy if needed)
FHENIX_SERVICE_ADDRESS=0x0000000000000000000000000000000000000000

# Step 6: Deploy Hook (you deploy)
HOOK_ADDRESS=0x0000000000000000000000000000000000000000
VERIFICATION_MODE=0
ALLOW_FALLBACK=true

# RPC
LOCAL_RPC_URL=http://localhost:8545
```

---

## 🚀 Deployment Order

1. **Deploy Groth16 Verifier** → Update `GROTH16_VERIFIER_ADDRESS`
2. **Deploy RealBrevisVerifier** → Update `BREVIS_VERIFIER_ADDRESS`
3. **Deploy EigenLayer AVS** → Update `EIGENLAYER_AVS_ADDRESS`
4. **Get Fhenix FHE address** → Update `FHENIX_FHE_ADDRESS` (from docs)
5. **Deploy Fhenix Service** (optional) → Update `FHENIX_SERVICE_ADDRESS`
6. **Deploy Hook** → Update `HOOK_ADDRESS`

---

## 📚 Detailed Guides

- **Complete setup:** `docs/ENV_SETUP_ENHANCED.md`
- **Deployment steps:** `docs/DEPLOYMENT_STEPS.md`
- **Integration guide:** `docs/REAL_INTEGRATIONS.md`

---

## ⚠️ Important Notes

1. **GROTH16_VERIFIER_ADDRESS**: You must deploy this yourself from generated verifier contract
2. **EIGENLAYER_AVS_ADDRESS**: You must deploy this yourself using EigenLayer templates
3. **FHENIX_FHE_ADDRESS**: This comes from Fhenix's official contracts (not something you deploy)
4. **HOOK_ADDRESS**: You must deploy this yourself
5. **FHENIX_SERVICE_ADDRESS**: Optional - only if building external FHE service

