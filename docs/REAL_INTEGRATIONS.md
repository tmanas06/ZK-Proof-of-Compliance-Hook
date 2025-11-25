# Real Integrations Guide: Brevis, EigenLayer AVS, and Fhenix FHE

This document provides comprehensive instructions for integrating real ZK proof generation, EigenLayer AVS, and Fhenix FHE into the ZK Proof-of-Compliance Hook system.

## Table of Contents

1. [Real ZK Proof Integration (Brevis/Circom)](#real-zk-proof-integration)
2. [EigenLayer AVS Integration](#eigenlayer-avs-integration)
3. [Fhenix FHE Integration](#fhenix-fhe-integration)
4. [Multi-Step Verification Workflows](#multi-step-verification-workflows)
5. [Frontend Integration](#frontend-integration)
6. [Security Considerations](#security-considerations)

---

## Real ZK Proof Integration

### Overview

The system uses **Circom** circuits and **SnarkJS** for generating zk-SNARK proofs. The compliance circuit verifies KYC status, age, location, and sanctions checks without revealing personal data.

### Setup

#### 1. Install Dependencies

```bash
# Install Circom compiler
npm install -g circom

# Install SnarkJS
npm install snarkjs

# Install Circomlib (Circom standard library)
npm install circomlib
```

#### 2. Compile Circuit

```bash
# Compile the compliance circuit
circom circuits/compliance.circom --r1cs --wasm --sym

# Generate proving key
snarkjs powersoftau new bn128 14 pot14_0000.ptau -v
snarkjs powersoftau contribute pot14_0000.ptau pot14_0001.ptau --name="First contribution" -v
snarkjs powersoftau prepare phase2 pot14_0001.ptau pot14_final.ptau -v
snarkjs groth16 setup compliance.r1cs pot14_final.ptau compliance_0000.zkey
snarkjs zkey contribute compliance_0000.zkey compliance_0001.zkey --name="Second contribution" -v
snarkjs zkey export verificationkey compliance_0001.zkey verification_key.json
```

#### 3. Generate Proof (JavaScript)

```javascript
const { generateComplianceProof, formatProofForChain } = require('./scripts/zk-proof-generation');

const privateInputs = {
  kycStatus: 1,
  age: 25,
  countryCode: [0x55, 0x53], // "US"
  sanctionsStatus: 0,
  userSecret: "0x..."
};

const publicInputs = {
  requireKYC: true,
  requireAgeVerification: true,
  requireLocationCheck: true,
  requireSanctionsCheck: true,
  minAge: 18,
  allowedCountryCode: [0x55, 0x53],
  complianceHash: "0x..."
};

const proofData = await generateComplianceProof(privateInputs, publicInputs);
const formattedProof = formatProofForChain(proofData);
```

#### 4. On-Chain Verification

The `RealBrevisVerifier` contract verifies Groth16 proofs on-chain. In production, you would:

1. Deploy a Groth16 verifier contract (generated from the circuit)
2. Update `RealBrevisVerifier` to call the verifier contract
3. Verify public signals match expected values

### Integration Points

- **Circuit**: `circuits/compliance.circom`
- **Proof Generation**: `scripts/zk-proof-generation.js`
- **On-Chain Verifier**: `src/verifiers/RealBrevisVerifier.sol`
- **Frontend Service**: `frontend/src/services/zkProofService.ts`

---

## EigenLayer AVS Integration

### Overview

EigenLayer AVS provides decentralized off-chain verification through multiple operators. The system includes:

- **State Machine**: Tracks verification states (Pending, Processing, Verified, Failed, Timeout, Retrying)
- **Operator Consensus**: Requires minimum number of operator confirmations
- **Retry Mechanism**: Automatic retry with configurable delays
- **Timeout Handling**: Automatic timeout detection and handling

### Setup

#### 1. Deploy EigenLayer AVS Contract

```solidity
address[] memory operators = [operator1, operator2, operator3];
uint256 minConfirmations = 2;
uint256 timeout = 5 minutes;
uint256 maxRetries = 3;
uint256 retryDelay = 1 minutes;

RealEigenLayerAVS avs = new RealEigenLayerAVS(
    operators,
    minConfirmations,
    timeout,
    maxRetries,
    retryDelay
);
```

#### 2. Submit Verification Request

```solidity
bytes32 requestId = avs.submitVerificationRequest(
    userAddress,
    proofHash,
    complianceData
);
```

#### 3. Operators Submit Results

```solidity
// Each operator calls this
avs.submitOperatorResult(
    requestId,
    isValid,
    dataHash,
    reason
);
```

#### 4. Check Results

```solidity
VerificationResult memory result = avs.getVerificationResult(requestId);
bool isValid = result.isValid;
```

### State Machine

```
Pending → Processing → Verified
              ↓
           Failed/Timeout → Retrying → Processing → Verified
```

### Integration Points

- **Contract**: `src/services/RealEigenLayerAVS.sol`
- **Frontend Service**: `frontend/src/services/eigenLayerService.ts`
- **Hook Integration**: `src/hooks/ZKProofOfComplianceFull.sol`

---

## Fhenix FHE Integration

### Overview

Fhenix FHE enables privacy-preserving computation on encrypted compliance data. The system:

1. **Encrypts** compliance data using FHE
2. **Processes** encrypted data off-chain
3. **Verifies** computation results on-chain

### Setup

#### 1. Deploy Fhenix FHE Contract

```solidity
address fhenixService = 0x...; // Fhenix service address
RealFhenixFHE fhe = new RealFhenixFHE(fhenixService);
```

#### 2. Encrypt Compliance Data

```solidity
(EncryptedComplianceData memory encrypted, bytes32 requestId) = fhe.encryptComplianceData(
    kycPassed,
    age,
    countryCode,
    notSanctioned
);
```

#### 3. Request FHE Computation

```solidity
bytes32 computationRequestId = fhe.requestFHEComputation(
    encrypted,
    requireKYC,
    minAge,
    allowedCountries
);
```

#### 4. Submit Computation Result (Fhenix Service)

```solidity
FHEComputationResult memory result = FHEComputationResult({
    requestId: computationRequestId,
    isValid: true,
    resultHash: keccak256(...),
    proof: fheProof,
    timestamp: block.timestamp
});

fhe.submitFHEComputationResult(computationRequestId, result);
```

### Integration Points

- **Contract**: `src/services/RealFhenixFHE.sol`
- **Frontend Service**: `frontend/src/services/fhenixService.ts`
- **Hook Integration**: `src/hooks/ZKProofOfComplianceFull.sol`

---

## Multi-Step Verification Workflows

### Verification Modes

The `ZKProofOfComplianceFull` hook supports multiple verification modes:

1. **BrevisOnly**: Only ZK proof verification
2. **EigenLayerOnly**: Only EigenLayer AVS verification
3. **FhenixOnly**: Only Fhenix FHE verification
4. **HybridBrevisEigen**: Brevis primary, EigenLayer fallback
5. **HybridEigenBrevis**: EigenLayer primary, Brevis fallback
6. **HybridAll**: All three methods with fallback chain

### Workflow Execution

```solidity
// Start workflow
bytes32 workflowId = _startVerificationWorkflow(user, proof, expectedHash);

// Execute based on mode
bool success = _executeVerificationWorkflow(workflowId, proof, expectedHash);

// Check status
(WorkflowState state, bool isComplete) = hook.getWorkflowStatus(workflowId);
```

### Fallback Mechanism

When fallback is enabled:

1. Primary method is tried first
2. If primary fails, fallback method is attempted
3. If all methods fail, verification fails

---

## Frontend Integration

### Real ZK Proof Generation

Update `ProofGenerator.tsx` to use real ZK proof generation:

```typescript
import { generateTestProof } from '../services/zkProofService'

const generateProof = async () => {
  const proof = await generateTestProof(account)
  // Submit to hook
}
```

### EigenLayer Status

Update `EigenLayerStatus.tsx` to use real service:

```typescript
import { EigenLayerService } from '../services/eigenLayerService'

const eigenLayerService = new EigenLayerService(avsAddress, provider)
const result = await eigenLayerService.getLatestVerification(account)
```

### Fhenix Integration

Update `FhenixIntegration.tsx` to use real service:

```typescript
import { FhenixService } from '../services/fhenixService'

const fhenixService = new FhenixService(fhenixAddress, provider)
const { encryptedData } = await fhenixService.encryptComplianceData(
  signer, kycPassed, age, countryCode, notSanctioned
)
```

---

## Security Considerations

### ZK Proof Security

1. **Trusted Setup**: Use secure multi-party computation for trusted setup
2. **Circuit Verification**: Audit circuit logic for correctness
3. **Proof Verification**: Verify proofs on-chain using trusted verifier contracts
4. **Replay Protection**: Prevent proof reuse through proof hash tracking

### EigenLayer AVS Security

1. **Operator Selection**: Use reputable operators with stake
2. **Consensus Threshold**: Require sufficient operator confirmations
3. **Timeout Handling**: Implement proper timeout mechanisms
4. **Retry Limits**: Prevent infinite retry loops

### Fhenix FHE Security

1. **Key Management**: Securely manage FHE public/private keys
2. **Proof Verification**: Verify FHE computation proofs
3. **Data Privacy**: Ensure encrypted data is never decrypted
4. **Service Authentication**: Authenticate Fhenix service calls

### General Security

1. **Access Control**: Use proper admin/operator modifiers
2. **Input Validation**: Validate all inputs
3. **Error Handling**: Handle errors gracefully
4. **Event Logging**: Log important events for auditing

---

## Deployment Checklist

- [ ] Compile Circom circuit and generate proving keys
- [ ] Deploy Groth16 verifier contract
- [ ] Deploy RealBrevisVerifier with verifier address
- [ ] Deploy RealEigenLayerAVS with operator addresses
- [ ] Deploy RealFhenixFHE with Fhenix service address
- [ ] Deploy ZKProofOfComplianceFull hook
- [ ] Configure verification mode and fallback settings
- [ ] Update frontend with contract addresses
- [ ] Test end-to-end verification workflows
- [ ] Audit security considerations

---

## Additional Resources

- [Circom Documentation](https://docs.circom.io/)
- [SnarkJS Documentation](https://github.com/iden3/snarkjs)
- [EigenLayer Documentation](https://docs.eigenlayer.xyz/)
- [Fhenix Documentation](https://docs.fhenix.io/)

