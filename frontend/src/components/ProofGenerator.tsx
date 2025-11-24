import { useState } from 'react'
import { ethers } from 'ethers'
import { Key, Loader } from 'lucide-react'
import './ProofGenerator.css'

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
      const timestamp = Math.floor(Date.now() / 1000)
      const dataHash = ethers.keccak256(ethers.toUtf8Bytes(`${account}-${timestamp}`))
      const proofHashValue = ethers.keccak256(
        ethers.concat([
          ethers.toUtf8Bytes(account),
          dataHash,
          ethers.toBeHex(timestamp, 32)
        ])
      )

      const proof = {
        proofHash: proofHashValue,
        publicInputs: ethers.AbiCoder.defaultAbiCoder().encode(['bytes32'], [dataHash]),
        timestamp: timestamp,
        user: account
      }

      // Submit proof to hook contract
      const hookABI = [
        'function submitProof(tuple(bytes32 proofHash, bytes publicInputs, uint256 timestamp, address user) calldata proof) external'
      ]
      const hookContract = new ethers.Contract(hookAddress, hookABI, signer)

      const tx = await hookContract.submitProof(proof)
      await tx.wait()

      setProofHash(proofHashValue)
      onProofSubmitted()
    } catch (err: any) {
      console.error('Error generating proof:', err)
      setError(err.message || 'Failed to generate proof')
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
            <p>Error: {error}</p>
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

