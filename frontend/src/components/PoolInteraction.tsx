import { useState } from 'react'
import { ethers } from 'ethers'
import { ArrowLeftRight, Plus } from 'lucide-react'
import './PoolInteraction.css'

interface PoolInteractionProps {
  account: string
  signer: ethers.JsonRpcSigner | null
  hookAddress: string
  isCompliant: boolean | null
}

function PoolInteraction({ account, signer, hookAddress, isCompliant }: PoolInteractionProps) {
  const [swapAmount, setSwapAmount] = useState('')
  const [liquidityAmount, setLiquidityAmount] = useState('')
  const [isProcessing, setIsProcessing] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const handleSwap = async () => {
    if (!signer || !isCompliant) {
      setError('You must be compliant to swap')
      return
    }

    setIsProcessing(true)
    setError(null)

    try {
      // In a real implementation, this would interact with the Uniswap v4 pool
      // For demonstration, we'll simulate the interaction
      await new Promise(resolve => setTimeout(resolve, 2000))
      alert('Swap would be executed here (requires full Uniswap v4 integration)')
    } catch (err: any) {
      setError(err.message || 'Swap failed')
    } finally {
      setIsProcessing(false)
    }
  }

  const handleAddLiquidity = async () => {
    if (!signer || !isCompliant) {
      setError('You must be compliant to add liquidity')
      return
    }

    setIsProcessing(true)
    setError(null)

    try {
      // In a real implementation, this would interact with the Uniswap v4 pool
      await new Promise(resolve => setTimeout(resolve, 2000))
      alert('Add liquidity would be executed here (requires full Uniswap v4 integration)')
    } catch (err: any) {
      setError(err.message || 'Add liquidity failed')
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
          <p>{error}</p>
        </div>
      )}

      <div className="info-note">
        <p>
          <strong>Note:</strong> This is a demonstration interface. Full Uniswap v4 integration
          requires connecting to the actual pool manager and router contracts.
        </p>
      </div>
    </div>
  )
}

export default PoolInteraction

