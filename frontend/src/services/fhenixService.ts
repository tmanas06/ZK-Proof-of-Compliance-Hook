/**
 * Fhenix FHE Service
 * Handles interaction with Fhenix Fully Homomorphic Encryption for privacy-preserving compliance
 */

import { ethers } from 'ethers'

export interface FhenixEncryptedData {
  encryptedKYC: string
  encryptedAge: string
  encryptedLocation: string
  encryptedSanctions: string
  publicKey: string
  dataHash: string
}

export interface FhenixComputationResult {
  requestId: string
  isValid: boolean
  resultHash: string
  proof: string
  timestamp: number
}

/**
 * Fhenix FHE Service Class
 */
export class FhenixService {
  private contract: ethers.Contract
  private provider: ethers.BrowserProvider

  constructor(contractAddress: string, provider: ethers.BrowserProvider) {
    this.provider = provider

    const ABI = [
      'function encryptComplianceData(bool kycPassed, uint256 age, string calldata countryCode, bool notSanctioned) external returns (tuple(bytes encryptedKYC, bytes encryptedAge, bytes encryptedLocation, bytes encryptedSanctions, bytes publicKey, bytes32 dataHash) encryptedData, bytes32 requestId)',
      'function requestFHEComputation(tuple(bytes encryptedKYC, bytes encryptedAge, bytes encryptedLocation, bytes encryptedSanctions, bytes publicKey, bytes32 dataHash) calldata encryptedData, bool requireKYC, uint256 minAge, string[] calldata allowedCountries) external returns (bytes32)',
      'function getFHEComputationResult(bytes32 requestId) external view returns (tuple(bytes32 requestId, bool isValid, bytes32 resultHash, bytes proof, uint256 timestamp) result)',
      'function getPublicKey() external view returns (bytes)',
      'function getLatestEncryption(address user) external view returns (tuple(bytes encryptedKYC, bytes encryptedAge, bytes encryptedLocation, bytes encryptedSanctions, bytes publicKey, bytes32 dataHash))',
      'event EncryptionRequested(bytes32 indexed requestId, address indexed user)',
      'event EncryptionCompleted(bytes32 indexed requestId, address indexed user, bytes32 dataHash)',
      'event ComputationRequested(bytes32 indexed requestId, bytes32 indexed encryptionRequestId)',
      'event ComputationCompleted(bytes32 indexed requestId, bool isValid, bytes32 resultHash)',
    ]

    this.contract = new ethers.Contract(contractAddress, ABI, provider)
  }

  /**
   * Encrypt compliance data using Fhenix FHE
   */
  async encryptComplianceData(
    signer: ethers.JsonRpcSigner,
    kycPassed: boolean,
    age: number,
    countryCode: string,
    notSanctioned: boolean
  ): Promise<{ encryptedData: FhenixEncryptedData; requestId: string }> {
    const contractWithSigner = this.contract.connect(signer)
    const tx = await contractWithSigner.encryptComplianceData(kycPassed, age, countryCode, notSanctioned)
    const receipt = await tx.wait()

    // Extract result from transaction
    const result = await contractWithSigner.encryptComplianceData.staticCall(kycPassed, age, countryCode, notSanctioned)

    return {
      encryptedData: {
        encryptedKYC: result.encryptedData.encryptedKYC,
        encryptedAge: result.encryptedData.encryptedAge,
        encryptedLocation: result.encryptedData.encryptedLocation,
        encryptedSanctions: result.encryptedData.encryptedSanctions,
        publicKey: result.encryptedData.publicKey,
        dataHash: result.encryptedData.dataHash,
      },
      requestId: result.requestId,
    }
  }

  /**
   * Request FHE computation
   */
  async requestFHEComputation(
    signer: ethers.JsonRpcSigner,
    encryptedData: FhenixEncryptedData,
    requireKYC: boolean,
    minAge: number,
    allowedCountries: string[]
  ): Promise<string> {
    const contractWithSigner = this.contract.connect(signer)
    
    const encryptedDataTuple = [
      encryptedData.encryptedKYC,
      encryptedData.encryptedAge,
      encryptedData.encryptedLocation,
      encryptedData.encryptedSanctions,
      encryptedData.publicKey,
      encryptedData.dataHash,
    ]

    const tx = await contractWithSigner.requestFHEComputation(
      encryptedDataTuple,
      requireKYC,
      minAge,
      allowedCountries
    )
    const receipt = await tx.wait()

    // Extract request ID from event
    const event = receipt.logs.find(
      (log: any) => log.topics[0] === ethers.id('ComputationRequested(bytes32,bytes32)')
    )

    if (event) {
      const decoded = ethers.AbiCoder.defaultAbiCoder().decode(['bytes32', 'bytes32'], event.data)
      return decoded[0]
    }

    throw new Error('Failed to extract computation request ID')
  }

  /**
   * Get FHE computation result
   */
  async getFHEComputationResult(requestId: string): Promise<FhenixComputationResult | null> {
    try {
      const result = await this.contract.getFHEComputationResult(requestId)
      
      if (result.requestId === ethers.ZeroHash) {
        return null
      }

      return {
        requestId: result.requestId,
        isValid: result.isValid,
        resultHash: result.resultHash,
        proof: result.proof,
        timestamp: Number(result.timestamp),
      }
    } catch (error) {
      console.error('Error getting FHE computation result:', error)
      return null
    }
  }

  /**
   * Get FHE public key
   */
  async getPublicKey(): Promise<string> {
    return await this.contract.getPublicKey()
  }

  /**
   * Get latest encryption for a user
   */
  async getLatestEncryption(userAddress: string): Promise<FhenixEncryptedData | null> {
    try {
      const result = await this.contract.getLatestEncryption(userAddress)
      
      if (result.dataHash === ethers.ZeroHash) {
        return null
      }

      return {
        encryptedKYC: result.encryptedKYC,
        encryptedAge: result.encryptedAge,
        encryptedLocation: result.encryptedLocation,
        encryptedSanctions: result.encryptedSanctions,
        publicKey: result.publicKey,
        dataHash: result.dataHash,
      }
    } catch (error) {
      console.error('Error getting latest encryption:', error)
      return null
    }
  }

  /**
   * Subscribe to encryption events
   */
  onEncryptionCompleted(
    callback: (requestId: string, user: string, dataHash: string) => void
  ) {
    this.contract.on('EncryptionCompleted', (requestId, user, dataHash) => {
      callback(requestId, user, dataHash)
    })
  }

  /**
   * Subscribe to computation events
   */
  onComputationCompleted(
    callback: (requestId: string, isValid: boolean, resultHash: string) => void
  ) {
    this.contract.on('ComputationCompleted', (requestId, isValid, resultHash) => {
      callback(requestId, isValid, resultHash)
    })
  }

  /**
   * Unsubscribe from events
   */
  removeAllListeners() {
    this.contract.removeAllListeners()
  }
}

