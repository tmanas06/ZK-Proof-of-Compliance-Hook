# Step-by-Step Deployment Guide

This guide walks you through deploying all contracts in the correct order and updating your `.env` file.

## Prerequisites

1. ✅ `.env` file set up (see `docs/ENV_SETUP_ENHANCED.md`)
2. ✅ Foundry installed and configured
3. ✅ Local node running (Anvil) or RPC URL configured
4. ✅ Sufficient funds in deployment account

## Deployment Order

### Step 1: Deploy Groth16 Verifier Contract

**What:** The zk-SNARK verifier contract generated from your Circom circuit.

**How:**

1. **Generate the verifier contract:**
   ```bash
   # Compile circuit
   circom circuits/compliance.circom --r1cs --wasm --sym
   
   # Generate trusted setup (powers of tau)
   snarkjs powersoftau new bn128 14 pot14_0000.ptau -v
   snarkjs powersoftau contribute pot14_0000.ptau pot14_0001.ptau --name="First contribution" -v
   snarkjs powersoftau prepare phase2 pot14_0001.ptau pot14_final.ptau -v
   
   # Generate proving key
   snarkjs groth16 setup compliance.r1cs pot14_final.ptau compliance_0000.zkey
   snarkjs zkey contribute compliance_0000.zkey compliance_0001.zkey --name="Second contribution" -v
   
   # Generate verifier contract
   snarkjs zkey export solidityverifier compliance_0001.zkey verifier.sol
   ```

2. **Deploy the verifier:**
   - Open `verifier.sol` (or `Groth16Verifier.sol`) in Remix, Hardhat, or Foundry
   - Deploy to your chain
   - Copy the deployed address

3. **Update .env:**
   ```bash
   GROTH16_VERIFIER_ADDRESS=0xYourDeployedVerifierAddress
   ```

---

### Step 2: Deploy RealBrevisVerifier

**What:** The Brevis verifier contract that uses the Groth16 verifier.

**How:**

1. **Deploy using Foundry:**
   ```bash
   # Create deployment script (or use existing)
   forge script script/DeployBrevisVerifier.s.sol --rpc-url $LOCAL_RPC_URL --broadcast
   ```

2. **Or deploy manually:**
   ```solidity
   // In Remix or Foundry console
   Groth16Verifier verifier = Groth16Verifier(0xYourGroth16VerifierAddress);
   RealBrevisVerifier brevisVerifier = new RealBrevisVerifier(address(verifier));
   ```

3. **Update .env:**
   ```bash
   BREVIS_VERIFIER_ADDRESS=0xYourBrevisVerifierAddress
   ```

---

### Step 3: Deploy EigenLayer AVS

**What:** Your EigenLayer Actively Validated Service for off-chain verification.

**Option A: Use EigenLayer Template**

1. **Clone EigenLayer contracts:**
   ```bash
   git clone https://github.com/Layr-Labs/eigenlayer-contracts
   cd eigenlayer-contracts
   ```

2. **Deploy AVS contracts:**
   - Deploy `ServiceManager`
   - Deploy `Registry`
   - Set up operators

3. **Update .env:**
   ```bash
   EIGENLAYER_AVS_ADDRESS=0xYourServiceManagerAddress
   ```

**Option B: Use RealEigenLayerAVS**

1. **Deploy using Foundry:**
   ```bash
   # Create deployment script
   forge script script/DeployEigenLayerAVS.s.sol --rpc-url $LOCAL_RPC_URL --broadcast
   ```

2. **Update .env:**
   ```bash
   EIGENLAYER_AVS_ADDRESS=0xYourEigenLayerAVSAddress
   ```

---

### Step 4: Deploy RealFhenixFHE (Optional)

**What:** Wrapper contract for Fhenix FHE integration.

**Note:** If using Fhenix's official contracts directly, you can skip this and use `FHENIX_FHE_ADDRESS` from Fhenix docs.

