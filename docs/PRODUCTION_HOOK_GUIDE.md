# Production Compliance Hook - Complete Guide

## Overview

The `ProductionComplianceHook` is a production-ready Uniswap v4 hook that enforces compliance using **real Groth16 zk-SNARK proofs** generated from the `compliance.circom` circuit. This hook replaces all mock verifiers and provides on-chain proof verification for KYC, age, location, and sanctions checks.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│              ProductionComplianceHook                   │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Groth16 Verifier (snarkjs-generated)            │  │
│  │  - Verifies zk-SNARK proofs on-chain             │  │
│  │  - Validates public signals                      │  │
│  └──────────────────────────────────────────────────┘  │
│                                                          │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Compliance Enforcement                          │  │
│  │  - beforeSwap: Verify compliance before swap     │  │
│  │  - beforeAddLiquidity: Verify before LP          │  │
│  │  - Replay protection (proof hash tracking)       │  │
│  │  - Proof expiration (configurable)               │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

## Key Features

1. **Real Groth16 Verification**: Uses actual snarkjs-generated verifier contract
2. **Replay Protection**: Tracks used proof hashes to prevent reuse
3. **Proof Expiration**: Configurable expiration time (default: 30 days)
4. **Compliance Requirements**: Configurable KYC, age, location, sanctions checks
5. **Gas Efficient**: Optimized for on-chain verification
6. **Production Ready**: Comprehensive tests and error handling

## Step-by-Step Setup

### Step 1: Generate Groth16 Verifier

**Windows:**
```powershell
.\scripts\generate-groth16-verifier.ps1
```

**Linux/Mac:**
```bash
bash scripts/generate-groth16-verifier.sh
```

This will:
- Compile `circuits/compliance.circom`
- Generate powers of tau (trusted setup)
- Create zkey files
- Export `contracts/generated/Groth16Verifier.sol`

### Step 2: Deploy Groth16 Verifier

Deploy the generated `Groth16Verifier.sol` contract:

```solidity
// Using Remix, Hardhat, or Foundry
Groth16Verifier verifier = new Groth16Verifier();
```

Copy the deployed address to your `.env`:
```
GROTH16_VERIFIER_ADDRESS=0x...
```

### Step 3: Deploy Production Compliance Hook

```bash
forge script script/DeployProductionHook.s.sol:DeployProductionHook \
  --rpc-url http://localhost:8545 \
  --broadcast
```

The script will:
- Read `GROTH16_VERIFIER_ADDRESS` from `.env`
- Deploy `ProductionComplianceHook` with configured requirements
- Output deployment addresses

### Step 4: Configure Requirements

Update compliance requirements in the deployment script or via admin function:

```solidity
ProductionComplianceHook.ComplianceRequirements memory requirements = 
    ProductionComplianceHook.ComplianceRequirements({
        requireKYC: true,
        requireAgeVerification: true,
        requireLocationCheck: true,
        requireSanctionsCheck: true,
        minAge: 18,
        allowedCountryCode: bytes2("US")
    });
```

## Proof Generation & Submission

### Generating a Proof (Off-Chain)

Using snarkjs with the compiled circuit:

```javascript
const snarkjs = require("snarkjs");
const fs = require("fs");

// Load circuit artifacts
const wasm = fs.readFileSync("circuits/compliance_js/compliance.wasm");
const zkey = fs.readFileSync("circuits/compliance_0001.zkey");

// Prepare inputs
const inputs = {
    // Private inputs (witnesses)
    kycStatus: 1,              // 1 = KYC passed
    age: 25,                    // User's age
    countryCode: [85, 83],      // "US" as bytes
    sanctionsStatus: 0,         // 0 = not sanctioned
    userSecret: "0x1234...",    // Secret salt
    
    // Public inputs
    requireKYC: 1,
    requireAgeVerification: 1,
    requireLocationCheck: 1,
    requireSanctionsCheck: 1,
    minAge: 18,
    allowedCountryCode: [85, 83],
    complianceHash: "0x..."     // Expected hash
};

// Generate proof
const { proof, publicSignals } = await snarkjs.groth16.fullProve(
    inputs,
    wasm,
    zkey
);

// Format for contract submission
const formattedProof = [
    [proof.pi_a[0], proof.pi_a[1]],
    [[proof.pi_b[0][1], proof.pi_b[0][0]], [proof.pi_b[1][1], proof.pi_b[1][0]]],
    [proof.pi_c[0], proof.pi_c[1]]
];

const formattedPublicSignals = publicSignals.map(x => BigInt(x));
```

