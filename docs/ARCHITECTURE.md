# Complete System Architecture

## Overview

The ZK Proof-of-Compliance Hook system is a comprehensive Uniswap v4 integration that enforces regulatory compliance through zero-knowledge proofs, decentralized verification, and privacy-preserving computation.

## System Components

### 1. Smart Contracts

#### ZKProofOfCompliance (Basic)
- **Purpose**: Basic hook with Brevis ZK proof verification
- **Features**:
  - `beforeSwap` and `beforeAddLiquidity` hooks
  - Brevis proof verification
  - Replay protection
  - Admin controls

#### ZKProofOfComplianceEnhanced (Advanced)
- **Purpose**: Enhanced hook with EigenLayer AVS and fallback handling
- **Features**:
  - Multiple verification modes (Brevis, EigenLayer, Hybrid)
  - Fallback mechanisms
  - Async EigenLayer verification
  - Comprehensive error handling

#### BrevisVerifier
- **Purpose**: On-chain ZK proof verification
- **Features**:
  - Proof verification
  - User compliance tracking
  - Proof expiration (30 days)
  - Replay protection

#### EigenLayerAVS
- **Purpose**: Decentralized off-chain verification service
- **Features**:
  - Async verification requests
  - Multiple operator support
  - Verification result tracking
  - Timeout handling

#### FhenixFHE (Placeholder)
- **Purpose**: Privacy-preserving computation
- **Features**:
  - Encrypted data processing
  - FHE computation interface
  - Integration ready for production

### 2. Verification Modes

#### BrevisOnly
- Uses only on-chain Brevis verification
- Fastest verification
- Requires gas for on-chain computation

#### EigenLayerOnly
- Uses only EigenLayer AVS
- Decentralized verification
- Async processing required

#### Hybrid
- Tries EigenLayer first
- Falls back to Brevis if EigenLayer fails
- Best of both worlds

#### HybridReverse
- Tries Brevis first
- Falls back to EigenLayer if Brevis fails
- Optimized for speed

### 3. Compliance Data Flow

```
User Data
    │
    ├─→ [Optional] Fhenix FHE Encryption
    │
    ├─→ Brevis Circuit (ZK Proof Generation)
    │
    ├─→ On-chain Verification (BrevisVerifier)
    │
    └─→ Off-chain Verification (EigenLayer AVS)
         │
         └─→ Multiple Operators Verify
              │
              └─→ Result Returned to Hook
```

### 4. Proof Generation Pipeline

1. **Data Collection**: User provides compliance data
2. **FHE Encryption** (Optional): Encrypt using Fhenix
3. **Circuit Execution**: Generate ZK proof using Brevis circuit
4. **Proof Submission**: Submit to hook contract
5. **Verification**: Hook verifies using selected mode
6. **Authorization**: If valid, transaction proceeds

### 5. Error Handling & Fallbacks

#### Primary Verification Fails
- **Brevis Fails**: Try EigenLayer (if hybrid mode)
- **EigenLayer Fails**: Try Brevis (if hybrid mode)
- **Both Fail**: Revert with clear error

#### Async Verification
- **Pending State**: Transaction blocked until verification complete
- **Timeout**: Verification expires after 5 minutes
- **Retry**: User can resubmit verification request

### 6. Frontend Architecture

```
App.tsx
├── WalletConnection
├── ComplianceStatus
├── ProofGenerator
├── PoolInteraction
├── EigenLayerStatus (New)
└── FhenixIntegration (New)
```

### 7. Testing Strategy

#### Unit Tests
- Individual contract functionality
- Edge cases
- Error conditions

#### Integration Tests
- Full verification flows
- Mode switching
- Fallback mechanisms

#### Security Tests
- Access control
- Replay attacks
- Gas limits
- Malicious inputs

## Deployment Architecture

### Production Deployment

1. **Deploy BrevisVerifier**
   ```bash
   forge script script/DeployBrevisVerifier.s.sol --broadcast
   ```

2. **Deploy EigenLayerAVS**
   ```bash
   forge script script/DeployEigenLayerAVS.s.sol --broadcast
   ```

3. **Deploy Hook**
   ```bash
   forge script script/DeployHook.s.sol --broadcast
   ```

4. **Configure Hook**
   ```solidity
   hook.setVerificationMode(VerificationMode.Hybrid);
   hook.setRequirements(requirements);
   ```

### Integration Points

- **Uniswap v4 PoolManager**: Hook must be registered with pool
- **Brevis Network**: Circuit deployment and proof generation
- **EigenLayer**: Operator registration and AVS configuration
- **Fhenix** (Future): FHE service integration

## Security Architecture

### Access Control
- Admin-only functions protected
- Pool manager verification
- User-specific proof binding

### Data Privacy
- ZK proofs reveal no PII
- FHE encryption (when integrated)
- On-chain data hashed only

### Verification Security
- Multiple verification methods
- Decentralized operators
- Replay protection
- Expiration checks

## Performance Considerations

### Gas Optimization
- Efficient storage patterns
- Minimal external calls
- Batch operations where possible

### Verification Speed
- Brevis: ~30k gas, instant
- EigenLayer: Async, variable time
- Hybrid: Fastest available method

### Scalability
- Stateless verification
- Off-chain computation
- Efficient proof verification

## Future Enhancements

1. **Fhenix Integration**: Full FHE support
2. **More Circuits**: Additional compliance rules
3. **Multi-chain**: Cross-chain verification
4. **Governance**: DAO-based requirement updates
5. **Analytics**: Compliance metrics dashboard

## Monitoring & Maintenance

### Key Metrics
- Verification success rate
- Average verification time
- Gas costs
- Error rates

### Maintenance Tasks
- Operator management (EigenLayer)
- Circuit updates (Brevis)
- Requirement adjustments
- Security audits

