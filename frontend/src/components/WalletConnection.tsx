import { CheckCircle, XCircle } from 'lucide-react'
import './WalletConnection.css'

interface WalletConnectionProps {
  account: string | null
  onConnect: () => void
  onDisconnect: () => void
}

function WalletConnection({ account, onConnect, onDisconnect }: WalletConnectionProps) {
  const formatAddress = (addr: string) => {
    return `${addr.slice(0, 6)}...${addr.slice(-4)}`
  }

  return (
    <div className="wallet-connection">
      <h2>Wallet Connection</h2>
      {account ? (
        <div className="wallet-connected">
          <div className="wallet-info">
            <CheckCircle className="icon-success" size={20} />
            <span>Connected: {formatAddress(account)}</span>
          </div>
          <button onClick={onDisconnect} className="btn btn-secondary">
            Disconnect
          </button>
        </div>
      ) : (
        <div className="wallet-disconnected">
          <XCircle className="icon-error" size={20} />
          <span>No wallet connected</span>
          <button onClick={onConnect} className="btn btn-primary">
            Connect Wallet
          </button>
        </div>
      )}
    </div>
  )
}

export default WalletConnection

