# User Flow: ZK Proof-of-Compliance Hook

## 📋 Overview

This document explains the complete user flow for the ZK Proof-of-Compliance system, from initial setup to executing swaps and liquidity operations on Uniswap v4.

---

## 🎯 High-Level Flow

```
1. Setup & Deployment (Admin/Developer)
   ↓
2. User Registration & Compliance Setup (Admin)
   ↓
3. User Connects Wallet (End User)
   ↓
4. User Generates & Submits ZK Proof (End User)
   ↓
5. User Interacts with Pool (Swap/LP) (End User)
   ↓
6. Optional: EigenLayer Verification (End User)
```

---

## 🔧 Phase 1: Initial Setup (Admin/Developer)

### Step 1.1: Deploy Contracts

**Who**: Developer/Admin  
**What**: Deploy smart contracts to the blockchain

```bash
# Start local blockchain (Anvil)
anvil

# Deploy contracts
forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --broadcast
```

**Contracts Deployed**:
- `BrevisVerifier`: Verifies ZK proofs
- `ZKProofOfCompliance`: Main hook that enforces compliance
- `UniswapV4Router`: Router for swap/LP operations
- `MockPoolManager`: Mock pool manager for testing

**Output**: Contract addresses saved to `.env` or deployment logs

---

### Step 1.2: Mark Users as Compliant

**Who**: Admin  
**What**: Set up users in the compliance system

```bash
# Run interaction script to mark a user as compliant
forge script script/InteractWithContracts.s.sol --rpc-url http://localhost:8545 --broadcast
```

**What Happens**:
1. Admin calls `BrevisVerifier.setUserCompliance(userAddress, true, dataHash)`
2. User is marked as compliant in the system
3. A compliance data hash is stored for the user

**Note**: In production, this would be done by a KYC provider or compliance service.

---

## 👤 Phase 2: End User Flow

### Step 2.1: Connect Wallet

**Who**: End User  
**What**: Connect MetaMask or another Web3 wallet to the frontend

**User Actions**:
1. Navigate to `http://localhost:5173` (frontend)
2. Click **"Connect Wallet"** button
3. Approve connection in MetaMask
4. Select account to connect

**What Happens Behind the Scenes**:
- Frontend reads wallet address
- Calls `BrevisVerifier.isUserCompliant(userAddress)` to check status
- Displays compliance status in the UI

**UI Display**:
- ✅ **Compliant**: Green shield icon, "Compliant" status
- ❌ **Not Compliant**: Red X icon, "Not Compliant" status
- ⏳ **Loading**: Shield icon, "Checking compliance status..."

---

### Step 2.2: Check Compliance Status

**Who**: End User  
**What**: View current compliance status

**UI Components**:
- **Compliance Status Card**: Shows if user is compliant
- **Compliance Hash**: Displays the hash of compliance data (if compliant)

**What Happens**:
- Frontend queries `BrevisVerifier.isUserCompliant(address)`
- Frontend queries `BrevisVerifier.getUserComplianceHash(address)`
- Status is displayed in real-time

**Possible States**:
1. **Not Compliant**: User needs to be marked as compliant by admin first
2. **Compliant (No Proof)**: User is compliant but hasn't submitted a proof yet
3. **Compliant (With Proof)**: User has submitted a valid proof and can trade

---

### Step 2.3: Generate & Submit ZK Proof

**Who**: End User  
**What**: Generate a zero-knowledge proof and submit it to the hook

**User Actions**:
1. Click **"Generate Proof"** button in the Proof Generator card
2. Wait for proof generation (simulated ~2 seconds)
3. Proof is automatically submitted to the hook contract

**What Happens Behind the Scenes**:

