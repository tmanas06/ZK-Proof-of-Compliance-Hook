// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {RealBrevisVerifier} from "../src/verifiers/RealBrevisVerifier.sol";

/// @title SetUserCompliantForDashboard
/// @notice Script to set a test user as compliant for the Dashboard
/// @dev This sets the user in RealBrevisVerifier which is used by ZKProofOfComplianceFull
contract SetUserCompliantForDashboard is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Get verifier address from .env (RealBrevisVerifier used by Dashboard)
        // Default to the address used by the Dashboard frontend
        address verifierAddress = vm.envOr("VERIFIER_ADDRESS", address(0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512));
        RealBrevisVerifier verifier = RealBrevisVerifier(verifierAddress);

        console.log("========================================");
        console.log("Set User Compliant for Dashboard");
        console.log("========================================");
        console.log("");
        console.log("Verifier Address:", address(verifier));
        console.log("");

        // Test user (the one connected in MetaMask - second Anvil account)
        address testUser = address(0x70997970C51812dc3A010C7d01b50e0d17dc79C8);
        console.log("Setting up test user:", testUser);
        console.log("");

        // Create a compliance hash for the user
        // In production, this would come from actual compliance data
        bytes32 complianceHash = keccak256(
            abi.encodePacked(
                testUser,
                true,  // kycPassed
                true,  // ageVerified
                true,  // locationAllowed
                true,  // notSanctioned
                uint256(25), // age
                "US"   // countryCode
            )
        );

        // Set user as compliant
        verifier.setUserCompliance(testUser, true, complianceHash);
        console.log("User set as compliant");
        console.log("  User:", testUser);
        console.log("  Compliance Hash:", vm.toString(complianceHash));
        console.log("");

        // Verify the user is now compliant
        bool isCompliant = verifier.isUserCompliant(testUser);
        bytes32 storedHash = verifier.getUserComplianceHash(testUser);
        
        console.log("Verification:");
        console.log("  Is Compliant:", isCompliant);
        console.log("  Stored Hash:", vm.toString(storedHash));
        console.log("");

        if (isCompliant && storedHash == complianceHash) {
            console.log("SUCCESS: User is now compliant!");
            console.log("   You can now generate proofs in the Dashboard");
        } else {
            console.log("ERROR: User compliance setup failed");
        }

        vm.stopBroadcast();
    }
}

