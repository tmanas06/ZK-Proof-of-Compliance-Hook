# User Guide: ZK Proof-of-Compliance Hook

## 📖 Project Overview

This is a **Uniswap v4 Hook** system that enforces compliance requirements for users who want to swap tokens or provide liquidity. Instead of revealing personal information (like KYC status, age, location) on-chain, users generate **zero-knowledge proofs** that prove they meet compliance requirements without exposing the underlying data.

### Key Concepts

1. **Zero-Knowledge Proofs (ZKPs)**: Cryptographic proofs that verify you meet certain criteria (e.g., "I'm over 18" or "I passed KYC") without revealing the actual data.

2. **Uniswap v4 Hooks**: Custom logic that runs before/after swaps and liquidity operations, allowing pools to enforce custom rules.

3. **Brevis Network**: The ZK proof verification system that validates your compliance proofs.

4. **EigenLayer AVS**: A decentralized verification service that provides additional security through multiple validators.

## 🏗️ Architecture

```
┌─────────────────┐
│   User Wallet   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐      ┌──────────────────┐
│  Frontend App    │─────▶│  Proof Generator │
│  (React/TS)      │      │  (Mock/Sim)      │
└────────┬─────────┘      └──────────────────┘
         │
         ▼
┌─────────────────┐      ┌──────────────────┐
│  Uniswap v4     │─────▶│  ZKProofOf       │
│  PoolManager    │      │  Compliance Hook  │
└─────────────────┘      └────────┬──────────┘
                                  │
                    ┌─────────────┼─────────────┐
                    ▼             ▼             ▼
         ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
         │   Brevis     │  │  EigenLayer │  │   Fhenix     │
         │  Verifier    │  │     AVS     │  │     FHE      │
         └──────────────┘  └──────────────┘  └──────────────┘
```

## 🚀 How to Use the System

### For End Users

#### Step 1: Set Up Your Environment

1. **Install MetaMask** (or another Web3 wallet)
2. **Connect to Local Network**:
   - Open MetaMask
   - Add network: `http://localhost:8545` (Chain ID: 31337)
   - Import Anvil account for testing (private key from `.env`)

#### Step 2: Start the Frontend

```bash
# Navigate to frontend directory
cd frontend

# Install dependencies (first time only)
npm install

# Start the development server
npm run dev
```

The frontend will open at `http://localhost:5173` (or similar port).

#### Step 3: Connect Your Wallet

1. Click "Connect Wallet" in the frontend
2. Approve the connection in MetaMask
3. Your wallet address will be displayed

#### Step 4: Generate and Submit Compliance Proof

1. **Check Compliance Status**: The app will show if you're marked as compliant
2. **Generate Proof**: Click "Generate Proof" to create a ZK compliance proof
3. **Submit Proof**: Click "Submit Proof" to send it to the hook contract
4. **Verify**: The app will show your proof status and compliance hash

#### Step 5: Interact with Uniswap Pool

Once your proof is submitted:
- You can now swap tokens through the Uniswap pool
- You can add liquidity to the pool
- The hook will automatically verify your proof before allowing the transaction

### For Developers/Admins

#### Setting User Compliance

To mark a user as compliant (for testing):

```bash
# Use the interaction script
forge script script/InteractWithContracts.s.sol --rpc-url http://localhost:8545 --broadcast
```

Or call directly:

```solidity
// In a script or contract
BrevisVerifier verifier = BrevisVerifier(VERIFIER_ADDRESS);
ComplianceData memory data = ComplianceData.createCompliantData();
bytes32 dataHash = ComplianceData.hashComplianceData(data);
verifier.setUserCompliance(userAddress, true, dataHash);
```

#### Updating Contract Addresses in Frontend

1. Open `frontend/src/App.tsx`
2. Update the addresses:
   ```typescript
   const HOOK_ADDRESS = '0xa513E6E4b8f2a923D98304ec87F64353C4D5C853'
   const VERIFIER_ADDRESS = '0x0165878A594ca255338adfa4d48449f69242Eb8F'
   ```

## 🎨 Frontend Features

The frontend includes several components:

### 1. **WalletConnection**
- Connect/disconnect MetaMask wallet
- Display connected address
- Network status