**How:**

1. **Get Fhenix official FHE address:**
   - Visit: https://docs.fhenix.io
   - Find official FHE contract address
   - Or use Fhenix testnet address

2. **Deploy RealFhenixFHE (if using wrapper):**
   ```bash
   forge script script/DeployFhenixFHE.s.sol --rpc-url $LOCAL_RPC_URL --broadcast
   ```

3. **Update .env:**
   ```bash
   # Option 1: Use Fhenix official contract
   FHENIX_FHE_ADDRESS=0xFhenixOfficialContractAddress
   
   # Option 2: Use your wrapper contract
   FHENIX_FHE_ADDRESS=0xYourRealFhenixFHEAddress
   ```

---

### Step 5: Deploy Fhenix Service (Optional)

**What:** External service contract for off-chain FHE computation.

**⚠️ Only needed if building external FHE processing service.**

**How:**

1. **Build your service contract:**
   - Contract that receives encrypted data
   - Processes using FHE (off-chain)
   - Submits results on-chain

2. **Deploy the service:**
   ```bash
   forge script script/DeployFhenixService.s.sol --rpc-url $LOCAL_RPC_URL --broadcast
   ```

3. **Update .env:**
   ```bash
   FHENIX_SERVICE_ADDRESS=0xYourServiceAddress
   ```

**If not building external service:**
- Leave as `0x0`

---

### Step 6: Deploy ZKProofOfComplianceFull Hook

**What:** Your main Uniswap v4 compliance hook contract.

**How:**

1. **Deploy using Foundry:**
   ```bash
   forge script script/DeployFullHook.s.sol --rpc-url $LOCAL_RPC_URL --broadcast
   ```

2. **Or deploy manually:**
   ```solidity
   // Set up requirements
   ComplianceRequirements memory requirements = ComplianceRequirements({
       requireKYC: true,
       requireAgeVerification: true,
       requireLocationCheck: true,
       requireSanctionsCheck: true,
       minAge: 18
   });
   
   // Deploy hook
   ZKProofOfComplianceFull hook = new ZKProofOfComplianceFull(
       poolManager,
       brevisVerifier,
       eigenLayerAVS,
       fhenixFHE,
       requirements,
       VerificationMode.BrevisOnly, // or your preferred mode
       true // allowFallback
   );
   ```

3. **Update .env:**
   ```bash
   HOOK_ADDRESS=0xYourHookAddress
   ```

---

## Complete Deployment Script Example

Create `script/DeployAll.s.sol`:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {RealBrevisVerifier} from "../src/verifiers/RealBrevisVerifier.sol";
import {RealEigenLayerAVS} from "../src/services/RealEigenLayerAVS.sol";
import {RealFhenixFHE} from "../src/services/RealFhenixFHE.sol";
import {ZKProofOfComplianceFull} from "../src/hooks/ZKProofOfComplianceFull.sol";
import {IPoolManager} from "../src/interfaces/IPoolManager.sol";

