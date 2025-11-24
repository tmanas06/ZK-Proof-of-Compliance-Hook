import { useState, useEffect } from 'react'
import { ethers } from 'ethers'
import { BrowserRouter as Router, Routes, Route, NavLink } from 'react-router-dom'
import { ShieldCheck, Cpu, BookOpenCheck, BarChart3 } from 'lucide-react'
import './App.css'
import WalletConnection from './components/WalletConnection'
import DashboardPage from './pages/Dashboard'
import InsightsPage from './pages/Insights'
import ResourcesPage from './pages/Resources'

// Contract addresses (update these after deployment)
// Use the hook from the latest router deployment
const HOOK_ADDRESS = '0x67d269191c92caf3cd7723f116c85e6e9bf55933' // From router deployment
const VERIFIER_ADDRESS = '0xc5a5c42992decbae36851359345fe25997f5c42d' // From router deployment
// Router and PoolManager addresses (set after deploying router)
// These can also be set in the frontend UI
export const ROUTER_ADDRESS = localStorage.getItem('routerAddress') || '0x0000000000000000000000000000000000000000'
export const POOL_MANAGER_ADDRESS = localStorage.getItem('poolManagerAddress') || '0x0000000000000000000000000000000000000000'

const VERIFIER_ABI = [
  'function isUserCompliant(address user) external view returns (bool)',
  'function getUserComplianceHash(address user) external view returns (bytes32)'
]

function App() {
  const [provider, setProvider] = useState<ethers.BrowserProvider | null>(null)
  const [signer, setSigner] = useState<ethers.JsonRpcSigner | null>(null)
  const [account, setAccount] = useState<string | null>(null)
  const [isCompliant, setIsCompliant] = useState<boolean | null>(null)
  const [complianceHash, setComplianceHash] = useState<string | null>(null)

  useEffect(() => {
    if (window.ethereum) {
      const newProvider = new ethers.BrowserProvider(window.ethereum)
      setProvider(newProvider)
    }
  }, [])

  const connectWallet = async () => {
    if (!window.ethereum) {
      alert('Please install MetaMask!')
      return
    }

    try {
      const newProvider = new ethers.BrowserProvider(window.ethereum)
      await newProvider.send('eth_requestAccounts', [])
      const newSigner = await newProvider.getSigner()
      const address = await newSigner.getAddress()

      setProvider(newProvider)
      setSigner(newSigner)
      setAccount(address)

      // Check compliance status
      await checkComplianceStatus(address, newProvider)
    } catch (error) {
      console.error('Error connecting wallet:', error)
      alert('Failed to connect wallet')
    }
  }

  const checkComplianceStatus = async (userAddress: string, prov: ethers.BrowserProvider) => {
    try {
      const verifier = new ethers.Contract(VERIFIER_ADDRESS, VERIFIER_ABI, prov)
      const compliant = await verifier.isUserCompliant(userAddress)
      const hash = await verifier.getUserComplianceHash(userAddress)

      setIsCompliant(compliant)
      setComplianceHash(hash === ethers.ZeroHash ? null : hash)
    } catch (error) {
      console.error('Error checking compliance:', error)
      setIsCompliant(false)
    }
  }

  const disconnectWallet = () => {
    setProvider(null)
    setSigner(null)
    setAccount(null)
    setIsCompliant(null)
    setComplianceHash(null)
  }

  const navLinks = [
    { to: '/', label: 'Dashboard', icon: ShieldCheck },
    { to: '/insights', label: 'Insights', icon: BarChart3 },
    { to: '/resources', label: 'Resources', icon: BookOpenCheck }
  ]

  return (
    <Router>
      <div className="app-shell">
        <aside className="sidebar">
          <div className="brand">
            <Cpu size={28} />
            <div>
              <p className="brand-title">Brevis Compliance</p>
              <span className="brand-subtitle">Uniswap v4 Hook</span>
            </div>
          </div>

          <nav className="nav-links">
            {navLinks.map(link => {
              const Icon = link.icon
              return (
                <NavLink key={link.to} to={link.to} className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`} end={link.to === '/'}>
                  <Icon size={18} />
                  <span>{link.label}</span>
                </NavLink>
              )
            })}
          </nav>
        </aside>

        <div className="content-area">
          <header className="topbar">
            <div>
              <h1>ZK Proof of Compliance</h1>
              <p>Zero-Knowledge security for every swap, powered by Brevis + EigenLayer.</p>
            </div>
            <WalletConnection account={account} onConnect={connectWallet} onDisconnect={disconnectWallet} />
          </header>

          <Routes>
            <Route
              path="/"
              element={
                <DashboardPage
                  account={account}
                  signer={signer}
                  isCompliant={isCompliant}
                  complianceHash={complianceHash}
                  hookAddress={HOOK_ADDRESS}
                  onProofSubmitted={() => {
                    if (account && provider) {
                      checkComplianceStatus(account, provider)
                    }
                  }}
                />
              }
            />
            <Route path="/insights" element={<InsightsPage account={account} complianceHash={complianceHash} isCompliant={isCompliant} />} />
            <Route path="/resources" element={<ResourcesPage />} />
          </Routes>

          <footer className="app-footer">
            <p>© {new Date().getFullYear()} Brevis Compliance. Built with Uniswap v4 + EigenLayer.</p>
          </footer>
        </div>
      </div>
    </Router>
  )
}

export default App

