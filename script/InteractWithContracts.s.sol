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
    address constant BREVIS_VERIFIER = address(0x0165878A594ca255338adfa4d48449f69242Eb8F);
    address constant HOOK = address(0xa513E6E4b8f2a923D98304ec87F64353C4D5C853);

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

        // Set deployer as compliant too (since we're submitting from deployer account)
        address deployer = vm.addr(deployerPrivateKey);
        verifier.setUserCompliance(deployer, true, dataHash);
        console.log("Deployer set as compliant:", deployer);
        console.log("");

        // Verify deployer is compliant
        bool deployerCompliant = hook.isUserCompliant(deployer);
        console.log("Deployer compliance check:", deployerCompliant);
        console.log("");

        // Create a proof for the deployer
        // Use a unique nonce to ensure the proof hash is always unique
        uint256 nonce = block.timestamp + block.number + uint256(uint160(deployer));
        bytes32 proofHash = keccak256(abi.encodePacked(deployer, dataHash, nonce, "unique-proof"));
        IBrevisVerifier.ComplianceProof memory proof = IBrevisVerifier.ComplianceProof({
            proofHash: proofHash,
            publicInputs: abi.encode(dataHash),
            timestamp: block.timestamp,
            user: deployer
        });

        console.log("Proof Created:");
        console.log("  Proof Hash:", vm.toString(proof.proofHash));
        console.log("  User:", proof.user);
        console.log("  Timestamp:", proof.timestamp);
        console.log("  Expected Data Hash:", vm.toString(dataHash));
        console.log("");

        // Verify proof before submitting (test the verifier)
        bytes32 expectedHash = verifier.getUserComplianceHash(deployer);
        console.log("Expected compliance hash from verifier:", vm.toString(expectedHash));
        
        // Check if proof is already used in verifier
        bool verifierProofUsed = verifier.isProofUsed(proof.proofHash);
        console.log("Proof already used in verifier:", verifierProofUsed);
        
        (bool isValid, bytes32 verifiedHash) = verifier.verifyProof(proof, expectedHash);
        console.log("Proof verification result (direct call):");
        console.log("  Is Valid:", isValid);
        console.log("  Verified Hash:", vm.toString(verifiedHash));
        console.log("");

        // Submit proof through hook
        console.log("Submitting proof through hook...");
        try hook.submitProof(proof) {
            console.log("  Proof submitted successfully!");
            console.log("");

            // Verify proof was recorded
            bool proofUsed = hook.isProofUsed(proof.proofHash);
            bytes32 userHash = hook.userComplianceHashes(deployer);
            console.log("Verification:");
            console.log("  Proof used in hook:", proofUsed);
            console.log("  User compliance hash:", vm.toString(userHash));
            console.log("");
        } catch Error(string memory reason) {
            console.log("  Error:", reason);
        } catch (bytes memory lowLevelData) {
            console.log("  Low-level error occurred");
        }

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

