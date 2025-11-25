# Enhanced Architecture: ZK Proof-of-Compliance with Real Integrations

## System Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         User Interface                          │
│                    (React Frontend + Web3)                      │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                    ZKProofOfComplianceFull                      │
│                    (Uniswap v4 Hook)                            │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │         Multi-Step Verification Workflow                  │  │
│  │  ┌──────────┐  ┌──────────────┐  ┌──────────────┐      │  │
│  │  │  Brevis  │→ │ EigenLayer   │→ │   Fhenix     │      │  │
│  │  │   ZK     │  │     AVS      │  │     FHE     │      │  │
│  │  └──────────┘  └──────────────┘  └──────────────┘      │  │
│  └──────────────────────────────────────────────────────────┘  │
└───────────────────────────┬─────────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
        ▼                   ▼                   ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│   Brevis     │  │  EigenLayer  │  │    Fhenix    │
│  Verifier    │  │     AVS      │  │     FHE      │
│              │  │              │  │              │
│  - Groth16   │  │  - Operators  │  │  - FHE       │
│  - Circuit   │  │  - Consensus  │  │  - Privacy   │
│  - Proof     │  │  - Retry      │  │  - Compute    │
└──────────────┘  └──────────────┘  └──────────────┘
```

## Component Details

### 1. ZKProofOfComplianceFull Hook

**Location**: `src/hooks/ZKProofOfComplianceFull.sol`

**Responsibilities**:
- Enforce compliance on Uniswap v4 swaps and liquidity operations
- Coordinate multi-step verification workflows
- Handle fallback mechanisms
- Track verification states

**Key Functions**:
- `beforeSwap()`: Verify compliance before swap
- `beforeAddLiquidity()`: Verify compliance before LP
- `_executeVerificationWorkflow()`: Execute verification based on mode
- `submitProof()`: Submit proof for verification

### 2. RealBrevisVerifier

**Location**: `src/verifiers/RealBrevisVerifier.sol`

**Responsibilities**:
- Verify zk-SNARK proofs on-chain
- Store user compliance hashes
- Manage compliance status

**Integration**:
- Uses Groth16 verifier contract
- Verifies proofs from Circom circuits
- Checks proof expiration and validity

### 3. RealEigenLayerAVS

**Location**: `src/services/RealEigenLayerAVS.sol`

**Responsibilities**:
- Manage off-chain verification requests
- Track operator consensus
- Handle retries and timeouts
- Process verification results

**State Machine**:
```
Pending → Processing → Verified
              ↓
           Failed/Timeout → Retrying → Processing → Verified
```

**Key Features**:
- Minimum operator confirmations
- Automatic retry with delays
- Timeout detection
- Event-based result notification

### 4. RealFhenixFHE

**Location**: `src/services/RealFhenixFHE.sol`

**Responsibilities**:
- Encrypt compliance data using FHE
- Request FHE computations
- Verify FHE computation results
- Manage encryption keys

**Workflow**:
1. Encrypt compliance data
2. Request FHE computation
3. Receive computation result
4. Verify result on-chain

## Verification Workflows

### Workflow 1: Brevis Only

```
User → Generate ZK Proof → Submit to Hook
                              ↓
                    Hook → Brevis Verifier
                              ↓
                    Verify Proof → Allow/Block
```

### Workflow 2: EigenLayer Only

```
User → Submit Proof → Hook → EigenLayer AVS
                              ↓
                    Submit to Operators
                              ↓
                    Operators Verify (Off-chain)
                              ↓
                    Submit Results → Hook
                              ↓
                    Check Consensus → Allow/Block
```

### Workflow 3: Hybrid (Brevis + EigenLayer)

```
User → Submit Proof → Hook
                        ↓
              Try Brevis First
                        ↓
              [Success] → Allow
              [Failure] → Try EigenLayer
                        ↓
              [Success] → Allow
              [Failure] → Block
```

### Workflow 4: Hybrid All (Brevis + EigenLayer + Fhenix)

```
User → Submit Proof → Hook
                        ↓
              Try Brevis → [Success] → Allow
                        ↓ [Failure]
              Try EigenLayer → [Success] → Allow
                        ↓ [Failure]
              Try Fhenix → [Success] → Allow
                        ↓ [Failure]
              Block
```

## Data Flow

### Proof Generation Flow

```
1. User provides compliance data (KYC, age, location, sanctions)
   ↓
2. Optionally encrypt with Fhenix FHE
   ↓
3. Generate ZK proof using Circom circuit
   ↓
4. Format proof for on-chain submission
   ↓
5. Submit proof to hook contract
```

### Verification Flow

```
1. Hook receives proof
   ↓
2. Check if user already verified (proof reuse)
   ↓
3. Start verification workflow
   ↓
4. Execute verification based on mode:
   - Brevis: Verify ZK proof on-chain
   - EigenLayer: Submit to AVS, wait for operators
   - Fhenix: Request FHE computation
   ↓
5. If primary fails and fallback enabled, try fallback
   ↓
6. Record result and allow/block transaction
```

## Security Architecture

### Trust Model

1. **ZK Proofs**: Trusted setup ceremony, circuit correctness
2. **EigenLayer**: Trust in operator stake and reputation
3. **Fhenix**: Trust in FHE implementation and key management

### Attack Vectors & Mitigations

1. **Proof Replay**: Prevented by proof hash tracking
2. **Invalid Proofs**: Prevented by on-chain verification
3. **Operator Collusion**: Mitigated by requiring multiple operators
4. **FHE Key Leakage**: Prevented by secure key management

## Integration Points

### Frontend → Backend

- **ZK Proof Generation**: `zkProofService.ts` → SnarkJS → Circuit
- **EigenLayer**: `eigenLayerService.ts` → EigenLayer AVS Contract
- **Fhenix**: `fhenixService.ts` → Fhenix FHE Contract

### Backend → On-Chain

- **Hook**: Receives proofs, coordinates verification
- **Brevis**: Verifies ZK proofs on-chain
- **EigenLayer**: Processes operator consensus
- **Fhenix**: Verifies FHE computation results

## Performance Considerations

1. **ZK Proof Generation**: ~2-5 seconds (off-chain)
2. **On-Chain Verification**: ~100-200k gas
3. **EigenLayer Verification**: ~5-10 minutes (async)
4. **Fhenix Computation**: ~10-30 seconds (off-chain)

## Scalability

1. **Proof Reuse**: Users can reuse proofs for multiple transactions
2. **Async Verification**: EigenLayer and Fhenix are async, don't block transactions
3. **Batch Operations**: Support batch proof submission (future)

## Future Enhancements

1. **Batch Verification**: Verify multiple proofs in one transaction
2. **Proof Aggregation**: Aggregate multiple proofs into one
3. **Optimistic Verification**: Allow transactions with pending verification
4. **Cross-Chain**: Support verification across multiple chains

