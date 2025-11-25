// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {RealBrevisVerifier} from "../src/verifiers/RealBrevisVerifier.sol";
import {ZKProofOfComplianceFull} from "../src/hooks/ZKProofOfComplianceFull.sol";

/// @title SetUserCompliantEnhanced
/// @notice Script to set a user as compliant for testing the enhanced system
contract SetUserCompliantEnhanced is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address brevisVerifier = vm.envAddress("BREVIS_VERIFIER_ADDRESS");
        RealBrevisVerifier verifier = RealBrevisVerifier(brevisVerifier);

        // User address from the frontend (0x70997970C51812dc3A010C7d01b50e0d17dc79C8)
        address testUser = address(0x70997970C51812dc3A010C7d01b50e0d17dc79C8);
        
        console.log("========================================");
        console.log("Setting User as Compliant");
        console.log("========================================");
        console.log("User address:", testUser);
        console.log("");

        // Create a compliance data hash
        // In production, this would be computed from actual compliance data
        // For testing, we'll create a hash that represents compliant status
        bytes2 countryCode = bytes2("US");
        bytes32 complianceHash = keccak256(
            abi.encodePacked(
                testUser,
                true,  // KYC passed
                uint256(25),    // Age
                countryCode,  // Country code
                false, // Not sanctioned
                block.timestamp
            )
        );

        // Set user as compliant
        verifier.setUserCompliance(testUser, true, complianceHash);
        console.log("[SUCCESS] User set as compliant");
        console.log("Compliance hash:", vm.toString(complianceHash));
        console.log("");

        // Verify the user is now compliant
        bool isCompliant = verifier.isUserCompliant(testUser);
        bytes32 storedHash = verifier.getUserComplianceHash(testUser);
        
        console.log("Verification:");
        console.log("  Is compliant:", isCompliant ? "YES" : "NO");
        console.log("  Stored hash:", vm.toString(storedHash));
        console.log("");

        // Also set the hash in the hook if needed
        address hookAddress = vm.envAddress("HOOK_ADDRESS");
        ZKProofOfComplianceFull hook = ZKProofOfComplianceFull(hookAddress);
        
        // The hook will read from the verifier, so this should work
        bytes32 hookHash = hook.userComplianceHashes(testUser);
        console.log("Hook status:");
        console.log("  User hash in hook:", vm.toString(hookHash));
        console.log("");

        console.log("========================================");
        console.log("[SUCCESS] User is now compliant!");
        console.log("You can now generate and submit proofs.");
        console.log("========================================");

        vm.stopBroadcast();
    }
}

