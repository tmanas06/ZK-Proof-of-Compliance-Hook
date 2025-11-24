import { useState, useEffect } from 'react'
import { ethers } from 'ethers'
import { ArrowLeftRight, Plus, CheckCircle } from 'lucide-react'
import './PoolInteraction.css'
import { getErrorMessage, getErrorHelp } from '../utils/errorDecoder'

interface PoolInteractionProps {
  account: string
  signer: ethers.JsonRpcSigner | null
  hookAddress: string
  isCompliant: boolean | null
}

// Contract addresses (update after deployment)
// Default addresses - can be overridden in UI
const DEFAULT_ROUTER_ADDRESS = '0x09635F643e140090A9A8Dcd712eD6285858ceBef' // Latest deployment
const DEFAULT_POOL_MANAGER_ADDRESS = '0x7a2088a1bFc9d81c55368AE168C2C02570cB814F' // Latest deployment

// Mock token addresses for testing
const TOKEN0 = '0x0000000000000000000000000000000000000001' // Mock token 0
const TOKEN1 = '0x0000000000000000000000000000000000000002' // Mock token 1

// Router ABI
const ROUTER_ABI = [
  'function swap(tuple(address currency0, address currency1, uint24 fee, int24 tickSpacing, address hooks) calldata key, tuple(bool zeroForOne, int256 amountSpecified, uint160 sqrtPriceLimitX96) calldata params, bytes calldata hookData) external returns (int256)',
  'function modifyLiquidity(tuple(address currency0, address currency1, uint24 fee, int24 tickSpacing, address hooks) calldata key, tuple(int24 tickLower, int24 tickUpper, int256 liquidityDelta) calldata params, bytes calldata hookData) external returns (int256)',
  'event SwapExecuted(address indexed user, address currency0, address currency1, bool zeroForOne, int256 amountSpecified)',
  'event LiquidityModified(address indexed user, address currency0, address currency1, int256 liquidityDelta)'
]

// Hook ABI for getting proof
const HOOK_ABI = [
  'function userComplianceHashes(address) external view returns (bytes32)'
]

