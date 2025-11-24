// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {ZKProofOfCompliance} from "../src/hooks/ZKProofOfCompliance.sol";
import {BrevisVerifier} from "../src/verifiers/BrevisVerifier.sol";
import {ComplianceData} from "../src/libraries/ComplianceData.sol";
import {IBrevisVerifier} from "../src/interfaces/IBrevisVerifier.sol";

/// @title InteractWithContractsScript
/// @notice Script to interact with deployed contracts for testing
/// @dev Update addresses after deployment
contract InteractWithContractsScript is Script {
    // Update these addresses after deployment
    address constant BREVIS_VERIFIER = address(0x5FbDB2315678afecb367f032d93F642f64180aa3);
    address constant HOOK = address(0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512);

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        BrevisVerifier verifier = BrevisVerifier(BREVIS_VERIFIER);
        ZKProofOfCompliance hook = ZKProofOfCompliance(HOOK);

        console.log("========================================");
        console.log("Contract Interaction Script");
        console.log("========================================");
        console.log("");

        // Check hook status
        console.log("Hook Status:");
        console.log("  Enabled:", hook.enabled());
        console.log("  Admin:", hook.admin());
        console.log("");

        // Create test user
        address testUser = address(0x70997970C51812dc3A010C7d01b50e0d17dc79C8);
        console.log("Setting up test user:", testUser);

        // Create compliance data
        IBrevisVerifier.ComplianceData memory compliantData = ComplianceData.createCompliantData();
        bytes32 dataHash = ComplianceData.hashComplianceData(compliantData);

        // Set user as compliant
        verifier.setUserCompliance(testUser, true, dataHash);
        console.log("  User set as compliant");
        console.log("  Compliance hash:", vm.toString(dataHash));
        console.log("");

        // Check user compliance
        bool isCompliant = hook.isUserCompliant(testUser);
        console.log("User Compliance Check:");
        console.log("  Is Compliant:", isCompliant);
        console.log("");

        // Create a proof
        IBrevisVerifier.ComplianceProof memory proof = IBrevisVerifier.ComplianceProof({
            proofHash: keccak256(abi.encodePacked(testUser, dataHash, block.timestamp)),
            publicInputs: abi.encode(dataHash),
            timestamp: block.timestamp,
            user: testUser
        });

        console.log("Proof Created:");
        console.log("  Proof Hash:", vm.toString(proof.proofHash));
        console.log("  User:", proof.user);
        console.log("  Timestamp:", proof.timestamp);
        console.log("");

        // Submit proof
        console.log("Submitting proof...");
        hook.submitProof(proof);
        console.log("  Proof submitted successfully!");
        console.log("");

        // Verify proof was recorded
        bool proofUsed = hook.isProofUsed(proof.proofHash);
        bytes32 userHash = hook.userComplianceHashes(testUser);
        console.log("Verification:");
        console.log("  Proof used:", proofUsed);
        console.log("  User compliance hash:", vm.toString(userHash));
        console.log("");

        console.log("========================================");
        console.log("Interaction Complete!");
        console.log("========================================");

        vm.stopBroadcast();
    }
}

