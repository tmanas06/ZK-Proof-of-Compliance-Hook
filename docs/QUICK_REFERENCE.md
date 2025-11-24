# Quick Reference Guide

## Contract Addresses

After deployment, update these in your frontend and tests:

```solidity
// Update in frontend/src/App.tsx
const HOOK_ADDRESS = '0x...'
const VERIFIER_ADDRESS = '0x...'
```

## Key Functions

### ZKProofOfCompliance Hook

```solidity
// Submit a compliance proof
function submitProof(ComplianceProof calldata proof) external

// Check if user is compliant
function isUserCompliant(address user) external view returns (bool)

// Check if proof has been used
function isProofUsed(bytes32 proofHash) external view returns (bool)

// Admin functions
function setEnabled(bool _enabled) external onlyAdmin
function setRequirements(ComplianceRequirements memory _requirements) external onlyAdmin
function transferAdmin(address newAdmin) external onlyAdmin
```

### BrevisVerifier

```solidity
// Verify a proof
function verifyProof(ComplianceProof calldata proof, bytes32 expectedDataHash) 
    external view returns (bool isValid, bytes32 dataHash)

// Check user compliance
function isUserCompliant(address user) external view returns (bool)

// Admin: Set user compliance (for testing)
function setUserCompliance(address user, bool compliant, bytes32 dataHash) external onlyAdmin
```

## Common Commands

```bash
# Build contracts
forge build

# Run tests
forge test

# Run tests with verbose output
forge test -vvv

# Format code
forge fmt

# Deploy
forge script script/Deploy.s.sol:DeployScript --rpc-url $RPC_URL --broadcast

# Frontend
cd frontend && npm run dev
```

## Proof Structure

```solidity
struct ComplianceProof {
    bytes32 proofHash;      // Hash of the ZK proof
    bytes publicInputs;     // Public inputs to the proof
    uint256 timestamp;      // Timestamp when proof was generated
    address user;           // User address this proof is for
}
```

## Compliance Data Structure

```solidity
struct ComplianceData {
    bool kycPassed;         // KYC verification status
    bool ageVerified;       // Age >= 18 verification
    bool locationAllowed;   // Geographic location allowed
    bool notSanctioned;     // Not on sanctions list
    uint256 age;            // User's age
    string countryCode;     // ISO country code
}
```

## Error Codes

- `HookNotEnabled()`: Hook is disabled
- `InvalidProof()`: Proof verification failed
- `ProofExpired()`: Proof has expired (>30 days)
- `ProofAlreadyUsed()`: Proof has already been used
- `UserNotCompliant()`: User is not compliant
- `Unauthorized()`: Caller is not authorized

## Gas Estimates

Typical gas costs:
- `submitProof`: ~50,000 gas
- `beforeSwap`: ~30,000 gas
- `beforeAddLiquidity`: ~30,000 gas
- `verifyProof`: ~20,000 gas (view function)

## Testing Checklist

- [ ] Compliant users can submit proofs
- [ ] Non-compliant users are blocked
- [ ] Proof replay protection works
- [ ] Proof expiration is enforced
- [ ] Admin functions are protected
- [ ] Hook can be enabled/disabled
- [ ] Requirements can be updated
- [ ] Gas limits are reasonable

## Integration Checklist

- [ ] Deploy BrevisVerifier
- [ ] Deploy ZKProofOfCompliance hook
- [ ] Set user compliance in verifier
- [ ] Configure hook requirements
- [ ] Update frontend contract addresses
- [ ] Test proof submission
- [ ] Test swap with proof
- [ ] Test add liquidity with proof
- [ ] Verify non-compliant users are blocked

