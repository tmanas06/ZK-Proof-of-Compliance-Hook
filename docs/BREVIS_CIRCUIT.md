# Brevis ZK Compliance Proof Circuit

This document describes the zero-knowledge proof circuit used for compliance verification in the ZKProofOfCompliance hook.

## Overview

The compliance circuit proves that a user meets certain requirements (KYC, age, location, sanctions) without revealing the actual values. The proof is generated off-chain using Brevis Network and verified on-chain.

## Circuit Specification

### Inputs

#### Private Inputs (Witnesses)
- `kycStatus`: Boolean - Whether user passed KYC
- `age`: Integer - User's age
- `countryCode`: String - ISO country code
- `sanctionsStatus`: Boolean - Whether user is on sanctions list
- `userSecret`: Secret value linking proof to user address

#### Public Inputs
- `userAddress`: Ethereum address - User's wallet address
- `complianceHash`: Bytes32 - Hash of compliance data
- `timestamp`: Integer - Proof generation timestamp
- `requirementsHash`: Bytes32 - Hash of compliance requirements

### Circuit Logic

The circuit verifies the following conditions:

1. **KYC Verification**
   ```
   IF requireKYC THEN kycStatus == true
   ```

2. **Age Verification**
   ```
   IF requireAgeVerification THEN age >= minAge
   ```

3. **Location Verification**
   ```
   IF requireLocationCheck THEN countryCode IN allowedCountries
   ```

4. **Sanctions Check**
   ```
   IF requireSanctionsCheck THEN sanctionsStatus == false
   ```

5. **Data Integrity**
   ```
   complianceHash == keccak256(kycStatus, age, countryCode, sanctionsStatus)
   ```

6. **User Binding**
   ```
   userAddress == deriveAddress(userSecret)
   ```

## Sample Circuit Implementation (Circom)

```circom
pragma circom 2.0.0;

include "circomlib/poseidon.circom";
include "circomlib/comparators.circom";

template ComplianceCircuit() {
    // Private inputs
    signal private input kycStatus;
    signal private input age;
    signal private input countryCode[2]; // 2 characters for ISO code
    signal private input sanctionsStatus;
    signal private input userSecret;

    // Public inputs
    signal input userAddress;
    signal input complianceHash;
    signal input timestamp;
    signal input requirementsHash;

    // Requirements (public)
    signal input requireKYC;
    signal input requireAgeVerification;
    signal input requireLocationCheck;
    signal input requireSanctionsCheck;
    signal input minAge;
    signal input allowedCountries[10][2]; // Max 10 allowed countries

    // Intermediate signals
    signal kycCheck;
    signal ageCheck;
    signal locationCheck;
    signal sanctionsCheck;
    signal computedHash;

    // KYC Check
    component kycGate = IsEqual();
    kycGate.in[0] <== kycStatus;
    kycGate.in[1] <== 1; // true
    kycCheck <== requireKYC * (1 - kycGate.out); // 0 if compliant

    // Age Check
    component ageComparator = GreaterThan(32);
    ageComparator.in[0] <== age;
    ageComparator.in[1] <== minAge;
    ageCheck <== requireAgeVerification * (1 - ageComparator.out); // 0 if compliant

    // Location Check (simplified - check if country matches any allowed)
    component locationMatch[10];
    for (var i = 0; i < 10; i++) {
        locationMatch[i] = IsEqual();
        locationMatch[i].in[0] <== countryCode[0];
        locationMatch[i].in[1] <== allowedCountries[i][0];
        // Check second character too...
    }
    // Combine location matches (simplified)
    locationCheck <== requireLocationCheck * (1 - /* combined match result */);

    // Sanctions Check
    component sanctionsGate = IsEqual();
    sanctionsGate.in[0] <== sanctionsStatus;
    sanctionsGate.in[1] <== 0; // false (not sanctioned)
    sanctionsCheck <== requireSanctionsCheck * sanctionsGate.out; // 0 if compliant

    // Compute compliance hash
    component hash = Poseidon(5);
    hash.inputs[0] <== kycStatus;
    hash.inputs[1] <== age;
    hash.inputs[2] <== countryCode[0] * 256 + countryCode[1];
    hash.inputs[3] <== sanctionsStatus;
    hash.inputs[4] <== userSecret;
    computedHash <== hash.out;

    // Verify all checks pass
    component allChecks = IsZero();
    allChecks.in <== kycCheck + ageCheck + locationCheck + sanctionsCheck;

    // Verify hash matches
    component hashCheck = IsEqual();
    hashCheck.in[0] <== computedHash;
    hashCheck.in[1] <== complianceHash;

    // Final constraint: all checks must pass
    allChecks.out === 1;
    hashCheck.out === 1;
}

component main = ComplianceCircuit();
```

## Proof Generation Flow

1. **User Submits Compliance Data**
   - User provides KYC status, age, location, sanctions status
   - Data is encrypted (optionally using Fhenix FHE)

2. **Off-Chain Proof Generation**
   - Use Brevis SDK to generate ZK proof
   - Circuit verifies compliance without revealing data
   - Proof includes public inputs (user address, compliance hash)

3. **On-Chain Verification**
   - Submit proof to BrevisVerifier contract
   - Contract verifies proof validity
   - If valid, user is marked as compliant

## Integration with Brevis Network

### Step 1: Deploy Circuit
```bash
# Using Brevis CLI
brevis circuit deploy ComplianceCircuit.circom
```

### Step 2: Generate Proof
```javascript
// Using Brevis SDK
const brevis = new BrevisSDK();
const proof = await brevis.generateProof({
  circuit: 'ComplianceCircuit',
  privateInputs: {
    kycStatus: true,
    age: 25,
    countryCode: ['U', 'S'],
    sanctionsStatus: false,
    userSecret: secret
  },
  publicInputs: {
    userAddress: userAddress,
    complianceHash: computedHash,
    timestamp: Date.now(),
    requirementsHash: requirementsHash
  }
});
```

### Step 3: Verify On-Chain
```solidity
// Submit proof to contract
IBrevisVerifier.ComplianceProof memory proof = IBrevisVerifier.ComplianceProof({
    proofHash: keccak256(abi.encode(proof)),
    publicInputs: abi.encode(userAddress, complianceHash, timestamp, requirementsHash),
    timestamp: block.timestamp,
    user: userAddress
});

brevisVerifier.verifyProof(proof, expectedComplianceHash);
```

## Security Considerations

1. **Replay Protection**: Proof hashes are tracked to prevent reuse
2. **Expiration**: Proofs expire after 30 days
3. **User Binding**: Proof is cryptographically bound to user address
4. **Data Integrity**: Compliance hash ensures data hasn't been tampered with

## Future Enhancements

- Support for more complex compliance rules
- Multi-party computation for privacy
- Integration with Fhenix FHE for encrypted data processing
- Support for dynamic requirements updates

