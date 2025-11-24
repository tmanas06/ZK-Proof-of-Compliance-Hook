import { useState, useEffect } from 'react'
import { ethers } from 'ethers'
import './App.css'
import WalletConnection from './components/WalletConnection'
import ComplianceStatus from './components/ComplianceStatus'
import ProofGenerator from './components/ProofGenerator'
import PoolInteraction from './components/PoolInteraction'
import EigenLayerStatus from './components/EigenLayerStatus'
import FhenixIntegration from './components/FhenixIntegration'

// Contract addresses (update these after deployment)
const HOOK_ADDRESS = '0xa513E6E4b8f2a923D98304ec87F64353C4D5C853' // Latest deployment
const VERIFIER_ADDRESS = '0x0165878A594ca255338adfa4d48449f69242Eb8F' // Latest deployment
const EIGENLAYER_AVS_ADDRESS = '0x0000000000000000000000000000000000000000' // Update if EigenLayer deployed

// ABI snippets (in production, import from artifacts)
const HOOK_ABI = [
  'function submitProof(tuple(bytes32 proofHash, bytes publicInputs, uint256 timestamp, address user) calldata proof) external',
  'function isUserCompliant(address user) external view returns (bool)',
  'function isProofUsed(bytes32 proofHash) external view returns (bool)',
  'function userComplianceHashes(address) external view returns (bytes32)',
  'event ProofSubmitted(address indexed user, bytes32 proofHash, bytes32 dataHash)'
]

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

  return (
    <div className="app">
      <header className="app-header">
        <h1>ZK Proof of Compliance</h1>
        <p className="subtitle">Uniswap v4 Hook with Brevis Network</p>
      </header>

      <main className="app-main">
        <WalletConnection
          account={account}
          onConnect={connectWallet}
          onDisconnect={disconnectWallet}
        />

        {account && (
          <>
            <ComplianceStatus
              isCompliant={isCompliant}
              complianceHash={complianceHash}
              account={account}
            />

            <ProofGenerator
              account={account}
              signer={signer}
              hookAddress={HOOK_ADDRESS}
              onProofSubmitted={() => checkComplianceStatus(account, provider!)}
            />

            <PoolInteraction
              account={account}
              signer={signer}
              hookAddress={HOOK_ADDRESS}
              isCompliant={isCompliant}
            />

            <EigenLayerStatus
              account={account}
              signer={signer}
              avsAddress={EIGENLAYER_AVS_ADDRESS}
              hookAddress={HOOK_ADDRESS}
            />

            <FhenixIntegration account={account} />
          </>
        )}

        {!account && (
          <div className="info-box">
            <p>Connect your wallet to get started</p>
            <p className="info-text">
              This application demonstrates the ZK Proof of Compliance hook for Uniswap v4.
              Users must provide valid zero-knowledge compliance proofs to swap or add liquidity.
            </p>
          </div>
        )}
      </main>

      <footer className="app-footer">
        <p>Built with Uniswap v4 & Brevis Network</p>
      </footer>
    </div>
  )
}

export default App

