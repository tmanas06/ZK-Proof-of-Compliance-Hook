/**
 * Real ZK Proof Generation Service
 * Integrates with SnarkJS and Circom circuits for actual zk-SNARK proof generation
 */

import { ethers } from 'ethers'
import * as snarkjs from 'snarkjs'

export interface ZKProofInputs {
  // Private inputs (witnesses)
  kycStatus: number
  age: number
  countryCode: [number, number]
  sanctionsStatus: number
  userSecret: string
  // Public inputs
  requireKYC: boolean
  requireAgeVerification: boolean
  requireLocationCheck: boolean
  requireSanctionsCheck: boolean
  minAge: number
  allowedCountryCode: [number, number]
  complianceHash: string
}

export interface ZKProofResult {
  proof: {
    pi_a: [string, string]
    pi_b: [[string, string], [string, string]]
    pi_c: [string, string]
  }
  publicSignals: string[]
  verified: boolean
}

/**
 * Generate a real zk-SNARK proof using SnarkJS
 * @param inputs ZK proof inputs
 * @returns Proof result with Groth16 proof and public signals
 */
export async function generateZKProof(inputs: ZKProofInputs): Promise<ZKProofResult> {
  try {
    // Load circuit files (these should be generated from Circom compilation)
    const wasmPath = '/circuits/compliance_js/compliance.wasm'
    const zkeyPath = '/circuits/compliance_0001.zkey'

    // Prepare input for SnarkJS
    const circuitInput = {
      kycStatus: inputs.kycStatus,
      age: inputs.age,
      countryCode: inputs.countryCode,
      sanctionsStatus: inputs.sanctionsStatus,
      userSecret: inputs.userSecret,
      requireKYC: inputs.requireKYC ? 1 : 0,
      requireAgeVerification: inputs.requireAgeVerification ? 1 : 0,
      requireLocationCheck: inputs.requireLocationCheck ? 1 : 0,
      requireSanctionsCheck: inputs.requireSanctionsCheck ? 1 : 0,
      minAge: inputs.minAge,
      allowedCountryCode: inputs.allowedCountryCode,
      complianceHash: inputs.complianceHash,
    }

    // Generate proof using SnarkJS
    const { proof, publicSignals } = await snarkjs.groth16.fullProve(
      circuitInput,
      wasmPath,
      zkeyPath
    )

    // Verify proof locally
    const vkey = await fetch('/circuits/verification_key.json').then((r) => r.json())
    const verified = await snarkjs.groth16.verify(vkey, publicSignals, proof)

    if (!verified) {
      throw new Error('Generated proof failed local verification')
    }

    return {
      proof: {
        pi_a: proof.pi_a,
        pi_b: proof.pi_b,
        pi_c: proof.pi_c,
      },
      publicSignals,
      verified,
    }
  } catch (error: any) {
    console.error('Error generating ZK proof:', error)
    throw new Error(`Failed to generate ZK proof: ${error.message}`)
  }
}

/**
 * Format proof for on-chain submission
 * @param proofResult Proof result from generateZKProof
 * @param userAddress User's wallet address
 * @returns Formatted proof for Solidity contract
 */
export function formatProofForChain(
  proofResult: ZKProofResult,
  userAddress: string
): {
  proofHash: string
  publicInputs: string
  timestamp: number
  user: string
} {
  // Create proof hash
  const proofData = JSON.stringify(proofResult.proof)
  const proofHash = ethers.keccak256(ethers.toUtf8Bytes(proofData))

  // Encode public inputs (proof + public signals)
  const publicInputs = ethers.AbiCoder.defaultAbiCoder().encode(
    ['uint256[2]', 'uint256[2][2]', 'uint256[2]', 'uint256[]'],
    [
      proofResult.proof.pi_a,
      proofResult.proof.pi_b,
      proofResult.proof.pi_c,
      proofResult.publicSignals.map((s) => BigInt(s)),
    ]
  )

  return {
    proofHash,
    publicInputs,
    timestamp: Math.floor(Date.now() / 1000),
    user: userAddress,
  }
}

/**
 * Generate test proof with default values
 * @param userAddress User's wallet address
 * @returns Formatted proof ready for on-chain submission
 */
export async function generateTestProof(userAddress: string) {
  const inputs: ZKProofInputs = {
    kycStatus: 1, // KYC passed
    age: 25,
    countryCode: [0x55, 0x53], // "US"
    sanctionsStatus: 0, // Not sanctioned
    userSecret: ethers.keccak256(ethers.toUtf8Bytes(`${userAddress}-${Date.now()}`)),
    requireKYC: true,
    requireAgeVerification: true,
    requireLocationCheck: true,
    requireSanctionsCheck: true,
    minAge: 18,
    allowedCountryCode: [0x55, 0x53], // "US"
    complianceHash: ethers.ZeroHash, // Will be computed
  }

  // Compute compliance hash (simplified - in production use Poseidon)
  const hashInput = `${inputs.kycStatus}-${inputs.age}-${inputs.countryCode.join('')}-${inputs.sanctionsStatus}-${inputs.userSecret}`
  inputs.complianceHash = ethers.keccak256(ethers.toUtf8Bytes(hashInput))

  const proofResult = await generateZKProof(inputs)
  return formatProofForChain(proofResult, userAddress)
}