### Submitting Proof (On-Chain)

```solidity
// Call submitProof on the hook contract
hook.submitProof(
    formattedProof[0],      // a
    formattedProof[1],      // b
    formattedProof[2],      // c
    formattedPublicSignals  // publicSignals
);
```

## Contract Interface

### Key Functions

#### `submitProof`
Submit a Groth16 zk-SNARK proof for compliance verification.

```solidity
function submitProof(
    uint256[2] memory a,
    uint256[2][2] memory b,
    uint256[2] memory c,
    uint256[] memory publicSignals
) external;
```

**Public Signals Format:**
- `publicSignals[0]`: complianceHash (bytes32 as uint256)
- `publicSignals[1]`: isValid (1 if compliant, 0 otherwise)

#### `checkCompliance`
Check user's compliance status.

```solidity
function checkCompliance(address user) 
    external 
    view 
    returns (
        bool isCompliant,
        bytes32 complianceHash,
        uint256 lastProofTime
    );
```

#### Admin Functions

```solidity
// Enable/disable hook
function setEnabled(bool _enabled) external onlyAdmin;

// Update compliance requirements
function updateRequirements(ComplianceRequirements memory _requirements) external onlyAdmin;

// Update proof expiration
function setProofExpiration(uint256 _proofExpiration) external onlyAdmin;

// Manually set user compliance (emergency only)
function setUserCompliance(address user, bytes32 complianceHash, bool compliant) external onlyAdmin;
```

## Security Features

1. **Replay Protection**: Each proof hash can only be used once
2. **Proof Expiration**: Proofs expire after configured time (default: 30 days)
3. **Access Control**: Admin-only functions for critical operations
4. **Input Validation**: Validates public signals length and format
5. **Gas Optimization**: Efficient storage and verification patterns

## Testing

Run comprehensive tests:

```bash
forge test --match-contract ProductionComplianceHookTest -vv
```

Test coverage includes:
- ✅ Valid proof submission
- ✅ Replay attack prevention
- ✅ Invalid proof rejection
- ✅ Proof expiration handling
- ✅ Admin function access control
- ✅ Compliance status checking

## Integration with Uniswap v4

The hook implements the `IHooks` interface and is called by the PoolManager:

1. **beforeSwap**: Verifies compliance before allowing swap
2. **afterSwap**: No additional checks (swap completed)
3. **beforeAddLiquidity**: Verifies compliance before adding liquidity
4. **afterAddLiquidity**: No additional checks (liquidity added)

## Error Handling

The contract uses custom errors for gas efficiency:

- `HookNotEnabled()`: Hook is disabled
- `InvalidProof()`: Groth16 verification failed
- `ProofExpired()`: Proof has expired
- `ProofAlreadyUsed()`: Proof hash already used (replay attack)
- `UserNotCompliant()`: User doesn't meet compliance requirements
- `InvalidPublicSignals()`: Public signals format is invalid
- `Unauthorized()`: Caller is not authorized

## Deployment Checklist

- [ ] Generate Groth16 verifier from circuit
- [ ] Deploy Groth16Verifier contract
- [ ] Set `GROTH16_VERIFIER_ADDRESS` in `.env`
- [ ] Configure compliance requirements
- [ ] Deploy ProductionComplianceHook
- [ ] Set `PRODUCTION_HOOK_ADDRESS` in `.env`
- [ ] Test proof submission
- [ ] Verify compliance checking
- [ ] Test Uniswap v4 integration

## Next Steps

1. **Backend API**: Create API service for proof generation
2. **Frontend SDK**: Build React components for proof submission
3. **Monitoring**: Set up event monitoring for compliance status
4. **Documentation**: API documentation for dapp integration

## Files

- **Contract**: `src/hooks/ProductionComplianceHook.sol`
- **Deployment**: `script/DeployProductionHook.s.sol`
- **Tests**: `test/ProductionComplianceHook.t.sol`
- **Verifier Generation**: `scripts/generate-groth16-verifier.ps1` / `.sh`

## Support

For issues or questions:
1. Check test files for usage examples
2. Review contract comments for detailed documentation
3. Verify circuit compilation and proof generation