```
1. Frontend creates a mock ZK proof:
   - proofHash: keccak256(userAddress + dataHash + timestamp + nonce)
   - publicInputs: Encoded compliance data hash
   - timestamp: Current block timestamp
   - user: User's wallet address

2. Frontend calls hook.submitProof(proof)

3. Hook contract verifies:
   a. Checks proof.user == msg.sender
   b. Gets expected dataHash from BrevisVerifier
   c. Calls BrevisVerifier.verifyProof(proof, expectedDataHash)
   d. Checks if proof has been used (replay protection)
   e. Marks proof as used
   f. Stores userComplianceHashes[user] = dataHash

4. Transaction is mined
5. Frontend refreshes compliance status
```

**Success Indicators**:
- ✅ Green success message: "Proof generated successfully!"
- ✅ Proof hash displayed
- ✅ Compliance status updates to show proof is active

**Error Handling**:
- ❌ **UserNotCompliant**: User must be marked as compliant by admin first
- ❌ **InvalidProof**: Proof verification failed
- ❌ **ProofAlreadyUsed**: This proof was already submitted
- ❌ **ProofExpired**: Proof timestamp is too old

**User-Friendly Error Messages**:
- All errors are decoded and shown with actionable help text
- Example: "❌ You are not marked as compliant. Please contact an administrator..."

---

### Step 2.4: Execute Swap

**Who**: End User  
**What**: Swap tokens on Uniswap v4 pool

**Prerequisites**:
- ✅ User must be compliant
- ✅ User must have submitted a valid proof
- ✅ Router address must be configured

**User Actions**:
1. Enter swap amount in the "Swap Tokens" card
2. Click **"Swap"** button
3. Approve transaction in MetaMask
4. Wait for confirmation

**What Happens Behind the Scenes**:

```
1. Frontend creates a new proof hash (to avoid replay):
   - Uses existing complianceHash as base
   - Adds timestamp and random nonce for uniqueness

2. Frontend calls router.swap(poolKey, swapParams, hookData):
   - poolKey: Defines the pool (token0, token1, fee, tickSpacing, hooks)
   - swapParams: Swap direction, amount, price limit
   - hookData: Encoded compliance proof

3. Router calls poolManager.lock(operationData)

4. PoolManager decodes operation and calls hook.beforeSwap()

5. Hook verifies compliance:
   a. Decodes proof from hookData
   b. Checks if user already has valid complianceHash stored
   c. If yes, allows transaction (proof reuse for efficiency)
   d. If no, verifies proof using BrevisVerifier
   e. Marks proof as used and stores complianceHash

6. If verification passes:
   - Swap executes
   - Hook.beforeSwap() returns success selector
   - Transaction completes

7. If verification fails:
   - Hook reverts with custom error
   - Swap is blocked
   - User sees error message
```

**Success Indicators**:
- ✅ Transaction hash displayed
- ✅ "Swap completed successfully!" message
- ✅ Transaction appears in wallet history

**Error Handling**:
- All errors are decoded and shown with actionable help
- Common errors:
  - "Router address not set" → Configure router address in UI
  - "No compliance proof found" → Generate and submit proof first
  - "User not compliant" → Contact admin to mark as compliant

---

### Step 2.5: Add Liquidity

**Who**: End User  
**What**: Add liquidity to Uniswap v4 pool

**Prerequisites**: Same as swap (compliant + proof submitted)

**User Actions**:
1. Enter liquidity amount in the "Add Liquidity" card
2. Click **"Add Liquidity"** button
3. Approve transaction in MetaMask
4. Wait for confirmation

**What Happens Behind the Scenes**:

```
1. Frontend creates a new proof hash (to avoid replay)

2. Frontend calls router.modifyLiquidity(poolKey, liqParams, hookData)

3. Router calls poolManager.lock(operationData)

4. PoolManager calls hook.beforeAddLiquidity()

5. Hook verifies compliance (same process as swap)

6. If verification passes:
   - Liquidity is added
   - Transaction completes

7. If verification fails:
   - Hook reverts
   - Liquidity addition is blocked
```

**Success/Error Handling**: Same as swap

---

### Step 2.6: Optional - EigenLayer Verification

**Who**: End User  
**What**: Submit proof for additional verification by EigenLayer AVS

