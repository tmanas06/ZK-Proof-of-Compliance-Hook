import { Activity, ShieldCheck, Clock3 } from 'lucide-react'

interface InsightsProps {
  account: string | null
  complianceHash: string | null
  isCompliant: boolean | null
}

const timeline = [
  { title: 'Proof Submitted', desc: 'Brevis ZK proof accepted by hook', time: '2 mins ago' },
  { title: 'EigenLayer AVS Pending', desc: 'Waiting for decentralized attestation', time: '12 mins ago' },
  { title: 'Liquidity Attempt', desc: 'User tried adding liquidity', time: '30 mins ago' }
]

function InsightsPage({ account, complianceHash, isCompliant }: InsightsProps) {
  return (
    <div className="page insights-page">
      <section className="card glass">
        <h2>Compliance Snapshot</h2>
        <div className="insights-grid">
          <article className="stat-chip">
            <ShieldCheck size={24} />
            <div>
              <p>Status</p>
              <strong>{isCompliant ? 'Verified' : 'Pending'}</strong>
              <span>{isCompliant ? 'Brevis approved' : 'Requires proof submission'}</span>
            </div>
          </article>

          <article className="stat-chip">
            <Activity size={24} />
            <div>
              <p>Proof Hash</p>
              <strong>{complianceHash ? `${complianceHash.slice(0, 8)}…` : 'N/A'}</strong>
              <span>{complianceHash ? 'Synced with hook' : 'Awaiting hash'}</span>
            </div>
          </article>

          <article className="stat-chip">
            <Clock3 size={24} />
            <div>
              <p>Last Action</p>
              <strong>{account ? 'a few moments ago' : '—'}</strong>
              <span>{account ? 'Wallet monitored in real-time' : 'Connect wallet'}</span>
            </div>
          </article>
        </div>
      </section>

      <section className="card">
        <h3>Activity Timeline</h3>
        <ul className="timeline">
          {timeline.map(item => (
            <li key={item.title}>
              <div>
                <p className="timeline-title">{item.title}</p>
                <span>{item.desc}</span>
              </div>
              <small>{item.time}</small>
            </li>
          ))}
        </ul>
      </section>
    </div>
  )
}

export default InsightsPage

