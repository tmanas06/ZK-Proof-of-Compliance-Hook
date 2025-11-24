import { useState, useEffect } from 'react'
import { ethers } from 'ethers'
import { Shield, Clock, CheckCircle, XCircle } from 'lucide-react'
import './EigenLayerStatus.css'

interface EigenLayerStatusProps {
  account: string
  signer: ethers.JsonRpcSigner | null
  avsAddress: string
  hookAddress: string
}

function EigenLayerStatus({ account, signer, avsAddress, hookAddress }: EigenLayerStatusProps) {
  const [isPending, setIsPending] = useState<boolean | null>(null)
  const [isValid, setIsValid] = useState<boolean | null>(null)
  const [requestId, setRequestId] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)

  const AVS_ABI = [
    'function isVerificationPending(bytes32 requestId) external view returns (bool)',
    'function getLatestVerification(address user) external view returns (tuple(bytes32 requestId, bool isValid, bytes32 dataHash, uint256 timestamp, address operator, string reason))',
    'event VerificationResultAvailable(bytes32 indexed requestId, address indexed user, bool isValid, bytes32 dataHash, address operator)'
  ]

  const HOOK_ABI = [
    'function checkEigenLayerStatus(address user) external view returns (bool isPending, bool isValid)',
    'function submitEigenLayerVerification(tuple(bytes32 proofHash, bytes publicInputs, uint256 timestamp, address user) calldata proof) external returns (bytes32)'
  ]

  useEffect(() => {
    if (account && signer) {
      checkStatus()
    }
  }, [account, signer])

  const checkStatus = async () => {
    if (!signer || !account) return

    try {
      const hook = new ethers.Contract(hookAddress, HOOK_ABI, signer)
      const [pending, valid] = await hook.checkEigenLayerStatus(account)
      setIsPending(pending)
      setIsValid(valid)
    } catch (error) {
      console.error('Error checking EigenLayer status:', error)
    }
  }

  const submitVerification = async () => {
    if (!signer || !account) return

    setLoading(true)
    try {
      // Create mock proof
      const timestamp = Math.floor(Date.now() / 1000)
      const proofHash = ethers.keccak256(ethers.toUtf8Bytes(`${account}-${timestamp}`))
      
      const proof = {
        proofHash: proofHash,
        publicInputs: ethers.AbiCoder.defaultAbiCoder().encode(['bytes32'], [proofHash]),
        timestamp: timestamp,
        user: account
      }

      const hook = new ethers.Contract(hookAddress, HOOK_ABI, signer)
      const tx = await hook.submitEigenLayerVerification(proof)
      const receipt = await tx.wait()

      // Extract request ID from events
      const event = receipt.logs.find((log: any) => 
        log.topics[0] === ethers.id('VerificationRequestSubmitted(address,bytes32,bytes32,uint256)')
      )
      
      if (event) {
        const decoded = ethers.AbiCoder.defaultAbiCoder().decode(
          ['bytes32'],
          event.data
        )
        setRequestId(decoded[0])
      }

      await checkStatus()
    } catch (error: any) {
      console.error('Error submitting verification:', error)
      alert(`Error: ${error.message}`)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="eigenlayer-status">
      <h2>EigenLayer AVS Verification</h2>
      
      <div className="status-card">
        {isPending === null ? (
          <div className="status-loading">
            <Shield size={24} />
            <span>Checking verification status...</span>
          </div>
        ) : isPending ? (
          <div className="status-pending">
            <Clock className="icon-pending" size={32} />
            <div className="status-info">
              <h3>Verification Pending</h3>
              <p>Your verification request is being processed by EigenLayer operators</p>
              {requestId && (
                <div className="request-id">
                  <span>Request ID:</span>
                  <code>{requestId.slice(0, 20)}...</code>
                </div>
              )}
            </div>
          </div>
        ) : isValid ? (
          <div className="status-verified">
            <CheckCircle className="icon-verified" size={32} />
            <div className="status-info">
              <h3>Verified by EigenLayer</h3>
              <p>Your compliance proof has been verified by EigenLayer AVS operators</p>
            </div>
          </div>
        ) : (
          <div className="status-unverified">
            <XCircle className="icon-unverified" size={32} />
            <div className="status-info">
              <h3>Not Verified</h3>
              <p>Submit a verification request to EigenLayer AVS</p>
            </div>
          </div>
        )}
      </div>

      <div className="actions">
        <button
          onClick={submitVerification}
          disabled={loading || isPending}
          className="btn btn-primary"
        >
          {loading ? 'Submitting...' : 'Submit Verification Request'}
        </button>
        <button
          onClick={checkStatus}
          disabled={loading}
          className="btn btn-secondary"
        >
          Refresh Status
        </button>
      </div>

      <div className="info-note">
        <p>
          <strong>EigenLayer AVS:</strong> Decentralized verification service that uses
          multiple operators to verify compliance proofs off-chain. This provides
          additional security and redundancy beyond on-chain verification.
        </p>
      </div>
    </div>
  )
}

export default EigenLayerStatus