**User Actions**:
1. Navigate to EigenLayer Status card
2. Click **"Submit Verification Request"**
3. Wait for verification (simulated)

**What Happens**:
- Proof is submitted to EigenLayer AVS
- Multiple operators verify the proof off-chain
- Verification result is recorded on-chain
- Status updates to show verification state

**Status States**:
- ⏳ **Pending**: Verification in progress
- ✅ **Verified**: Proof verified by EigenLayer operators
- ❌ **Unverified**: Verification failed or not submitted

---

## 🔄 Proof Reuse Mechanism

**Important**: Once a user submits a valid proof, they can reuse it for multiple transactions without generating a new proof each time.

**How It Works**:
1. First transaction: User submits proof → Hook verifies and stores `userComplianceHashes[user]`
2. Subsequent transactions: Hook checks if `userComplianceHashes[user]` matches expected hash
3. If match: Transaction proceeds without re-verifying the ZK proof
4. If no match: User must submit a new proof

**Benefits**:
- ✅ Lower gas costs (no proof verification on every transaction)
- ✅ Better user experience (no need to generate proof for each swap)
- ✅ Still maintains security (proof must be valid initially)

---

## 📊 UI Pages & Navigation

### Dashboard (`/`)
- **Compliance Status**: Shows current compliance state
- **Proof Generator**: Generate and submit proofs
- **Pool Interaction**: Swap and add liquidity
- **EigenLayer Status**: EigenLayer verification status
- **Fhenix Integration**: FHE integration placeholder

### Insights (`/insights`)
- **Statistics**: Total proofs, successful verifications, compliance score
- **Activity Timeline**: Recent proof submissions, swaps, LP actions

### Resources (`/resources`)
- **Documentation Links**: Quick Start, Architecture, Frontend Setup
- **Knowledge Hub**: All project documentation

---

## 🚨 Error Scenarios & Recovery

### Scenario 1: User Not Marked as Compliant

**Error**: `UserNotCompliant()`

**Recovery**:
1. Admin must run: `forge script script/InteractWithContracts.s.sol --rpc-url http://localhost:8545 --broadcast`
2. This marks the user as compliant in `BrevisVerifier`
3. User can then generate and submit proof

### Scenario 2: Proof Already Used

**Error**: `ProofAlreadyUsed()`

**Recovery**:
1. User generates a new proof (proof hash includes timestamp + nonce, so it's unique)
2. User submits the new proof
3. Transaction proceeds

### Scenario 3: Proof Expired

**Error**: `ProofExpired()`

**Recovery**:
1. User generates a new proof with current timestamp
2. User submits the new proof
3. Transaction proceeds

### Scenario 4: Router Not Configured

**Error**: "Router address not set"

**Recovery**:
1. Deploy router: `forge script script/DeployRouter.s.sol --rpc-url http://localhost:8545 --broadcast`
2. Copy router address from deployment logs
3. Paste router address in frontend configuration section
4. Save (address is stored in localStorage)

---

## 🎓 Key Takeaways

1. **Two-Step Process**:
   - Admin marks user as compliant (one-time setup)
   - User generates and submits proof (can be reused)

2. **Privacy Preserved**:
   - No PII is stored on-chain
   - Only proof hashes and compliance data hashes are stored
   - ZK proofs verify compliance without revealing data

3. **Efficient Design**:
   - Proofs can be reused for multiple transactions
   - Only first transaction requires full proof verification
   - Subsequent transactions check stored compliance hash

4. **User-Friendly**:
   - Clear error messages with actionable help
   - Visual status indicators
   - Step-by-step guidance in UI

---

## 🔗 Related Documentation

- [Quick Start Guide](../QUICK_START.md)
- [User Guide](./USER_GUIDE.md)
- [Project Explanation](./PROJECT_EXPLANATION.md)
- [Architecture Overview](./ARCHITECTURE.md)
- [Error Messages Guide](./ERROR_MESSAGES.md)

