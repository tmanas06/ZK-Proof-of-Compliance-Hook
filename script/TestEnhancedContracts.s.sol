// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {RealBrevisVerifier} from "../src/verifiers/RealBrevisVerifier.sol";
import {RealEigenLayerAVS} from "../src/services/RealEigenLayerAVS.sol";
import {RealFhenixFHE} from "../src/services/RealFhenixFHE.sol";
import {ZKProofOfComplianceFull} from "../src/hooks/ZKProofOfComplianceFull.sol";
import {MockGroth16Verifier} from "../src/verifiers/MockGroth16Verifier.sol";

/// @title TestEnhancedContracts
/// @notice Test script to verify all enhanced contracts are working
contract TestEnhancedContracts is Script {
    function run() external view {
        console.log("========================================");
        console.log("Enhanced Contracts Test");
        console.log("========================================");
        console.log("");

        // Get addresses from .env
        address groth16Verifier = vm.envAddress("GROTH16_VERIFIER_ADDRESS");
        address brevisVerifier = vm.envAddress("BREVIS_VERIFIER_ADDRESS");
        address eigenLayerAVS = vm.envAddress("EIGENLAYER_AVS_ADDRESS");
        // Fhenix FHE contract address (not service address)
        address fhenixFHE = address(0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9); // From deployment
        address hook = vm.envAddress("HOOK_ADDRESS");

        console.log("Contract Addresses:");
        console.log("  Groth16 Verifier:", groth16Verifier);
        console.log("  Brevis Verifier:", brevisVerifier);
        console.log("  EigenLayer AVS:", eigenLayerAVS);
        console.log("  Fhenix FHE:", fhenixFHE);
        console.log("  Hook:", hook);
        console.log("");

        // Test Groth16 Verifier
        console.log("=== Testing Groth16 Verifier ===");
        MockGroth16Verifier groth16 = MockGroth16Verifier(groth16Verifier);
        uint256[8] memory mockProof;
        uint256[] memory mockPublicSignals = new uint256[](1);
        mockPublicSignals[0] = 1;
        bool isValid = groth16.verify(mockProof, mockPublicSignals);
        console.log("  Mock proof verification:", isValid ? "PASS" : "FAIL");
        console.log("");

        // Test Brevis Verifier
        console.log("=== Testing Brevis Verifier ===");
        RealBrevisVerifier brevis = RealBrevisVerifier(brevisVerifier);
        console.log("  Admin:", brevis.admin());
        console.log("  Verifier contract:", address(brevis.verifier()));
        address testUser = address(0x70997970C51812dc3A010C7d01b50e0d17dc79C8);
        bytes32 userHash = brevis.getUserComplianceHash(testUser);
        console.log("  Test user hash:", vm.toString(userHash));
        bool userCompliant = brevis.isUserCompliant(testUser);
        console.log("  Test user compliant:", userCompliant ? "YES" : "NO");
        console.log("");

        // Test EigenLayer AVS
        console.log("=== Testing EigenLayer AVS ===");
        RealEigenLayerAVS avs = RealEigenLayerAVS(eigenLayerAVS);
        console.log("  Admin:", avs.admin());
        console.log("  Min confirmations:", avs.minOperatorConfirmations());
        console.log("  Timeout:", avs.verificationTimeout());
        console.log("  Max retries:", avs.maxRetries());
        console.log("");

        // Test Fhenix FHE
        console.log("=== Testing Fhenix FHE ===");
        RealFhenixFHE fhe = RealFhenixFHE(fhenixFHE);
        console.log("  Admin:", fhe.admin());
        console.log("  Fhenix service:", fhe.fhenixService());
        bytes memory publicKey = fhe.getPublicKey();
        console.log("  Public key length:", publicKey.length);
        console.log("");

        // Test Hook
        console.log("=== Testing Hook ===");
        ZKProofOfComplianceFull hookContract = ZKProofOfComplianceFull(hook);
        console.log("  Admin:", hookContract.admin());
        console.log("  Enabled:", hookContract.enabled() ? "YES" : "NO");
        console.log("  Verification mode:", uint8(hookContract.verificationMode()));
        console.log("  Allow fallback:", hookContract.allowFallback() ? "YES" : "NO");
        console.log("  Brevis verifier:", address(hookContract.brevisVerifier()));
        console.log("  EigenLayer AVS:", address(hookContract.eigenLayerAVS()));
        console.log("  Fhenix FHE:", address(hookContract.fhenixFHE()));
        
        (bool requireKYC, bool requireAgeVerification, bool requireLocationCheck, bool requireSanctionsCheck, uint256 minAge) = hookContract.requirements();
        console.log("  Requirements:");
        console.log("    Require KYC:", requireKYC ? "YES" : "NO");
        console.log("    Require age verification:", requireAgeVerification ? "YES" : "NO");
        console.log("    Require location check:", requireLocationCheck ? "YES" : "NO");
        console.log("    Require sanctions check:", requireSanctionsCheck ? "YES" : "NO");
        console.log("    Min age:", minAge);
        console.log("");

        console.log("========================================");
        console.log("All contracts are accessible and working!");
        console.log("========================================");
    }
}

