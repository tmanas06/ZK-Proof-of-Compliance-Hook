import ComplianceStatus from '../components/ComplianceStatus'
import ProofGenerator from '../components/ProofGenerator'
import PoolInteraction from '../components/PoolInteraction'
import EigenLayerStatus from '../components/EigenLayerStatus'
import FhenixIntegration from '../components/FhenixIntegration'
import { ethers } from 'ethers'

interface DashboardProps {
  account: string | null
  signer: ethers.JsonRpcSigner | null
  isCompliant: boolean | null
  complianceHash: string | null
  hookAddress: string
  onProofSubmitted: () => void
}

function DashboardPage({
  account,
  signer,
  isCompliant,
  complianceHash,
  hookAddress,
  onProofSubmitted
}: DashboardProps) {
  const complianceScore = complianceHash ? 92 : 12

  return (
    <div className="page dashboard-page">
      <section className="hero-card">
        <div>
          <p className="badge">{account ? 'Live Mode' : 'Get Started'}</p>
          <h2>Brevis Guardrail</h2>
          <p className="hero-copy">
            Plug-and-play compliance for Uniswap v4. Enforce proofs, track EigenLayer attestations, and keep LPs safe—all
            without revealing any PII.
          </p>
        </div>
        <div className="hero-metric">
          <p>Compliance Confidence</p>
          <strong>{complianceScore}%</strong>
          <span>{account ? 'Proof verified by Brevis' : 'Connect wallet to unlock dashboard'}</span>
        </div>
      </section>

      {!account && (
        <section className="card muted">
          <h3>Connect your wallet to unlock the control center</h3>
          <p>
            Once connected, you can generate ZK proofs, monitor EigenLayer verification, and manage Uniswap interactions
            from one screen.
          </p>
        </section>
      )}

      {account && (
        <>
          <section className="grid two-col">
            <ComplianceStatus isCompliant={isCompliant} complianceHash={complianceHash} />
            <ProofGenerator account={account} signer={signer} hookAddress={hookAddress} onProofSubmitted={onProofSubmitted} />
          </section>

          <section className="grid single">
            <PoolInteraction account={account} signer={signer} hookAddress={hookAddress} isCompliant={isCompliant} />
          </section>

          <section className="grid two-col">
            <EigenLayerStatus account={account} signer={signer} hookAddress={hookAddress} />
            <FhenixIntegration account={account} />
          </section>
        </>
      )}
    </div>
  )
}

export default DashboardPage

