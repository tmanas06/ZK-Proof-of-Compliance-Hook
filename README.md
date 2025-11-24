# ZK Proof-of-Compliance Hook for Uniswap v4

A production-ready Uniswap v4 hook system that restricts swaps and liquidity provision to users who can produce valid zero-knowledge compliance proofs. The system integrates **Brevis Network** for ZK proof verification, **EigenLayer AVS** for decentralized off-chain verification, and **Fhenix FHE** (placeholder) for privacy-preserving computation.

## 🎯 Features

### Core Functionality
- **Zero-Knowledge Compliance Verification**: Uses Brevis Network to verify compliance data without exposing PII
- **EigenLayer AVS Integration**: Decentralized off-chain verification with multiple operators
- **Hybrid Verification Modes**: Support for Brevis-only, EigenLayer-only, or hybrid verification with fallback
- **Fhenix FHE Placeholder**: Architecture ready for fully homomorphic encryption integration
- **Uniswap v4 Hook Integration**: Seamlessly integrates with Uniswap v4's hook system
- **Modular Design**: Easily configurable compliance requirements (KYC, age, location, sanctions)
- **Replay Protection**: Prevents proof reuse through proof hash tracking
- **Fallback Handling**: Graceful error handling and fallback mechanisms

### Architecture Components
1. **ZKProofOfCompliance**: Basic hook with Brevis verification
2. **ZKProofOfComplianceEnhanced**: Enhanced hook with EigenLayer AVS and fallback handling
3. **EigenLayerAVS**: Mock service for decentralized verification
4. **FhenixFHE**: Placeholder for fully homomorphic encryption
5. **BrevisVerifier**: ZK proof verification system

## 📋 Requirements

- **Solidity**: ^0.8.24
- **Foundry**: Latest version
- **Node.js**: >= 18.0.0
- **npm** or **yarn**

## 🚀 Quick Start

### 1. Clone and Install Dependencies

```bash
# Install Foundry (if not already installed)
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Install project dependencies
npm install

# Install frontend dependencies
cd frontend
npm install
cd ..
```

### 2. Compile Contracts

```bash
forge build
```

### 3. Run Tests

```bash
# Run all tests
forge test

# Run with verbose output
forge test -vvv

# Run with gas reporting
forge test --gas-report
```

### 4. Set Up Environment Variables

```bash
# Copy the example .env file
cp .env.example .env

# Edit .env with your values
# See docs/ENV_SETUP.md for detailed instructions
```