### 2. **ComplianceStatus**
- Shows if user is marked as compliant
- Displays compliance data hash
- Real-time status updates

### 3. **ProofGenerator**
- Generate mock ZK proofs
- Submit proofs to the hook
- View proof hash and details

### 4. **PoolInteraction**
- Simulate swap operations
- Simulate liquidity provision
- View transaction status

### 5. **EigenLayerStatus**
- Check EigenLayer AVS verification status
- View verification requests
- Monitor async verification results

### 6. **FhenixIntegration**
- Placeholder for FHE integration
- Future privacy-preserving computation

## 📝 Workflow Example

### Complete User Journey

1. **User connects wallet** → Frontend detects MetaMask
2. **Admin sets user as compliant** → Via script or admin function
3. **User generates proof** → Frontend creates mock ZK proof
4. **User submits proof** → Transaction sent to hook contract
5. **Hook verifies proof** → Calls Brevis verifier
6. **Proof recorded** → User can now interact with pool
7. **User swaps tokens** → Hook checks proof before allowing swap
8. **Transaction succeeds** → User receives tokens

### Example Transaction Flow

```
User wants to swap 100 USDC for ETH:

1. User initiates swap on Uniswap
2. Uniswap calls PoolManager.swap()
3. PoolManager calls hook.beforeSwap()
4. Hook checks:
   - Is user compliant? ✅
   - Has valid proof? ✅
   - Proof not expired? ✅
   - Proof not reused? ✅
5. Hook allows swap to proceed
6. Swap executes successfully
```

## 🔧 Configuration

### Compliance Requirements

The hook can be configured with different requirements:

```solidity
ComplianceRequirements({
    requireKYC: true,              // Must pass KYC
    requireAgeVerification: true,   // Must verify age
    requireLocationCheck: true,     // Must pass location check
    requireSanctionsCheck: true,    // Must pass sanctions check
    minAge: 18                      // Minimum age requirement
})
```

### Verification Modes

The enhanced hook supports multiple verification modes:

- **BrevisOnly**: Only use Brevis ZK verification
- **EigenLayerOnly**: Only use EigenLayer AVS
- **Hybrid**: Try EigenLayer first, fallback to Brevis
- **HybridReverse**: Try Brevis first, fallback to EigenLayer

## 🧪 Testing

### Run Frontend Tests

```bash
cd frontend
npm test
```

### Run Contract Tests

```bash
# All tests
forge test

# Specific test
forge test --match-test test_CompliantUserCanSubmitProof -vv

# With gas reporting
forge test --gas-report
```

### Test User Flow

1. Start Anvil: `anvil`
2. Deploy contracts: `forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --broadcast`
3. Set user as compliant: `forge script script/InteractWithContracts.s.sol --rpc-url http://localhost:8545 --broadcast`
4. Start frontend: `cd frontend && npm run dev`
5. Connect wallet and test!

## 📚 Additional Resources

- **Architecture Details**: See `docs/ARCHITECTURE.md`
- **Environment Setup**: See `docs/ENV_SETUP.md`
- **Local Deployment**: See `docs/LOCAL_DEPLOYMENT.md`
- **Brevis Circuit**: See `docs/BREVIS_CIRCUIT.md`

## ❓ Troubleshooting

### Frontend won't connect to wallet
- Ensure MetaMask is installed
- Check network is set to localhost:8545
- Verify Anvil is running

### Proof submission fails
- Check user is marked as compliant in verifier
- Verify contract addresses are correct
- Check proof hasn't expired (30 days default)

### Transactions revert
- Ensure user has submitted a valid proof
- Check proof hasn't been used before (replay protection)
- Verify hook is enabled

## 🎯 Next Steps

1. **Integrate Real Brevis Network**: Replace mock verifier with actual Brevis contracts
2. **Deploy to Testnet**: Test on Sepolia or other testnets
3. **Add Real ZK Circuit**: Implement actual compliance proof circuit
4. **Integrate Fhenix**: Add fully homomorphic encryption layer
5. **Production Deployment**: Deploy to mainnet after thorough testing

---

**Need Help?** Check the documentation files or open an issue!

