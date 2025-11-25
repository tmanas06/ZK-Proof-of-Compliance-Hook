/**
 * EigenLayer AVS Service
 * Handles interaction with EigenLayer AVS for decentralized proof verification
 */

import { ethers } from 'ethers'

export interface EigenLayerVerificationRequest {
  requestId: string
  user: string
  proofHash: string
  timestamp: number
  state: 'Pending' | 'Processing' | 'Verified' | 'Failed' | 'Timeout' | 'Retrying'
  retryCount: number
  operatorVoteCount: number
}

export interface EigenLayerVerificationResult {
  requestId: string
  isValid: boolean
  dataHash: string
  timestamp: number
  operator: string
  reason: string
}

/**
 * EigenLayer AVS Service Class
 */
export class EigenLayerService {
  private contract: ethers.Contract
  private provider: ethers.BrowserProvider

  constructor(contractAddress: string, provider: ethers.BrowserProvider) {
    this.provider = provider

    const ABI = [
      'function submitVerificationRequest(address user, bytes32 proofHash, bytes calldata complianceData) external returns (bytes32)',
      'function getVerificationResult(bytes32 requestId) external view returns (tuple(bytes32 requestId, bool isValid, bytes32 dataHash, uint256 timestamp, address operator, string reason))',
      'function isVerificationPending(bytes32 requestId) external view returns (bool)',
      'function getLatestVerification(address user) external view returns (tuple(bytes32 requestId, bool isValid, bytes32 dataHash, uint256 timestamp, address operator, string reason))',
      'function getVerificationState(bytes32 requestId) external view returns (uint8 state, uint256 retryCount, uint256 operatorVoteCount)',
      'function retryVerification(bytes32 requestId) external',
      'function checkTimeout(bytes32 requestId) external',
      'event VerificationRequestSubmitted(bytes32 indexed requestId, address indexed user, bytes32 proofHash, uint256 timestamp)',
      'event VerificationResultAvailable(bytes32 indexed requestId, address indexed user, bool isValid, bytes32 dataHash, address operator)',
      'event VerificationStateChanged(bytes32 indexed requestId, uint8 oldState, uint8 newState)',
    ]

    this.contract = new ethers.Contract(contractAddress, ABI, provider)
  }

  /**
   * Submit verification request to EigenLayer AVS
   */
  async submitVerificationRequest(
    signer: ethers.JsonRpcSigner,
    userAddress: string,
    proofHash: string,
    complianceData: string = '0x'
  ): Promise<string> {
    const contractWithSigner = this.contract.connect(signer)
    const tx = await contractWithSigner.submitVerificationRequest(userAddress, proofHash, complianceData)
    const receipt = await tx.wait()

    // Extract request ID from event
    const event = receipt.logs.find(
      (log: any) => log.topics[0] === ethers.id('VerificationRequestSubmitted(bytes32,address,bytes32,uint256)')
    )

    if (event) {
      const decoded = ethers.AbiCoder.defaultAbiCoder().decode(['bytes32', 'address', 'bytes32', 'uint256'], event.data)
      return decoded[0]
    }

    throw new Error('Failed to extract request ID from transaction')
  }

  /**
   * Get verification result
   */
  async getVerificationResult(requestId: string): Promise<EigenLayerVerificationResult | null> {
    try {
      const result = await this.contract.getVerificationResult(requestId)
      
      if (result.requestId === ethers.ZeroHash) {
        return null
      }

      return {
        requestId: result.requestId,
        isValid: result.isValid,
        dataHash: result.dataHash,
        timestamp: Number(result.timestamp),
        operator: result.operator,
        reason: result.reason,
      }
    } catch (error) {
      console.error('Error getting verification result:', error)
      return null
    }
  }

  /**
   * Get verification state
   */
  async getVerificationState(requestId: string): Promise<EigenLayerVerificationRequest | null> {
    try {
      const [state, retryCount, operatorVoteCount] = await this.contract.getVerificationState(requestId)
      const isPending = await this.contract.isVerificationPending(requestId)

      const stateNames = ['Pending', 'Processing', 'Verified', 'Failed', 'Timeout', 'Retrying']
      const stateName = stateNames[Number(state)] || 'Unknown'

      return {
        requestId,
        user: '', // Would need to fetch separately
        proofHash: ethers.ZeroHash, // Would need to fetch separately
        timestamp: Date.now(),
        state: stateName as any,
        retryCount: Number(retryCount),
        operatorVoteCount: Number(operatorVoteCount),
      }
    } catch (error) {
      console.error('Error getting verification state:', error)
      return null
    }
  }

  /**
   * Get latest verification for a user
   */
  async getLatestVerification(userAddress: string): Promise<EigenLayerVerificationResult | null> {
    try {
      const result = await this.contract.getLatestVerification(userAddress)
      
      if (result.requestId === ethers.ZeroHash) {
        return null
      }

      return {
        requestId: result.requestId,
        isValid: result.isValid,
        dataHash: result.dataHash,
        timestamp: Number(result.timestamp),
        operator: result.operator,
        reason: result.reason,
      }
    } catch (error) {
      console.error('Error getting latest verification:', error)
      return null
    }
  }

  /**
   * Retry verification
   */
  async retryVerification(signer: ethers.JsonRpcSigner, requestId: string): Promise<void> {
    const contractWithSigner = this.contract.connect(signer)
    const tx = await contractWithSigner.retryVerification(requestId)
    await tx.wait()
  }

  /**
   * Check timeout
   */
  async checkTimeout(signer: ethers.JsonRpcSigner, requestId: string): Promise<void> {
    const contractWithSigner = this.contract.connect(signer)
    const tx = await contractWithSigner.checkTimeout(requestId)
    await tx.wait()
  }

  /**
   * Subscribe to verification events
   */
  onVerificationResult(
    callback: (requestId: string, user: string, isValid: boolean, dataHash: string, operator: string) => void
  ) {
    this.contract.on('VerificationResultAvailable', (requestId, user, isValid, dataHash, operator) => {
      callback(requestId, user, isValid, dataHash, operator)
    })
  }

  /**
   * Unsubscribe from events
   */
  removeAllListeners() {
    this.contract.removeAllListeners()
  }
}