**Required variables:**
- `PRIVATE_KEY`: Your deployment account private key
- `POOL_MANAGER_ADDRESS`: Uniswap v4 PoolManager address
- `LOCAL_RPC_URL`: Local node URL (default: http://localhost:8545)

**Optional variables:**
- `MAINNET_RPC_URL`: For mainnet deployment
- `SEPOLIA_RPC_URL`: For testnet deployment
- `ETHERSCAN_API_KEY`: For contract verification

See [docs/ENV_SETUP.md](docs/ENV_SETUP.md) for complete setup guide.

### 5. Test Environment Setup

```bash
# Verify your .env file is configured correctly
forge script script/TestEnv.s.sol
```

### 6. Deploy Contracts

```bash
# Deploy to local network
forge script script/Deploy.s.sol:DeployScript --rpc-url http://localhost:8545 --broadcast

# Deploy to testnet (Sepolia)
forge script script/Deploy.s.sol:DeployScript --rpc-url $SEPOLIA_RPC_URL --broadcast --verify

# Deploy to mainnet (use with caution!)
forge script script/Deploy.s.sol:DeployScript --rpc-url $MAINNET_RPC_URL --broadcast --verify
```

### 7. Run Frontend

```bash
cd frontend
npm run dev
```

The frontend will be available at `http://localhost:3000`

## 🏗️ Architecture

### System Overview

bash ```
┌─────────────────────────────────────────────────────────────┐
│                    Uniswap v4 Pool Manager                   │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│           ZKProofOfComplianceEnhanced Hook                   │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Verification Modes:                                  │  │
│  │  • BrevisOnly                                         │  │
│  │  • EigenLayerOnly                                    │  │
│  │  • Hybrid (EigenLayer → Brevis fallback)             │  │
│  │  • HybridReverse (Brevis → EigenLayer fallback)      │  │
│  └──────────────────────────────────────────────────────┘  │
└──────┬──────────────────────┬───────────────────────────────┘
       │                      │
       ▼                      ▼
┌──────────────┐    ┌──────────────────────┐
│   Brevis     │    │   EigenLayer AVS     │
│  Verifier    │    │   (Off-chain)        │
│              │    │                      │
│  On-chain    │    │  Multiple Operators  │
│  ZK Proof    │    │  Decentralized       │
│  Verification│    │  Verification        │
└──────────────┘    └──────────────────────┘
       │                      │
       └──────────┬───────────┘
                  ▼
         ┌─────────────────┐
         │  Fhenix FHE     │
         │  (Placeholder)  │
         │                 │
         │  Privacy-       │
         │  Preserving     │
         │  Computation    │
         └─────────────────┘
```

### Contract Structure

```
src/
├── hooks/
│   ├── ZKProofOfCompliance.sol          # Basic hook
│   └── ZKProofOfComplianceEnhanced.sol   # Enhanced hook with EigenLayer
├── verifiers/
│   └── BrevisVerifier.sol                # Brevis ZK verifier
├── services/
│   ├── EigenLayerAVS.sol                 # EigenLayer AVS service
│   └── FhenixFHE.sol                     # Fhenix FHE placeholder
├── interfaces/
│   ├── IPoolManager.sol                  # Uniswap v4 interfaces
│   ├── IBrevisVerifier.sol               # Brevis interface
│   └── IEigenLayerAVS.sol                # EigenLayer interface
└── libraries/
    ├── BalanceDelta.sol                  # Balance delta type
    └── ComplianceData.sol                # Compliance utilities
```

### Verification Flow

1. **User Submits Proof**
   - User generates ZK proof using Brevis (optionally with Fhenix FHE encryption)
   - Proof includes compliance data hash without revealing actual values

2. **Hook Verification**
   - Hook receives proof in `beforeSwap` or `beforeAddLiquidity`
   - Based on verification mode:
     - **BrevisOnly**: Verifies proof on-chain using BrevisVerifier
     - **EigenLayerOnly**: Submits to EigenLayer AVS for off-chain verification
     - **Hybrid**: Tries EigenLayer first, falls back to Brevis if needed
     - **HybridReverse**: Tries Brevis first, falls back to EigenLayer if needed

3. **EigenLayer AVS Process** (if used)
   - Request submitted to EigenLayer AVS
   - Multiple operators verify proof off-chain
   - Result returned asynchronously
   - Hook checks result before allowing transaction

4. **Fallback Handling**
   - If primary verification fails, fallback method is attempted
   - If all methods fail, transaction is reverted with clear error

## 🔧 Configuration

### Verification Modes

```solidity
enum VerificationMode {
    BrevisOnly,      // Use only Brevis verification
    EigenLayerOnly,  // Use only EigenLayer AVS
    Hybrid,          // Try EigenLayer first, fallback to Brevis
    HybridReverse    // Try Brevis first, fallback to EigenLayer
}
```

### Compliance Requirements

```solidity
struct ComplianceRequirements {
    bool requireKYC;              // Require KYC verification
    bool requireAgeVerification;  // Require age verification
    bool requireLocationCheck;    // Require location check
    bool requireSanctionsCheck;   // Require sanctions check
    uint256 minAge;              // Minimum age requirement
}
```

## 🧪 Testing

The test suite includes:

### Unit Tests
- Compliant users can submit proofs
- Non-compliant users are blocked
- Proof replay protection
- Proof expiration handling

### Integration Tests
- `beforeSwap` with different verification modes
- `beforeAddLiquidity` with EigenLayer verification
- Fallback mechanisms
- Error handling

### EigenLayer AVS Tests
- Verification request submission
- Async result handling
- Operator verification
- Timeout handling

### Security Tests
- Only admin can update settings
- Gas limit checks
- Malicious proof attempts
- Edge cases and corner cases

Run tests:
```bash
forge test
forge test -vvv  # Verbose output
```

## 🌐 Frontend

The React frontend provides:

1. **Wallet Connection**: Connect MetaMask or other Web3 wallets
2. **Compliance Status**: View your compliance status
3. **Proof Generation**: Generate and submit compliance proofs
4. **EigenLayer AVS Status**: Check EigenLayer verification status
5. **Fhenix Integration**: Placeholder for FHE encryption
6. **Pool Interaction**: Swap tokens and add liquidity (demo)

### Frontend Configuration

Update contract addresses in `frontend/src/App.tsx`:

```typescript
const HOOK_ADDRESS = '0x...' // Your deployed hook address
const VERIFIER_ADDRESS = '0x...' // Your deployed verifier address
const EIGENLAYER_AVS_ADDRESS = '0x...' // Your deployed EigenLayer AVS address
```

## 📝 Integration Guides

### Brevis Network Integration

See [docs/BREVIS_CIRCUIT.md](docs/BREVIS_CIRCUIT.md) for:
- Circuit specification
- Proof generation flow
- Integration steps
- Sample Circom code

### EigenLayer AVS Integration

1. **Deploy EigenLayer AVS Contract**
   ```bash
   forge script script/DeployEigenLayerAVS.s.sol --broadcast
   ```

2. **Set Up Operators**
   - Register EigenLayer operators
   - Configure operator addresses in AVS contract

3. **Configure Hook**
   ```solidity
   hook.setVerificationMode(VerificationMode.EigenLayerOnly);
   ```

### Fhenix FHE Integration (Placeholder)

The Fhenix integration is currently a placeholder. To integrate:

1. Deploy Fhenix FHE contract
2. Replace `FhenixFHEPlaceholder` with actual Fhenix contract
3. Update encryption/decryption calls
4. Integrate with proof generation pipeline

## 🔒 Security Considerations

### Implemented Security Features

1. **Replay Protection**: Proofs can only be used once
2. **Proof Expiration**: Proofs expire after 30 days
3. **User Verification**: Proofs must match the transaction sender
4. **Admin Controls**: Only admin can modify hook settings
5. **Input Validation**: All inputs are validated before processing
6. **Fallback Mechanisms**: Graceful handling of verification failures
7. **Access Control**: Hook functions only callable by pool manager

### Security Best Practices

- **Access Control**: Admin functions are protected
- **Reentrancy Protection**: No external calls in state-changing functions
- **Gas Optimization**: Efficient storage and computation
- **Error Handling**: Comprehensive error messages and reverts

### Audit Recommendations

Before deploying to mainnet:

1. **External Audit**: Engage a professional security audit firm
2. **Formal Verification**: Consider formal verification for critical paths
3. **Bug Bounty**: Launch a bug bounty program
4. **Gradual Rollout**: Deploy to testnet first, then gradually to mainnet

## 📚 Documentation

- [README.md](README.md) - This file
- [docs/BREVIS_CIRCUIT.md](docs/BREVIS_CIRCUIT.md) - Brevis circuit documentation
- [SECURITY.md](SECURITY.md) - Security considerations
- [SETUP.md](SETUP.md) - Setup guide
- [QUICK_REFERENCE.md](QUICK_REFERENCE.md) - Quick reference

## 🐛 Troubleshooting

### Common Issues

1. **Tests Failing**: Ensure Foundry is up to date (`foundryup`)
2. **Compilation Errors**: Check Solidity version compatibility
3. **Frontend Not Connecting**: Ensure MetaMask is installed and unlocked
4. **Proof Verification Failing**: Check that user compliance is set in verifier
5. **EigenLayer Pending**: Verification may take time, check status periodically

### Debug Mode

Run tests with verbose output:
```bash
forge test -vvvv
```


## 🙏 Acknowledgments

- Uniswap Labs for Uniswap v4
- Brevis Network for ZK proof infrastructure
- EigenLayer for AVS architecture
- Fhenix for FHE technology
- Foundry team for excellent tooling

 
 
