// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {ZKProofOfCompliance} from "../src/hooks/ZKProofOfCompliance.sol";
import {BrevisVerifier} from "../src/verifiers/BrevisVerifier.sol";
import {ComplianceData} from "../src/libraries/ComplianceData.sol";
import {IBrevisVerifier} from "../src/interfaces/IBrevisVerifier.sol";

/// @title DiagnoseIssueScript
/// @notice Script to diagnose why verifyProof fails when called from hook
contract DiagnoseIssueScript is Script {
    address constant BREVIS_VERIFIER = address(0x5FbDB2315678afecb367f032d93F642f64180aa3);
    address constant HOOK = address(0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512);

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        vm.startBroadcast(deployerPrivateKey);

        BrevisVerifier verifier = BrevisVerifier(BREVIS_VERIFIER);
        ZKProofOfCompliance hook = ZKProofOfCompliance(HOOK);

        console.log("=== Diagnosis ===");
        console.log("Deployer:", deployer);
        console.log("Verifier address:", address(verifier));
        console.log("Hook address:", address(hook));
        console.log("Hook's verifier:", address(hook.brevisVerifier()));
        console.log("");

        // Check if hook is using correct verifier
        if (address(hook.brevisVerifier()) != address(verifier)) {
            console.log("ERROR: Hook is using different verifier!");
            console.log("  Expected:", address(verifier));
            console.log("  Actual:", address(hook.brevisVerifier()));
            return;
        }
        console.log("Hook verifier matches: OK");
        console.log("");

        // Set deployer as compliant
        IBrevisVerifier.ComplianceData memory compliantData = ComplianceData.createCompliantData();
        bytes32 dataHash = ComplianceData.hashComplianceData(compliantData);
        
        verifier.setUserCompliance(deployer, true, dataHash);
        console.log("Deployer set as compliant");
        console.log("Data hash:", vm.toString(dataHash));
        console.log("");

        // Verify state
        bytes32 storedHash = verifier.getUserComplianceHash(deployer);
        bool isCompliant = verifier.isUserCompliant(deployer);
        console.log("Verifier state:");
        console.log("  Stored hash:", vm.toString(storedHash));
        console.log("  Is compliant:", isCompliant);
        console.log("");

        // Create proof
        bytes32 proofHash = keccak256(abi.encodePacked(deployer, dataHash, block.timestamp, block.number, "diagnosis"));
        IBrevisVerifier.ComplianceProof memory proof = IBrevisVerifier.ComplianceProof({
            proofHash: proofHash,
            publicInputs: abi.encode(dataHash),
            timestamp: block.timestamp,
            user: deployer
        });

        console.log("Proof:");
        console.log("  Hash:", vm.toString(proofHash));
        console.log("  User:", proof.user);
        console.log("  Timestamp:", proof.timestamp);
        console.log("");

        // Test direct verification
        console.log("=== Direct Verification ===");
        bytes32 expectedHash = verifier.getUserComplianceHash(deployer);
        console.log("Expected hash:", vm.toString(expectedHash));
        
        (bool isValid, bytes32 verifiedHash) = verifier.verifyProof(proof, expectedHash);
        console.log("Result:");
        console.log("  Valid:", isValid);
        console.log("  Hash:", vm.toString(verifiedHash));
        console.log("");

        // Test hook's getUserComplianceHash
        console.log("=== Hook's getUserComplianceHash ===");
        bytes32 hookExpectedHash = hook.brevisVerifier().getUserComplianceHash(deployer);
        console.log("Hook's expected hash:", vm.toString(hookExpectedHash));
        console.log("");

        // Test hook's verifyProof (simulate what hook does)
        console.log("=== Hook's verifyProof (simulated) ===");
        (bool hookIsValid, bytes32 hookVerifiedHash) = hook.brevisVerifier().verifyProof(proof, hookExpectedHash);
        console.log("Result:");
        console.log("  Valid:", hookIsValid);
        console.log("  Hash:", vm.toString(hookVerifiedHash));
        console.log("");

        if (isValid && !hookIsValid) {
            console.log("ISSUE FOUND: Direct call works but hook's call fails!");
            console.log("This suggests a state difference or execution context issue.");
        } else if (isValid && hookIsValid) {
            console.log("Both calls work - issue might be in submitProof logic");
        }

        vm.stopBroadcast();
    }
}

