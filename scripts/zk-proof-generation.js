/**
 * Real ZK Proof Generation Script
 * Uses SnarkJS to generate zk-SNARK proofs from Circom circuits
 */

const snarkjs = require("snarkjs");
const fs = require("fs");
const path = require("path");

/**
 * Generate a ZK proof for compliance verification
 * @param {Object} privateInputs - Private witness data (not revealed)
 * @param {Object} publicInputs - Public inputs (revealed)
 * @returns {Promise<Object>} Proof object with proof, publicSignals, and circuit info
 */
async function generateComplianceProof(privateInputs, publicInputs) {
  const circuitPath = path.join(__dirname, "../circuits/compliance_js/compliance.wasm");
  const zkeyPath = path.join(__dirname, "../circuits/compliance_0001.zkey");
  const vkeyPath = path.join(__dirname, "../circuits/verification_key.json");

  // Prepare inputs
  const input = {
    // Private inputs
    kycStatus: privateInputs.kycStatus,
    age: privateInputs.age,
    countryCode: privateInputs.countryCode,
    sanctionsStatus: privateInputs.sanctionsStatus,
    userSecret: privateInputs.userSecret,
    // Public inputs
    requireKYC: publicInputs.requireKYC ? 1 : 0,
    requireAgeVerification: publicInputs.requireAgeVerification ? 1 : 0,
    requireLocationCheck: publicInputs.requireLocationCheck ? 1 : 0,
    requireSanctionsCheck: publicInputs.requireSanctionsCheck ? 1 : 0,
    minAge: publicInputs.minAge,
    allowedCountryCode: publicInputs.allowedCountryCode,
    complianceHash: publicInputs.complianceHash,
  };

  // Generate proof
  const { proof, publicSignals } = await snarkjs.groth16.fullProve(
    input,
    circuitPath,
    zkeyPath
  );

  // Verify proof locally
  const vkey = JSON.parse(fs.readFileSync(vkeyPath, "utf8"));
  const verified = await snarkjs.groth16.verify(vkey, publicSignals, proof);

  if (!verified) {
    throw new Error("Generated proof failed local verification");
  }

  return {
    proof,
    publicSignals,
    verified,
  };
}

/**
 * Format proof for on-chain submission
 * @param {Object} proofData - Proof data from generateComplianceProof
 * @returns {Object} Formatted proof for Solidity contract
 */
function formatProofForChain(proofData) {
  const { proof, publicSignals } = proofData;

  return {
    a: [proof.pi_a[0], proof.pi_a[1]],
    b: [
      [proof.pi_b[0][1], proof.pi_b[0][0]],
      [proof.pi_b[1][1], proof.pi_b[1][0]],
    ],
    c: [proof.pi_c[0], proof.pi_c[1]],
    publicSignals: publicSignals,
  };
}

/**
 * Generate compliance proof with default test data
 * @returns {Promise<Object>} Formatted proof ready for on-chain submission
 */
async function generateTestProof() {
  const privateInputs = {
    kycStatus: 1, // KYC passed
    age: 25,
    countryCode: [0x55, 0x53], // "US"
    sanctionsStatus: 0, // Not sanctioned
    userSecret: "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
  };

  const publicInputs = {
    requireKYC: true,
    requireAgeVerification: true,
    requireLocationCheck: true,
    requireSanctionsCheck: true,
    minAge: 18,
    allowedCountryCode: [0x55, 0x53], // "US"
    complianceHash: "0x0000000000000000000000000000000000000000000000000000000000000000", // Will be computed
  };

  // Compute compliance hash (simplified - in production use Poseidon)
  const crypto = require("crypto");
  const hashInput = `${privateInputs.kycStatus}-${privateInputs.age}-${privateInputs.countryCode.join("")}-${privateInputs.sanctionsStatus}-${privateInputs.userSecret}`;
  publicInputs.complianceHash = "0x" + crypto.createHash("sha256").update(hashInput).digest("hex");

  const proofData = await generateComplianceProof(privateInputs, publicInputs);
  return formatProofForChain(proofData);
}

module.exports = {
  generateComplianceProof,
  formatProofForChain,
  generateTestProof,
};

// CLI usage
if (require.main === module) {
  generateTestProof()
    .then((proof) => {
      console.log("Proof generated successfully!");
      console.log(JSON.stringify(proof, null, 2));
    })
    .catch((error) => {
      console.error("Error generating proof:", error);
      process.exit(1);
    });
}

