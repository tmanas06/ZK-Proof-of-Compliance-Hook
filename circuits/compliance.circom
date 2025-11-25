pragma circom 2.1.0;

// Compliance verification circuit using zk-SNARKs
// This circuit proves compliance without revealing personal data

include "../node_modules/circomlib/circuits/comparators.circom";
include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/gates.circom";

template ComplianceCircuit() {
    // Private inputs (witnesses) - these are NOT revealed
    signal input kycStatus;        // 1 if KYC passed, 0 otherwise
    signal input age;              // User's age
    signal input countryCode[2];   // ISO country code (2 bytes)
    signal input sanctionsStatus;  // 0 if not sanctioned, 1 if sanctioned
    signal input userSecret;        // Secret salt for privacy

    // Public inputs - these ARE revealed
    signal input requireKYC;              // Whether KYC is required
    signal input requireAgeVerification;    // Whether age verification is required
    signal input requireLocationCheck;     // Whether location check is required
    signal input requireSanctionsCheck;    // Whether sanctions check is required
    signal input minAge;                   // Minimum age requirement
    signal input allowedCountryCode[2];    // Allowed country code
    signal input complianceHash;           // Expected compliance data hash

    // Outputs
    signal output isValid;                 // 1 if all checks pass, 0 otherwise
    signal output computedHash;            // Computed compliance data hash

    // KYC Check
    component kycGate = IsEqual();
    kycGate.in[0] <== kycStatus;
    kycGate.in[1] <== 1; // 1 means KYC passed
    signal kycCheckValue;
    kycCheckValue <== requireKYC * (1 - kycGate.out); // 0 if compliant

    // Age Check
    component ageGate = GreaterThan(32);
    ageGate.in[0] <== age;
    ageGate.in[1] <== minAge;
    signal ageCheckValue;
    ageCheckValue <== requireAgeVerification * (1 - ageGate.out); // 0 if compliant

    // Location Check
    component locationGate0 = IsEqual();
    locationGate0.in[0] <== countryCode[0];
    locationGate0.in[1] <== allowedCountryCode[0];
    component locationGate1 = IsEqual();
    locationGate1.in[0] <== countryCode[1];
    locationGate1.in[1] <== allowedCountryCode[1];
    signal locationMatch;
    locationMatch <== locationGate0.out * locationGate1.out; // Both must match
    signal locationCheckValue;
    locationCheckValue <== requireLocationCheck * (1 - locationMatch); // 0 if compliant

    // Sanctions Check
    component sanctionsGate = IsEqual();
    sanctionsGate.in[0] <== sanctionsStatus;
    sanctionsGate.in[1] <== 0; // 0 means not sanctioned
    signal sanctionsCheckValue;
    sanctionsCheckValue <== requireSanctionsCheck * (1 - sanctionsGate.out); // 0 if compliant

    // Compute compliance hash using Poseidon
    component hash = Poseidon(5);
    hash.inputs[0] <== kycStatus;
    hash.inputs[1] <== age;
    hash.inputs[2] <== countryCode[0] * 256 + countryCode[1];
    hash.inputs[3] <== sanctionsStatus;
    hash.inputs[4] <== userSecret;
    computedHash <== hash.out;

    // Verify all checks pass
    component allChecks = IsZero();
    allChecks.in <== kycCheckValue + ageCheckValue + locationCheckValue + sanctionsCheckValue;

    // Verify hash matches
    component hashCheck = IsEqual();
    hashCheck.in[0] <== computedHash;
    hashCheck.in[1] <== complianceHash;

    // Final constraint: all checks must pass AND hash must match
    isValid <== allChecks.out * hashCheck.out;
}

component main = ComplianceCircuit();

