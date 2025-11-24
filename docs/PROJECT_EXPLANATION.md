# Project Explanation: ZK Proof-of-Compliance Hook

## 🎯 What Problem Does This Solve?

Traditional DeFi platforms face a challenge: **regulatory compliance vs. user privacy**. 

- **Regulators** want to ensure users meet requirements (KYC, age verification, sanctions checks)
- **Users** want privacy and don't want to expose personal information on-chain
- **Platforms** need to enforce rules without becoming a data custodian

**This project solves this** by using **Zero-Knowledge Proofs (ZKPs)** to verify compliance without revealing personal data.

## 🔐 How Zero-Knowledge Proofs Work

### Traditional Approach (Privacy Leaking)
```
User: "I'm 25 years old and passed KYC"
Platform: "Okay, I'll store this on-chain"
Result: Everyone can see your age and KYC status ❌
```

### ZK Proof Approach (Privacy Preserving)
```
User: "I have a proof that I'm over 18 and passed KYC"
Platform: "The proof is valid, but I can't see your actual age"
Result: Compliance verified, privacy maintained ✅
```

### Real-World Analogy

Think of it like a **bouncer at a club**:
- **Traditional**: Show your ID, bouncer sees your exact age and address
- **ZK Proof**: Show a proof that says "I'm over 21" without revealing your actual age or address

## 🏗️ System Architecture

### Core Components

#### 1. **ZKProofOfCompliance Hook** (Main Contract)
- **Purpose**: Enforces compliance rules on Uniswap v4 pools
- **Location**: `src/hooks/ZKProofOfCompliance.sol`
- **Key Functions**:
  - `beforeSwap()`: Checks proof before allowing swap
  - `beforeAddLiquidity()`: Checks proof before allowing LP
  - `submitProof()`: Allows users to submit proofs separately

#### 2. **BrevisVerifier** (ZK Proof Verifier)
- **Purpose**: Verifies that ZK proofs are valid
- **Location**: `src/verifiers/BrevisVerifier.sol`
- **Key Functions**:
  - `verifyProof()`: Validates a ZK proof
  - `getUserComplianceHash()`: Gets user's compliance data hash
  - `isUserCompliant()`: Checks if user is compliant

#### 3. **EigenLayerAVS** (Decentralized Verifier)
- **Purpose**: Provides additional verification through multiple operators
- **Location**: `src/services/EigenLayerAVS.sol`
- **Key Features**:
  - Multiple validators verify proofs
  - Decentralized and trustless
  - Fallback mechanism

#### 4. **Frontend** (User Interface)
- **Purpose**: User-friendly interface for interacting with the system
- **Location**: `frontend/`
- **Tech Stack**: React + TypeScript + Vite + Ethers.js

## 🔄 How It Works: Step by Step

### Step 1: User Registration (Off-Chain)
```
1. User provides compliance data (KYC, age, location) to a trusted service
2. Service verifies the data
3. Service generates a ZK proof that proves compliance without revealing data
4. User receives the proof
```

### Step 2: Proof Submission (On-Chain)
```
1. User connects wallet to frontend
2. Frontend generates/submits proof to hook contract
3. Hook contract calls BrevisVerifier.verifyProof()
4. Verifier checks:
   - Proof is valid
   - User is marked as compliant
   - Proof hasn't expired
   - Proof hasn't been used before
5. If valid, proof is recorded in hook
```

### Step 3: Pool Interaction (On-Chain)
```
1. User tries to swap tokens on Uniswap
2. Uniswap calls hook.beforeSwap()
3. Hook checks:
   - User has submitted a valid proof
   - Proof is still valid
   - User meets all compliance requirements
4. If checks pass, swap proceeds
5. If checks fail, swap is blocked
```

## 🎨 Frontend Components Explained

### WalletConnection
- **What it does**: Connects user's MetaMask wallet
- **Why it's needed**: To sign transactions and interact with contracts
- **User sees**: "Connect Wallet" button, wallet address when connected

### ComplianceStatus
- **What it does**: Shows if user is marked as compliant
- **Why it's needed**: Users need to know their compliance status
- **User sees**: Green checkmark if compliant, red X if not

### ProofGenerator
- **What it does**: Generates and submits ZK proofs
- **Why it's needed**: Users must submit proofs before trading
- **User sees**: "Generate Proof" and "Submit Proof" buttons

### PoolInteraction
- **What it does**: Simulates swap and LP operations
- **Why it's needed**: To test if proofs work correctly
- **User sees**: Swap/LP interface with transaction status

## 🔒 Security Features

### 1. **Replay Protection**
- Each proof can only be used once
- Prevents proof reuse attacks
- Implemented via `usedProofs` mapping

### 2. **Proof Expiration**
- Proofs expire after 30 days (configurable)
- Forces periodic re-verification
- Prevents stale proofs