contract DeployAllScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Step 1: Deploy RealBrevisVerifier
        address groth16Verifier = vm.envAddress("GROTH16_VERIFIER_ADDRESS");
        require(groth16Verifier != address(0), "GROTH16_VERIFIER_ADDRESS not set");
        
        console.log("Deploying RealBrevisVerifier...");
        RealBrevisVerifier brevisVerifier = new RealBrevisVerifier(groth16Verifier);
        console.log("RealBrevisVerifier:", address(brevisVerifier));

        // Step 2: Deploy RealEigenLayerAVS
        string memory operatorsStr = vm.envString("EIGENLAYER_OPERATORS");
        // Parse operators (simplified - you'd need proper parsing)
        address[] memory operators = new address[](2);
        operators[0] = address(0x70997970C51812dc3A010C7d01b50e0d17dc79C8);
        operators[1] = address(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC);
        
        uint256 minConfirmations = vm.envUint("EIGENLAYER_MIN_CONFIRMATIONS");
        uint256 timeout = vm.envUint("EIGENLAYER_TIMEOUT");
        uint256 maxRetries = vm.envUint("EIGENLAYER_MAX_RETRIES");
        uint256 retryDelay = vm.envUint("EIGENLAYER_RETRY_DELAY");
        
        console.log("Deploying RealEigenLayerAVS...");
        RealEigenLayerAVS eigenLayerAVS = new RealEigenLayerAVS(
            operators,
            minConfirmations,
            timeout,
            maxRetries,
            retryDelay
        );
        console.log("RealEigenLayerAVS:", address(eigenLayerAVS));

        // Step 3: Deploy RealFhenixFHE
        address fhenixService = vm.envAddress("FHENIX_SERVICE_ADDRESS");
        console.log("Deploying RealFhenixFHE...");
        RealFhenixFHE fhenixFHE = new RealFhenixFHE(fhenixService);
        console.log("RealFhenixFHE:", address(fhenixFHE));

        // Step 4: Deploy ZKProofOfComplianceFull
        IPoolManager poolManager = IPoolManager(vm.envAddress("POOL_MANAGER_ADDRESS"));
        
        ZKProofOfComplianceFull.ComplianceRequirements memory requirements = 
            ZKProofOfComplianceFull.ComplianceRequirements({
                requireKYC: true,
                requireAgeVerification: true,
                requireLocationCheck: true,
                requireSanctionsCheck: true,
                minAge: 18
            });
        
        uint256 mode = vm.envUint("VERIFICATION_MODE");
        bool allowFallback = vm.envBool("ALLOW_FALLBACK");
        
        console.log("Deploying ZKProofOfComplianceFull...");
        ZKProofOfComplianceFull hook = new ZKProofOfComplianceFull(
            poolManager,
            brevisVerifier,
            eigenLayerAVS,
            fhenixFHE,
            requirements,
            ZKProofOfComplianceFull.VerificationMode(mode),
            allowFallback
        );
        console.log("ZKProofOfComplianceFull:", address(hook));

        console.log("\n=== Deployment Complete ===");
        console.log("Update your .env file with these addresses:");
        console.log("BREVIS_VERIFIER_ADDRESS=", address(brevisVerifier));
        console.log("EIGENLAYER_AVS_ADDRESS=", address(eigenLayerAVS));
        console.log("FHENIX_FHE_ADDRESS=", address(fhenixFHE));
        console.log("HOOK_ADDRESS=", address(hook));

        vm.stopBroadcast();
    }
}
```

Run it:
```bash
forge script script/DeployAll.s.sol --rpc-url $LOCAL_RPC_URL --broadcast
```

---

## Verification Checklist

After deployment, verify:

- [ ] All contracts deployed successfully
- [ ] All addresses updated in `.env`
- [ ] Contracts verified on block explorer (if applicable)
- [ ] Test basic functionality
- [ ] Check contract interactions

---

## Next Steps

1. **Update frontend** with deployed addresses
2. **Test verification workflows**
3. **Configure operators** (for EigenLayer)
4. **Set up monitoring** and alerts

---

## Troubleshooting

### "Address not set" error
- Make sure all required addresses are in `.env`
- Check variable names (case-sensitive)
- Verify addresses are valid (start with `0x`, 42 chars)

### "Insufficient funds" error
- Ensure deployment account has enough ETH
- For local testing, use Anvil's pre-funded account

### "Contract not found" error
- Verify contract files exist
- Check import paths
- Run `forge build` first

---

## Additional Resources

- [ENV_SETUP_ENHANCED.md](./ENV_SETUP_ENHANCED.md) - Environment variable details
- [REAL_INTEGRATIONS.md](./REAL_INTEGRATIONS.md) - Integration guide
- [EigenLayer Documentation](https://docs.eigenlayer.xyz/)
- [Fhenix Documentation](https://docs.fhenix.io/)

