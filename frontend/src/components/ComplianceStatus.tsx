import { Shield, ShieldCheck, ShieldX } from 'lucide-react'
import './ComplianceStatus.css'

interface ComplianceStatusProps {
  isCompliant: boolean | null
  complianceHash: string | null
  account: string
}

function ComplianceStatus({ isCompliant, complianceHash, account }: ComplianceStatusProps) {
  const formatHash = (hash: string) => {
    return `${hash.slice(0, 10)}...${hash.slice(-8)}`
  }

  return (
    <div className="compliance-status">
      <h2>Compliance Status</h2>
      <div className="status-card">
        {isCompliant === null ? (
          <div className="status-loading">
            <Shield size={24} />
            <span>Checking compliance status...</span>
          </div>
        ) : isCompliant ? (
          <div className="status-compliant">
            <ShieldCheck className="icon-compliant" size={32} />
            <div className="status-info">
              <h3>Compliant</h3>
              <p>You are verified and can interact with the pool</p>
              {complianceHash && (
                <div className="hash-display">
                  <span className="hash-label">Compliance Hash:</span>
                  <code>{formatHash(complianceHash)}</code>
                </div>
              )}
            </div>
          </div>
        ) : (
          <div className="status-non-compliant">
            <ShieldX className="icon-non-compliant" size={32} />
            <div className="status-info">
              <h3>Not Compliant</h3>
              <p>You need to generate and submit a compliance proof</p>
            </div>
          </div>
        )}
      </div>
    </div>
  )
}

export default ComplianceStatus

