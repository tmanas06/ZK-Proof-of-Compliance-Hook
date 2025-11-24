// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {ZKProofOfCompliance} from "../src/hooks/ZKProofOfCompliance.sol";
import {BrevisVerifier} from "../src/verifiers/BrevisVerifier.sol";
import {ComplianceData} from "../src/libraries/ComplianceData.sol";
import {IBrevisVerifier} from "../src/interfaces/IBrevisVerifier.sol";

/// @title SimpleTestScript
/// @notice Simple test to verify the hook works
contract SimpleTestScript is Script {
    address constant BREVIS_VERIFIER = address(0x0165878A594ca255338adfa4d48449f69242Eb8F);
    address constant HOOK = address(0xa513E6E4b8f2a923D98304ec87F64353C4D5C853);

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        vm.startBroadcast(deployerPrivateKey);

        BrevisVerifier verifier = BrevisVerifier(BREVIS_VERIFIER);
        ZKProofOfCompliance hook = ZKProofOfCompliance(HOOK);

        console.log("=== Simple Hook Test ===");
        console.log("Deployer:", deployer);
        console.log("");

        // Set deployer as compliant
        IBrevisVerifier.ComplianceData memory compliantData = ComplianceData.createCompliantData();
        bytes32 dataHash = ComplianceData.hashComplianceData(compliantData);
        
        verifier.setUserCompliance(deployer, true, dataHash);
        console.log("Deployer set as compliant");
        console.log("Data hash:", vm.toString(dataHash));
        console.log("");

        // Create proof
        bytes32 proofHash = keccak256(abi.encodePacked(deployer, dataHash, block.timestamp, block.number));
        IBrevisVerifier.ComplianceProof memory proof = IBrevisVerifier.ComplianceProof({
            proofHash: proofHash,
            publicInputs: abi.encode(dataHash),
            timestamp: block.timestamp,
            user: deployer
        });

        console.log("Proof created:");
        console.log("  Hash:", vm.toString(proofHash));
        console.log("  User:", proof.user);
        console.log("");

        // Verify directly
        bytes32 expectedHash = verifier.getUserComplianceHash(deployer);
        (bool isValid, bytes32 verifiedHash) = verifier.verifyProof(proof, expectedHash);
        console.log("Direct verification:");
        console.log("  Valid:", isValid);
        console.log("  Hash:", vm.toString(verifiedHash));
        console.log("");

        if (isValid) {
            // Try submitting through hook
            console.log("Submitting through hook...");
            hook.submitProof(proof);
            console.log("Success! Proof submitted.");
            console.log("");
            
            // Check result
            bool proofUsed = hook.isProofUsed(proofHash);
            bytes32 userHash = hook.userComplianceHashes(deployer);
            console.log("Result:");
            console.log("  Proof used:", proofUsed);
            console.log("  User hash:", vm.toString(userHash));
        } else {
            console.log("Direct verification failed, skipping hook submission");
        }

        vm.stopBroadcast();
    }
}

