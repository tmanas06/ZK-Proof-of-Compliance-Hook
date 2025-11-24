/**
 * Error decoder utility for user-friendly error messages
 * Decodes Solidity custom errors and provides clear explanations
 */

// Error selectors (first 4 bytes of keccak256(error signature))
const ERROR_SELECTORS: { [key: string]: string } = {
  '0xadcd8b60': 'UserNotCompliant',
  '0x09bde339': 'InvalidProof',
  '0xc9838a65': 'ProofAlreadyUsed',
  '0xb67a7713': 'ProofExpired',
  '0x7e5ba1ad': 'HookNotEnabled',
  '0xea2e0857': 'InvalidComplianceData',
  '0x1f2a2005': 'Unauthorized',
}

// User-friendly error messages
const ERROR_MESSAGES: { [key: string]: string } = {
  UserNotCompliant: '❌ You are not marked as compliant. Please contact an administrator to set your compliance status.',
  InvalidProof: '❌ The proof is invalid. Please generate a new proof.',
  ProofAlreadyUsed: '⚠️ This proof has already been used. Please generate a new proof.',
  ProofExpired: '⏰ This proof has expired. Please generate a new proof.',
  HookNotEnabled: '🔒 The compliance hook is currently disabled.',
  InvalidComplianceData: '❌ Invalid compliance data provided.',
  Unauthorized: '🚫 You are not authorized to perform this action.',
}

/**
 * Decode error from transaction data
 * @param errorData The error data from the transaction
 * @returns User-friendly error message
 */
export function decodeError(errorData: string): string {
  if (!errorData || errorData === '0x') {
    return '❌ An unknown error occurred. Please try again.'
  }

  // Extract error selector (first 4 bytes)
  const selector = errorData.slice(0, 10) // 0x + 8 hex chars = 10 chars

  // Check if we know this error
  const errorName = ERROR_SELECTORS[selector]
  if (errorName && ERROR_MESSAGES[errorName]) {
    return ERROR_MESSAGES[errorName]
  }

  // Try to decode common errors
  if (errorData.includes('insufficient funds')) {
    return '💰 Insufficient funds. Please add more ETH to your wallet.'
  }

  if (errorData.includes('user rejected')) {
    return '❌ Transaction was rejected. Please try again.'
  }

  if (errorData.includes('nonce')) {
    return '⚠️ Transaction nonce error. Please refresh and try again.'
  }

  // Default message
  return `❌ Transaction failed. Error code: ${selector}`
}

/**
 * Extract error message from ethers error object
 * @param error The error object from ethers
 * @returns User-friendly error message
 */
export function getErrorMessage(error: any): string {
  if (!error) {
    return '❌ An unknown error occurred.'
  }

  // Check for custom error data
  if (error.data) {
    const decoded = decodeError(error.data)
    if (decoded) return decoded
  }

  // Check for error reason
  if (error.reason) {
    return `❌ ${error.reason}`
  }

  // Check for error message
  if (error.message) {
    // Try to extract error data from message
    const dataMatch = error.message.match(/data="(0x[a-fA-F0-9]+)"/)
    if (dataMatch) {
      const decoded = decodeError(dataMatch[1])
      if (decoded) return decoded
    }

    // Check for common error patterns
    if (error.message.includes('execution reverted')) {
      const dataMatch = error.message.match(/data="(0x[a-fA-F0-9]+)"/)
      if (dataMatch) {
        return decodeError(dataMatch[1])
      }
      return '❌ Transaction was reverted. Please check your inputs and try again.'
    }

    if (error.message.includes('user rejected')) {
      return '❌ Transaction was rejected. Please approve the transaction in MetaMask.'
    }

    if (error.message.includes('insufficient funds')) {
      return '💰 Insufficient funds. Please add more ETH to your wallet.'
    }

    // Return a simplified version of the message
    return `❌ ${error.message.split('\n')[0].substring(0, 100)}`
  }

  // Fallback
  return '❌ An unknown error occurred. Please try again.'
}

/**
 * Get actionable help text based on error
 * @param error The error object
 * @returns Helpful action items
 */
export function getErrorHelp(error: any): string[] {
  const errorMsg = getErrorMessage(error)
  const help: string[] = []

  if (errorMsg.includes('not marked as compliant')) {
    help.push('1. Contact an administrator to set your compliance status')
    help.push('2. Or run: forge script script/InteractWithContracts.s.sol --rpc-url http://localhost:8545 --broadcast')
  }

  if (errorMsg.includes('proof has already been used')) {
    help.push('1. Generate a new proof using the "Generate Proof" button')
    help.push('2. Submit the new proof')
  }

  if (errorMsg.includes('proof has expired')) {
    help.push('1. Generate a new proof (proofs expire after 30 days)')
    help.push('2. Submit the new proof')
  }

  if (errorMsg.includes('Insufficient funds')) {
    help.push('1. Add ETH to your wallet')
    help.push('2. Check your wallet balance')
  }

  if (errorMsg.includes('Transaction was rejected')) {
    help.push('1. Check MetaMask for pending transactions')
    help.push('2. Approve the transaction when prompted')
  }

  return help
}