function PoolInteraction({ account, signer, hookAddress, isCompliant }: PoolInteractionProps) {
  const [swapAmount, setSwapAmount] = useState('')
  const [liquidityAmount, setLiquidityAmount] = useState('')
  const [isProcessing, setIsProcessing] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [success, setSuccess] = useState<string | null>(null)
  const [routerAddress, setRouterAddress] = useState<string>(() => {
    return localStorage.getItem('routerAddress') || DEFAULT_ROUTER_ADDRESS
  })
  const [poolManagerAddress, setPoolManagerAddress] = useState<string>(() => {
    return localStorage.getItem('poolManagerAddress') || DEFAULT_POOL_MANAGER_ADDRESS
  })
  const [complianceHash, setComplianceHash] = useState<string | null>(null)
  const [proofHash, setProofHash] = useState<string | null>(null)

  useEffect(() => {
    // Get compliance hash and proof for hook data
    if (signer && hookAddress) {
      loadComplianceHash()
      loadLatestProof()
    }
  }, [signer, hookAddress])

  const loadLatestProof = async () => {
    if (!signer) return
    try {
      // Get the user's compliance hash to create a proof
      const hook = new ethers.Contract(hookAddress, HOOK_ABI, signer)
      const hash = await hook.userComplianceHashes(account)
      if (hash && hash !== ethers.ZeroHash) {
        setComplianceHash(hash)
        // Create a proof hash for this transaction
        const timestamp = Math.floor(Date.now() / 1000)
        const proofHashValue = ethers.keccak256(
          ethers.concat([
            ethers.toUtf8Bytes(account),
            hash,
            ethers.toBeHex(timestamp, 32),
            ethers.toBeHex(Math.floor(Math.random() * 1000000), 32) // Add randomness
          ])
        )
        setProofHash(proofHashValue)
      }
    } catch (err) {
      console.error('Error loading proof:', err)
    }
  }

  const loadComplianceHash = async () => {
    if (!signer) return
    try {
      const hook = new ethers.Contract(hookAddress, HOOK_ABI, signer)
      const hash = await hook.userComplianceHashes(account)
      if (hash && hash !== ethers.ZeroHash) {
        setComplianceHash(hash)
      }
    } catch (err) {
      console.error('Error loading compliance hash:', err)
    }
  }

  const handleSwap = async () => {
    if (!signer || !isCompliant) {
      setError('You must be compliant to swap')
      return
    }

    if (!routerAddress || routerAddress === '0x0000000000000000000000000000000000000000') {
      setError('Router address not set. Please deploy router first.')
      return
    }

    if (!complianceHash) {
      setError('No compliance proof found. Please submit a proof first.')
      return
    }

    setIsProcessing(true)
    setError(null)
    setSuccess(null)

    try {
      const router = new ethers.Contract(routerAddress, ROUTER_ABI, signer)
      
      // Parse amount (assuming 18 decimals)
      const amount = ethers.parseUnits(swapAmount || '1', 18)
      
      // Create pool key
      const poolKey = {
        currency0: TOKEN0,
        currency1: TOKEN1,
        fee: 3000, // 0.3% fee
        tickSpacing: 60,
        hooks: hookAddress
      }
      
      // Create swap params
      const swapParams = {
        zeroForOne: true, // Swap token0 for token1
        amountSpecified: amount,
        sqrtPriceLimitX96: 0 // No price limit
      }
      
      // Create hook data (compliance proof struct)
      // The hook expects a ComplianceProof struct
      if (!complianceHash || !proofHash) {
        setError('No compliance proof found. Please submit a proof first.')
        setIsProcessing(false)
        return
      }
      
      const timestamp = Math.floor(Date.now() / 1000)
      
      const proof = {
        proofHash: proofHash,
        publicInputs: ethers.AbiCoder.defaultAbiCoder().encode(['bytes32'], [complianceHash]),
        timestamp: timestamp,
        user: account
      }
      
      // Encode the full proof struct
      const hookData = ethers.AbiCoder.defaultAbiCoder().encode(
        ['tuple(bytes32 proofHash, bytes publicInputs, uint256 timestamp, address user)'],
        [proof]
      )
      
      // Execute swap
      const tx = await router.swap(poolKey, swapParams, hookData)
      console.log('Swap transaction:', tx.hash)
      
      setSuccess(`Swap transaction submitted! Hash: ${tx.hash}`)
      
      // Wait for confirmation
      await tx.wait()
      setSuccess(`Swap completed successfully! Hash: ${tx.hash}`)
      
      // Reset form
      setSwapAmount('')
    } catch (err: any) {
      console.error('Swap error:', err)
      // Use user-friendly error decoder
      const friendlyError = getErrorMessage(err)
      setError(friendlyError)
    } finally {
      setIsProcessing(false)
    }
  }

  const handleAddLiquidity = async () => {
    if (!signer || !isCompliant) {
      setError('You must be compliant to add liquidity')
      return
    }

    if (!routerAddress || routerAddress === '0x0000000000000000000000000000000000000000') {
      setError('Router address not set. Please deploy router first.')
      return
    }

    if (!complianceHash) {
      setError('No compliance proof found. Please submit a proof first.')
      return
    }

    setIsProcessing(true)
    setError(null)
    setSuccess(null)

    try {
      const router = new ethers.Contract(routerAddress, ROUTER_ABI, signer)
      
      // Parse amount (assuming 18 decimals)
      const amount = ethers.parseUnits(liquidityAmount || '1', 18)
      
      // Create pool key
      const poolKey = {
        currency0: TOKEN0,
        currency1: TOKEN1,
        fee: 3000, // 0.3% fee
        tickSpacing: 60,
        hooks: hookAddress
      }
      
      // Create liquidity params
      const liqParams = {
        tickLower: -887272, // Full range
        tickUpper: 887272,  // Full range
        liquidityDelta: amount
      }
      
      // Create hook data (compliance proof struct)
      if (!complianceHash || !proofHash) {
        setError('No compliance proof found. Please submit a proof first.')
        setIsProcessing(false)
        return
      }
      
      const timestamp = Math.floor(Date.now() / 1000)
      
      // Create a new proof hash for this transaction (to avoid replay)
      const newProofHash = ethers.keccak256(
        ethers.concat([
          proofHash,
          ethers.toBeHex(timestamp, 32),
          ethers.toBeHex(Math.floor(Math.random() * 1000000), 32)
        ])
      )
      
      const proof = {
        proofHash: newProofHash,
        publicInputs: ethers.AbiCoder.defaultAbiCoder().encode(['bytes32'], [complianceHash]),
        timestamp: timestamp,
        user: account
      }
      
      // Encode the full proof struct
      const hookData = ethers.AbiCoder.defaultAbiCoder().encode(
        ['tuple(bytes32 proofHash, bytes publicInputs, uint256 timestamp, address user)'],
        [proof]
      )
      
      // Execute liquidity modification
      const tx = await router.modifyLiquidity(poolKey, liqParams, hookData)
      console.log('Liquidity transaction:', tx.hash)
      
      setSuccess(`Liquidity transaction submitted! Hash: ${tx.hash}`)
      
      // Wait for confirmation
      await tx.wait()
      setSuccess(`Liquidity added successfully! Hash: ${tx.hash}`)
      
      // Reset form
      setLiquidityAmount('')
    } catch (err: any) {
      console.error('Liquidity error:', err)
      // Use user-friendly error decoder
      const friendlyError = getErrorMessage(err)
      setError(friendlyError)
    } finally {
      setIsProcessing(false)
    }
  }

  return (
    <div className="pool-interaction">
      <h2>Pool Interaction</h2>
      
      {!isCompliant && (
        <div className="warning-box">
          <p>⚠️ You must be compliant to interact with the pool</p>
        </div>
      )}

      <div className="interaction-grid">
        <div className="interaction-card">
          <h3>Swap Tokens</h3>
          <div className="input-group">
            <input
              type="text"
              placeholder="Amount"
              value={swapAmount}
              onChange={(e) => setSwapAmount(e.target.value)}
              disabled={!isCompliant || isProcessing}
              className="input"
            />
          </div>
          <button
            onClick={handleSwap}
            disabled={!isCompliant || isProcessing || !swapAmount}
            className="btn btn-primary btn-action"
          >
            <ArrowLeftRight size={20} />
            {isProcessing ? 'Processing...' : 'Swap'}
          </button>
        </div>

        <div className="interaction-card">
          <h3>Add Liquidity</h3>
          <div className="input-group">
            <input
              type="text"
              placeholder="Amount"
              value={liquidityAmount}
              onChange={(e) => setLiquidityAmount(e.target.value)}
              disabled={!isCompliant || isProcessing}
              className="input"
            />
          </div>
          <button
            onClick={handleAddLiquidity}
            disabled={!isCompliant || isProcessing || !liquidityAmount}
            className="btn btn-primary btn-action"
          >
            <Plus size={20} />
            {isProcessing ? 'Processing...' : 'Add Liquidity'}
          </button>
        </div>
      </div>

      {error && (
        <div className="error-box">
          <p><strong>{error}</strong></p>
          {getErrorHelp({ message: error }).length > 0 && (
            <div className="error-help" style={{ marginTop: '10px', paddingLeft: '20px' }}>
              <p><strong>What to do:</strong></p>
              <ul style={{ marginTop: '5px' }}>
                {getErrorHelp({ message: error }).map((help, idx) => (
                  <li key={idx} style={{ marginBottom: '5px' }}>{help}</li>
                ))}
              </ul>
            </div>
          )}
        </div>
      )}

      {success && (
        <div className="success-box">
          <CheckCircle className="icon-success" size={20} />
          <p>{success}</p>
        </div>
      )}

      <div className="config-section">
        <h3>Configuration</h3>
        <div className="input-group">
          <label>Router Address:</label>
          <input
            type="text"
            value={routerAddress}
            onChange={(e) => {
              setRouterAddress(e.target.value)
              localStorage.setItem('routerAddress', e.target.value)
            }}
            placeholder="0x..."
            className="input"
          />
        </div>
        <div className="input-group">
          <label>Pool Manager Address:</label>
          <input
            type="text"
            value={poolManagerAddress}
            onChange={(e) => {
              setPoolManagerAddress(e.target.value)
              localStorage.setItem('poolManagerAddress', e.target.value)
            }}
            placeholder="0x..."
            className="input"
          />
        </div>
        {complianceHash && (
          <div className="info-box">
            <p>Compliance Hash: {complianceHash.slice(0, 20)}...</p>
          </div>
        )}
      </div>
    </div>
  )
}

export default PoolInteraction

