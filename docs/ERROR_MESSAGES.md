# Error Messages Guide

## Overview

The frontend now decodes Solidity custom errors and displays **user-friendly error messages** instead of technical gibberish.

## Error Decoding

When a transaction fails, the system:

1. **Extracts the error selector** (first 4 bytes of the error data)
2. **Maps it to a friendly message** using our error decoder
3. **Shows actionable help** if available

## Error Messages

### UserNotCompliant (`0xadcd8b60`)
**Message:** ❌ You are not marked as compliant. Please contact an administrator to set your compliance status.

**What it means:** The user hasn't been set as compliant in the BrevisVerifier contract.

**What to do:**
1. Contact an administrator to set your compliance status
2. Or run: `forge script script/InteractWithContracts.s.sol --rpc-url http://localhost:8545 --broadcast`

---

### InvalidProof (`0x09bde339`)
**Message:** ❌ The proof is invalid. Please generate a new proof.

**What it means:** The proof doesn't match the expected compliance data hash.

**What to do:**
1. Generate a new proof using the "Generate Proof" button
2. Make sure you're using the correct account

---

### ProofAlreadyUsed (`0xc9838a65`)
**Message:** ⚠️ This proof has already been used. Please generate a new proof.

**What it means:** This proof hash was already submitted and marked as used (replay protection).

**What to do:**
1. Generate a new proof using the "Generate Proof" button
2. Submit the new proof

---

### ProofExpired (`0xb67a7713`)
**Message:** ⏰ This proof has expired. Please generate a new proof.

**What it means:** The proof timestamp is older than the expiration period (30 days).

**What to do:**
1. Generate a new proof (proofs expire after 30 days)
2. Submit the new proof

---

### HookNotEnabled (`0x7e5ba1ad`)
**Message:** 🔒 The compliance hook is currently disabled.

**What it means:** The hook admin has disabled the compliance checks.

**What to do:**
1. Contact the hook administrator
2. Wait for the hook to be re-enabled

---

### InvalidComplianceData (`0xea2e0857`)
**Message:** ❌ Invalid compliance data provided.

**What it means:** The compliance data structure is invalid.

**What to do:**
1. Check your input data
2. Try generating a new proof

---

### Unauthorized (`0x82b42900`)
**Message:** 🚫 You are not authorized to perform this action.

**What it means:** You're trying to perform an admin-only action.

**What to do:**
1. This action requires admin privileges
2. Contact the contract administrator

---

## Common Errors

### Insufficient Funds
**Message:** 💰 Insufficient funds. Please add more ETH to your wallet.

**What to do:**
1. Add ETH to your wallet
2. Check your wallet balance

---

### Transaction Rejected
**Message:** ❌ Transaction was rejected. Please approve the transaction in MetaMask.

**What to do:**
1. Check MetaMask for pending transactions
2. Approve the transaction when prompted

---

### Transaction Reverted
**Message:** ❌ Transaction was reverted. Please check your inputs and try again.

**What to do:**
1. Verify all inputs are correct
2. Check if you meet all requirements
3. Try again

---

## How It Works

### Error Decoder (`frontend/src/utils/errorDecoder.ts`)

The error decoder:
1. Extracts error data from ethers error objects
2. Maps error selectors to friendly messages
3. Provides actionable help text

### Usage in Components

```typescript
import { getErrorMessage, getErrorHelp } from '../utils/errorDecoder'

try {
  // ... transaction code
} catch (err: any) {
  const friendlyError = getErrorMessage(err)
  setError(friendlyError)
  
  // Show help if available
  const help = getErrorHelp(err)
  // ... display help
}
```

---

## Testing

To test error messages:

1. Try submitting a proof without being marked as compliant → Should show "UserNotCompliant"
2. Try using the same proof twice → Should show "ProofAlreadyUsed"
3. Try with insufficient funds → Should show "Insufficient funds"

---

## Adding New Errors

To add a new error:

1. **Get the error selector:**
   ```bash
   cast sig "YourError()"
   ```

2. **Add to `ERROR_SELECTORS`:**
   ```typescript
   '0x...': 'YourError',
   ```

3. **Add friendly message to `ERROR_MESSAGES`:**
   ```typescript
   YourError: '❌ Your friendly message here.',
   ```

4. **Add help text in `getErrorHelp()`:**
   ```typescript
   if (errorMsg.includes('your error pattern')) {
     help.push('1. First step to fix')
     help.push('2. Second step to fix')
   }
   ```

---

## Summary

✅ **Before:** `Error: execution reverted (unknown custom error) (action="estimateGas", data="0xadcd8b60"...)`

✅ **After:** `❌ You are not marked as compliant. Please contact an administrator to set your compliance status.`

**Much better!** 🎉