### 3. **Multiple Verification Layers**
- Brevis ZK verification (primary)
- EigenLayer AVS verification (secondary)
- Fallback mechanisms

### 4. **Admin Controls**
- Only admin can set compliance status
- Hook can be enabled/disabled
- Requirements can be updated

## 📊 Data Flow Diagram

```
┌─────────────┐
│   User      │
└──────┬──────┘
       │
       │ 1. Connect Wallet
       ▼
┌─────────────┐
│  Frontend   │
└──────┬──────┘
       │
       │ 2. Generate Proof
       ▼
┌─────────────┐      ┌──────────────┐
│  Proof      │─────▶│  Brevis      │
│  Generator  │      │  (Off-chain) │
└──────┬──────┘      └──────────────┘
       │
       │ 3. Submit Proof
       ▼
┌─────────────┐      ┌──────────────┐
│  Hook       │─────▶│  Brevis       │
│  Contract   │      │  Verifier     │
└──────┬──────┘      └──────────────┘
       │
       │ 4. Verify & Record
       ▼
┌─────────────┐
│  Proof      │
│  Stored     │
└──────┬──────┘
       │
       │ 5. User Swaps
       ▼
┌─────────────┐      ┌──────────────┐
│  Uniswap    │─────▶│  Hook        │
│  Pool       │      │  (Check)     │
└─────────────┘      └──────────────┘
```

## 🎓 Key Concepts Explained

### Zero-Knowledge Proofs
- **What**: Cryptographic proof that you know something without revealing it
- **Example**: Proving you're over 18 without revealing your exact age
- **Benefit**: Privacy + Compliance

### Uniswap v4 Hooks
- **What**: Custom code that runs at specific points in pool lifecycle
- **When**: Before/after swaps, before/after liquidity operations
- **Benefit**: Custom rules and logic

### Brevis Network
- **What**: Infrastructure for generating and verifying ZK proofs
- **How**: Provides circuits and verification contracts
- **Benefit**: Trustless proof verification

### EigenLayer AVS
- **What**: Decentralized verification service
- **How**: Multiple operators independently verify
- **Benefit**: Additional security and redundancy

## 🚀 Use Cases

### 1. **Regulated Token Pools**
- Only KYC'd users can trade
- Privacy-preserving compliance
- Regulatory compliance without data exposure

### 2. **Age-Restricted Pools**
- Only users over 18/21 can participate
- Age verified without revealing exact age
- Protects minors from risky DeFi

### 3. **Geographic Restrictions**
- Only users from allowed countries
- Location verified without revealing address
- Compliance with local regulations

### 4. **Sanctions Compliance**
- Block users on sanctions lists
- Verify without exposing identity
- Legal compliance

## 🔮 Future Enhancements

### Planned Features
1. **Real Brevis Integration**: Replace mock with actual Brevis contracts
2. **Fhenix FHE**: Add fully homomorphic encryption layer
3. **Multiple Proof Types**: Support different compliance requirements
4. **Proof Aggregation**: Combine multiple proofs into one
5. **Gas Optimization**: Reduce verification costs

### Production Considerations
1. **Audit**: Security audit before mainnet
2. **Upgradeability**: Consider proxy pattern for updates
3. **Monitoring**: Add event monitoring and alerts
4. **Documentation**: Complete API documentation
5. **Testing**: Comprehensive test coverage

## 📚 Technical Deep Dive

### Smart Contract Structure

```
ZKProofOfCompliance
├── State Variables
│   ├── brevisVerifier (IBrevisVerifier)
│   ├── userComplianceHashes (mapping)
│   ├── usedProofs (mapping)
│   └── requirements (ComplianceRequirements)
│
├── Hook Functions
│   ├── beforeSwap()
│   ├── afterSwap()
│   ├── beforeAddLiquidity()
│   └── afterAddLiquidity()
│
└── Admin Functions
    ├── setEnabled()
    ├── setRequirements()
    └── transferAdmin()
```

### Proof Structure

```solidity
struct ComplianceProof {
    bytes32 proofHash;        // Unique proof identifier
    bytes publicInputs;       // Public data (data hash)
    uint256 timestamp;        // When proof was created
    address user;            // User address
}
```

### Verification Flow

1. **Extract proof** from hook data
2. **Check user matches** proof.user
3. **Get expected hash** from verifier
4. **Verify proof** with Brevis verifier
5. **Check replay protection** (proof not used)
6. **Record proof** if valid

## 🎯 Summary

This project creates a **privacy-preserving compliance system** for DeFi:

- ✅ **Users** can prove compliance without exposing data
- ✅ **Platforms** can enforce rules without storing PII
- ✅ **Regulators** get compliance without privacy violations
- ✅ **Developers** get a modular, extensible system

**The result**: DeFi that's both compliant and privacy-preserving! 🎉

