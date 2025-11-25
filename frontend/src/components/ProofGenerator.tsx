import { useState } from 'react'
import { ethers } from 'ethers'
import { Key, Loader } from 'lucide-react'
import './ProofGenerator.css'
import { getErrorMessage, getErrorHelp } from '../utils/errorDecoder'

interface ProofGeneratorProps {
  account: string
  signer: ethers.JsonRpcSigner | null
  hookAddress: string
  onProofSubmitted: () => void
}

function ProofGenerator({ account, signer, hookAddress, onProofSubmitted }: ProofGeneratorProps) {
  const [isGenerating, setIsGenerating] = useState(false)
  const [proofHash, setProofHash] = useState<string | null>(null)
  const [error, setError] = useState<string | null>(null)

  // Mock proof generation (in production, this would call a backend service)
  const generateProof = async () => {
    if (!signer) {
      setError('Wallet not connected')
      return
    }

    setIsGenerating(true)
    setError(null)

    try {
      // Simulate proof generation
      await new Promise(resolve => setTimeout(resolve, 2000))

      // Create a mock proof
      // First, get the expected compliance hash from the verifier
      const verifierABI = [
        'function getUserComplianceHash(address user) external view returns (bytes32)'
      ]
      const verifierAddress = '0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512' // RealBrevisVerifier
      const verifierContract = new ethers.Contract(verifierAddress, verifierABI, signer)
      const expectedDataHash = await verifierContract.getUserComplianceHash(account)
      
      if (expectedDataHash === ethers.ZeroHash) {
        setError('You are not marked as compliant. Please contact an administrator to set your compliance status.')
        setIsGenerating(false)
        return
      }

      const timestamp = Math.floor(Date.now() / 1000)
      
      // Create proof hash
      const proofHashValue = ethers.keccak256(
        ethers.concat([
          ethers.toUtf8Bytes(account),
          expectedDataHash,
          ethers.toBeHex(timestamp, 32)
        ])
      )

      // publicInputs must be at least 32 bytes, with first 32 bytes being the compliance hash
      // Format: [complianceHash (32 bytes), ...other data]
      const publicInputs = ethers.concat([
        expectedDataHash, // First 32 bytes must be the compliance hash
        ethers.toBeHex(timestamp, 32) // Additional data (optional)
      ])

      const proof = {
        proofHash: proofHashValue,
        publicInputs: publicInputs,
        timestamp: timestamp,
        user: account
      }

      // Submit proof to hook contract
      // The hook expects IBrevisVerifier.ComplianceProof format
      const hookABI = [
        'function submitProof(tuple(bytes32 proofHash, bytes publicInputs, uint256 timestamp, address user) calldata proof) external'
      ]
      const hookContract = new ethers.Contract(hookAddress, hookABI, signer)

      // Format proof according to IBrevisVerifier.ComplianceProof struct
      const formattedProof = {
        proofHash: proof.proofHash,
        publicInputs: proof.publicInputs,
        timestamp: proof.timestamp,
        user: proof.user
      }

      const tx = await hookContract.submitProof(formattedProof)
      await tx.wait()

      setProofHash(proofHashValue)
      onProofSubmitted()
    } catch (err: any) {
      console.error('Error generating proof:', err)
      // Use user-friendly error decoder
      const friendlyError = getErrorMessage(err)
      setError(friendlyError)
    } finally {
      setIsGenerating(false)
    }
  }

  return (
    <div className="proof-generator">
      <h2>Generate Compliance Proof</h2>
      <div className="proof-content">
        <p className="proof-description">
          Generate a zero-knowledge compliance proof to verify your eligibility for trading.
          This proof verifies KYC status, age, location, and sanctions checks without exposing personal information.
        </p>

        {proofHash && (
          <div className="proof-success">
            <p>✓ Proof generated successfully!</p>
            <code className="proof-hash">{proofHash.slice(0, 20)}...{proofHash.slice(-20)}</code>
          </div>
        )}

        {error && (
          <div className="proof-error">
            <p><strong>{error}</strong></p>
            {getErrorHelp({ message: error }).length > 0 && (
              <div className="error-help">
                <p><strong>What to do:</strong></p>
                <ul>
                  {getErrorHelp({ message: error }).map((help, idx) => (
                    <li key={idx}>{help}</li>
                  ))}
                </ul>
              </div>
            )}
          </div>
        )}

        <button
          onClick={generateProof}
          disabled={isGenerating || !signer}
          className="btn btn-primary btn-generate"
        >
          {isGenerating ? (
            <>
              <Loader className="spinner" size={20} />
              Generating Proof...
            </>
          ) : (
            <>
              <Key size={20} />
              Generate Proof
            </>
          )}
        </button>
      </div>
    </div>
  )
}

export default ProofGenerator

