import { useState, useEffect } from 'react'
import { ethers } from 'ethers'
import { Shield, CheckCircle2, XCircle, Clock, Key, FileText } from 'lucide-react'
import './ProductionHook.css'

// Production Compliance Hook ABI
const PRODUCTION_HOOK_ABI = [
  'function submitProof(uint256[2] memory a, uint256[2][2] memory b, uint256[2] memory c, uint256[] memory publicSignals) external',
  'function checkCompliance(address user) external view returns (bool isCompliant, bytes32 complianceHash, uint256 lastProofTime)',
  'function enabled() external view returns (bool)',
  'function proofExpiration() external view returns (uint256)',
  'function requirements() external view returns (bool requireKYC, bool requireAgeVerification, bool requireLocationCheck, bool requireSanctionsCheck, uint256 minAge, bytes2 allowedCountryCode)',
  'function admin() external view returns (address)',
  'function groth16Verifier() external view returns (address)',
  'event ProofSubmitted(address indexed user, bytes32 indexed proofHash, bytes32 indexed dataHash, uint256 timestamp)',
  'event ProofVerified(address indexed user, bytes32 indexed proofHash, bool isValid)'
]

// Production Hook Address (from deployment)
const PRODUCTION_HOOK_ADDRESS = '0xB7f8BC63BbcaD18155201308C8f3540b07f84F5e'
const GROTH16_VERIFIER_ADDRESS = '0x610178dA211FEF7D417bC0e6FeD39F05609AD788'

interface ProductionHookProps {
  account: string | null
  signer: ethers.JsonRpcSigner | null
  provider: ethers.BrowserProvider | null
}

interface ComplianceStatus {
  isCompliant: boolean
  complianceHash: string | null
  lastProofTime: number | null
  proofExpired: boolean
}

