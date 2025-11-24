import { useState } from 'react'
import { Lock, Shield } from 'lucide-react'
import './FhenixIntegration.css'

interface FhenixIntegrationProps {
  account: string | null
}

function FhenixIntegration({ account }: FhenixIntegrationProps) {
  const [encrypted, setEncrypted] = useState(false)

  const handleEncrypt = () => {
    // Placeholder for Fhenix FHE encryption
    // In production, this would call Fhenix SDK
    setEncrypted(true)
    setTimeout(() => setEncrypted(false), 3000)
  }

  return (
    <div className="fhenix-integration">
      <h2>Fhenix FHE Privacy Layer</h2>
      
      <div className="fhe-info">
        <div className="fhe-icon">
          <Lock size={48} />
        </div>
        <div className="fhe-description">
          <h3>Fully Homomorphic Encryption</h3>
          <p>
            Fhenix enables privacy-preserving computation on encrypted compliance data.
            Your personal information is encrypted and processed without ever being decrypted.
          </p>
        </div>
      </div>

      <div className="fhe-features">
        <div className="feature">
          <Shield size={24} />
          <div>
            <h4>Privacy-Preserving</h4>
            <p>Data remains encrypted during computation</p>
          </div>
        </div>
        <div className="feature">
          <Lock size={24} />
          <div>
            <h4>Secure Processing</h4>
            <p>Compliance checks performed on encrypted data</p>
          </div>
        </div>
      </div>

      {account && (
        <div className="fhe-actions">
          <button
            onClick={handleEncrypt}
            disabled={encrypted}
            className="btn btn-primary"
          >
            {encrypted ? 'Encrypting...' : 'Encrypt Compliance Data'}
          </button>
        </div>
      )}

      {encrypted && (
        <div className="encryption-status">
          <p>✓ Data encrypted using Fhenix FHE</p>
          <p className="note">This is a placeholder. In production, this would use actual Fhenix FHE encryption.</p>
        </div>
      )}

      <div className="info-note">
        <p>
          <strong>Note:</strong> Fhenix FHE integration is currently a placeholder.
          In production, this would integrate with Fhenix's fully homomorphic encryption
          services to process compliance data privately before generating ZK proofs.
        </p>
      </div>
    </div>
  )
}

export default FhenixIntegration