function ProductionHookPage({ account, signer, provider }: ProductionHookProps) {
  const [complianceStatus, setComplianceStatus] = useState<ComplianceStatus>({
    isCompliant: false,
    complianceHash: null,
    lastProofTime: null,
    proofExpired: false
  })
  const [hookEnabled, setHookEnabled] = useState<boolean>(true)
  const [proofExpiration, setProofExpiration] = useState<number>(0)
  const [requirements, setRequirements] = useState<any>(null)
  const [loading, setLoading] = useState<boolean>(false)
  const [error, setError] = useState<string | null>(null)
  const [success, setSuccess] = useState<string | null>(null)
  const [proofInput, setProofInput] = useState({
    a: ['', ''],
    b: [['', ''], ['', '']],
    c: ['', ''],
    publicSignals: ['']
  })

  useEffect(() => {
    if (account && provider) {
      loadHookStatus()
      loadComplianceStatus()
    }
  }, [account, provider])

  const loadHookStatus = async () => {
    if (!provider) return

    try {
      const hook = new ethers.Contract(PRODUCTION_HOOK_ADDRESS, PRODUCTION_HOOK_ABI, provider)
      const enabled = await hook.enabled()
      const expiration = await hook.proofExpiration()
      const reqs = await hook.requirements()

      setHookEnabled(enabled)
      setProofExpiration(Number(expiration))
      setRequirements({
        requireKYC: reqs.requireKYC,
        requireAgeVerification: reqs.requireAgeVerification,
        requireLocationCheck: reqs.requireLocationCheck,
        requireSanctionsCheck: reqs.requireSanctionsCheck,
        minAge: Number(reqs.minAge),
        allowedCountryCode: ethers.toUtf8String(reqs.allowedCountryCode).replace(/\0/g, '')
      })
    } catch (err: any) {
      console.error('Error loading hook status:', err)
    }
  }

  const loadComplianceStatus = async () => {
    if (!account || !provider) return

    try {
      const hook = new ethers.Contract(PRODUCTION_HOOK_ADDRESS, PRODUCTION_HOOK_ABI, provider)
      const [isCompliant, hash, lastTime] = await hook.checkCompliance(account)

      const proofExpired = lastTime > 0 && Date.now() / 1000 > Number(lastTime) + proofExpiration

      setComplianceStatus({
        isCompliant: isCompliant && !proofExpired,
        complianceHash: hash === ethers.ZeroHash ? null : hash,
        lastProofTime: Number(lastTime),
        proofExpired
      })
    } catch (err: any) {
      console.error('Error loading compliance status:', err)
      setComplianceStatus({
        isCompliant: false,
        complianceHash: null,
        lastProofTime: null,
        proofExpired: false
      })
    }
  }

  const handleSubmitProof = async () => {
    if (!signer) {
      setError('Please connect your wallet')
      return
    }

    setLoading(true)
    setError(null)
    setSuccess(null)

    try {
      // Validate all inputs are provided
      if (
        !proofInput.a[0] || !proofInput.a[1] ||
        !proofInput.b[0][0] || !proofInput.b[0][1] ||
        !proofInput.b[1][0] || !proofInput.b[1][1] ||
        !proofInput.c[0] || !proofInput.c[1] ||
        proofInput.publicSignals.length < 2
      ) {
        setError('Please fill in all proof components and at least 2 public signals')
        setLoading(false)
        return
      }

      // Validate proof format
      const a: [string, string] = [proofInput.a[0], proofInput.a[1]]
      const b: [[string, string], [string, string]] = [
        [proofInput.b[0][0], proofInput.b[0][1]],
        [proofInput.b[1][0], proofInput.b[1][1]]
      ]
      const c: [string, string] = [proofInput.c[0], proofInput.c[1]]
      const publicSignals = proofInput.publicSignals.filter(s => s.trim() !== '').map(s => BigInt(s))

      // Convert to uint256 arrays
      const aUint: [bigint, bigint] = [BigInt(a[0]), BigInt(a[1])]
      const bUint: [[bigint, bigint], [bigint, bigint]] = [
        [BigInt(b[0][0]), BigInt(b[0][1])],
        [BigInt(b[1][0]), BigInt(b[1][1])]
      ]
      const cUint: [bigint, bigint] = [BigInt(c[0]), BigInt(c[1])]

      const hook = new ethers.Contract(PRODUCTION_HOOK_ADDRESS, PRODUCTION_HOOK_ABI, signer)
      const tx = await hook.submitProof(aUint, bUint, cUint, publicSignals)
      
      setSuccess(`Proof submitted! Transaction: ${tx.hash}`)
      await tx.wait()
      
      // Reload compliance status
      await loadComplianceStatus()
      setSuccess(`Proof verified and submitted successfully!`)
    } catch (err: any) {
      console.error('Error submitting proof:', err)
      setError(err.reason || err.message || 'Failed to submit proof')
    } finally {
      setLoading(false)
    }
  }

  const formatTime = (timestamp: number) => {
    if (!timestamp) return 'Never'
    const date = new Date(timestamp * 1000)
    return date.toLocaleString()
  }

  const formatDuration = (seconds: number) => {
    const days = Math.floor(seconds / 86400)
    const hours = Math.floor((seconds % 86400) / 3600)
    if (days > 0) return `${days} days, ${hours} hours`
    return `${hours} hours`
  }

  return (
    <div className="page production-hook-page">
      <section className="hero-card">
        <div>
          <p className="badge">{hookEnabled ? 'Active' : 'Disabled'}</p>
          <h2>Production Compliance Hook</h2>
          <p className="hero-copy">
            Submit Groth16 zk-SNARK proofs for compliance verification. This hook uses real Groth16 verification
            generated from the compliance.circom circuit.
          </p>
        </div>
        <div className="hero-metric">
          <p>Groth16 Verifier</p>
          <strong>Active</strong>
          <span>{GROTH16_VERIFIER_ADDRESS.slice(0, 10)}...{GROTH16_VERIFIER_ADDRESS.slice(-8)}</span>
        </div>
      </section>

      {!account && (
        <section className="card muted">
          <h3>Connect your wallet</h3>
          <p>Connect your wallet to submit Groth16 proofs and check your compliance status.</p>
        </section>
      )}

      {account && (
        <>
          {/* Compliance Status Card */}
          <section className="card">
            <div className="card-header">
              <Shield size={20} />
              <h3>Your Compliance Status</h3>
            </div>
            <div className="compliance-status-display">
              {complianceStatus.isCompliant ? (
                <div className="status-badge compliant">
                  <CheckCircle2 size={24} />
                  <div>
                    <strong>Compliant</strong>
                    <p>Your proof is valid and active</p>
                  </div>
                </div>
              ) : (
                <div className="status-badge non-compliant">
                  <XCircle size={24} />
                  <div>
                    <strong>Not Compliant</strong>
                    <p>
                      {complianceStatus.proofExpired
                        ? 'Your proof has expired. Please submit a new proof.'
                        : 'You need to submit a compliance proof.'}
                    </p>
                  </div>
                </div>
              )}

              {complianceStatus.complianceHash && (
                <div className="status-details">
                  <div className="detail-item">
                    <span>Compliance Hash:</span>
                    <code>{complianceStatus.complianceHash.slice(0, 20)}...{complianceStatus.complianceHash.slice(-16)}</code>
                  </div>
                  {complianceStatus.lastProofTime && (
                    <div className="detail-item">
                      <span>Last Proof Time:</span>
                      <span>{formatTime(complianceStatus.lastProofTime)}</span>
                    </div>
                  )}
                  {proofExpiration > 0 && (
                    <div className="detail-item">
                      <span>Proof Expires:</span>
                      <span>
                        {complianceStatus.lastProofTime
                          ? formatTime(complianceStatus.lastProofTime + proofExpiration)
                          : 'N/A'}
                      </span>
                    </div>
                  )}
                </div>
              )}
            </div>
            <button onClick={loadComplianceStatus} className="btn-secondary">
              Refresh Status
            </button>
          </section>

          {/* Hook Configuration */}
          {requirements && (
            <section className="card">
              <div className="card-header">
                <Key size={20} />
                <h3>Compliance Requirements</h3>
              </div>
              <div className="requirements-grid">
                <div className="requirement-item">
                  <span>KYC Required:</span>
                  <strong>{requirements.requireKYC ? 'Yes' : 'No'}</strong>
                </div>
                <div className="requirement-item">
                  <span>Age Verification:</span>
                  <strong>{requirements.requireAgeVerification ? `Yes (Min: ${requirements.minAge})` : 'No'}</strong>
                </div>
                <div className="requirement-item">
                  <span>Location Check:</span>
                  <strong>{requirements.requireLocationCheck ? `Yes (${requirements.allowedCountryCode})` : 'No'}</strong>
                </div>
                <div className="requirement-item">
                  <span>Sanctions Check:</span>
                  <strong>{requirements.requireSanctionsCheck ? 'Yes' : 'No'}</strong>
                </div>
                <div className="requirement-item">
                  <span>Proof Expiration:</span>
                  <strong>{formatDuration(proofExpiration)}</strong>
                </div>
              </div>
            </section>
          )}

          {/* Proof Submission */}
          <section className="card">
            <div className="card-header">
              <FileText size={20} />
              <h3>Submit Groth16 Proof</h3>
            </div>
            <p className="card-description">
              Submit a Groth16 zk-SNARK proof generated from the compliance.circom circuit. The proof must be generated
              using snarkjs with the compliance.wasm and compliance_0001.zkey files.
            </p>

            {error && (
              <div className="alert error">
                <XCircle size={18} />
                <div>
                  <strong>Error:</strong>
                  <p>{error}</p>
                </div>
              </div>
            )}

            {success && (
              <div className="alert success">
                <CheckCircle2 size={18} />
                <div>
                  <strong>Success:</strong>
                  <p>{success}</p>
                </div>
              </div>
            )}

            <div className="proof-input-section">
              <div className="proof-group">
                <label>Proof Component A [2]</label>
                <div className="input-row">
                  <input
                    type="text"
                    placeholder="a[0]"
                    value={proofInput.a[0]}
                    onChange={(e) => setProofInput({ ...proofInput, a: [e.target.value, proofInput.a[1]] })}
                  />
                  <input
                    type="text"
                    placeholder="a[1]"
                    value={proofInput.a[1]}
                    onChange={(e) => setProofInput({ ...proofInput, a: [proofInput.a[0], e.target.value] })}
                  />
                </div>
              </div>

              <div className="proof-group">
                <label>Proof Component B [2][2]</label>
                <div className="input-grid">
                  <input
                    type="text"
                    placeholder="b[0][0]"
                    value={proofInput.b[0][0]}
                    onChange={(e) =>
                      setProofInput({
                        ...proofInput,
                        b: [[e.target.value, proofInput.b[0][1]], proofInput.b[1]]
                      })
                    }
                  />
                  <input
                    type="text"
                    placeholder="b[0][1]"
                    value={proofInput.b[0][1]}
                    onChange={(e) =>
                      setProofInput({
                        ...proofInput,
                        b: [[proofInput.b[0][0], e.target.value], proofInput.b[1]]
                      })
                    }
                  />
                  <input
                    type="text"
                    placeholder="b[1][0]"
                    value={proofInput.b[1][0]}
                    onChange={(e) =>
                      setProofInput({
                        ...proofInput,
                        b: [proofInput.b[0], [e.target.value, proofInput.b[1][1]]]
                      })
                    }
                  />
                  <input
                    type="text"
                    placeholder="b[1][1]"
                    value={proofInput.b[1][1]}
                    onChange={(e) =>
                      setProofInput({
                        ...proofInput,
                        b: [proofInput.b[0], [proofInput.b[1][0], e.target.value]]
                      })
                    }
                  />
                </div>
              </div>

              <div className="proof-group">
                <label>Proof Component C [2]</label>
                <div className="input-row">
                  <input
                    type="text"
                    placeholder="c[0]"
                    value={proofInput.c[0]}
                    onChange={(e) => setProofInput({ ...proofInput, c: [e.target.value, proofInput.c[1]] })}
                  />
                  <input
                    type="text"
                    placeholder="c[1]"
                    value={proofInput.c[1]}
                    onChange={(e) => setProofInput({ ...proofInput, c: [proofInput.c[0], e.target.value] })}
                  />
                </div>
              </div>

              <div className="proof-group">
                <label>Public Signals (comma-separated or one per line)</label>
                <textarea
                  placeholder="Enter public signals (complianceHash, isValid, ...)"
                  value={proofInput.publicSignals.join(',')}
                  onChange={(e) =>
                    setProofInput({
                      ...proofInput,
                      publicSignals: e.target.value.split(',').map(s => s.trim()).filter(s => s)
                    })
                  }
                  rows={3}
                />
                <small>First signal should be complianceHash, second should be isValid (1 or 0)</small>
              </div>
            </div>

            <button onClick={handleSubmitProof} disabled={loading} className="btn-primary">
              {loading ? 'Submitting...' : 'Submit Proof'}
            </button>

            <div className="help-box">
              <h4>How to Generate a Proof:</h4>
              <ol>
                <li>Use snarkjs with compliance.wasm and compliance_0001.zkey</li>
                <li>Generate proof with: <code>snarkjs groth16 prove compliance_0001.zkey witness.wtns proof.json public.json</code></li>
                <li>Extract proof components from proof.json</li>
                <li>Paste the values into the form above</li>
              </ol>
            </div>
          </section>

          {/* Hook Information */}
          <section className="card">
            <div className="card-header">
              <Clock size={20} />
              <h3>Hook Information</h3>
            </div>
            <div className="info-grid">
              <div className="info-item">
                <span>Hook Address:</span>
                <code>{PRODUCTION_HOOK_ADDRESS}</code>
              </div>
              <div className="info-item">
                <span>Groth16 Verifier:</span>
                <code>{GROTH16_VERIFIER_ADDRESS}</code>
              </div>
              <div className="info-item">
                <span>Status:</span>
                <strong>{hookEnabled ? 'Enabled' : 'Disabled'}</strong>
              </div>
            </div>
          </section>
        </>
      )}
    </div>
  )
}

export default ProductionHookPage

