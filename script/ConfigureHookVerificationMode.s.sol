// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {ZKProofOfComplianceFull} from "../src/hooks/ZKProofOfComplianceFull.sol";

/// @title ConfigureHookVerificationMode
/// @notice Script to configure the hook's verification mode to BrevisOnly
contract ConfigureHookVerificationMode is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Get hook address from .env (ZKProofOfComplianceFull used by Dashboard)
        address hookAddress = vm.envOr("HOOK_ADDRESS", address(0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9));
        ZKProofOfComplianceFull hook = ZKProofOfComplianceFull(hookAddress);

        console.log("========================================");
        console.log("Configure Hook Verification Mode");
        console.log("========================================");
        console.log("");
        console.log("Hook Address:", address(hook));
        console.log("");

        // Get current verification mode
        ZKProofOfComplianceFull.VerificationMode currentMode = hook.verificationMode();
        console.log("Current Verification Mode:", uint8(currentMode));
        console.log("");

        // Set to BrevisOnly mode (mode 0)
        console.log("Setting verification mode to BrevisOnly...");
        hook.setVerificationMode(ZKProofOfComplianceFull.VerificationMode.BrevisOnly);
        console.log("Verification mode updated!");
        console.log("");

        // Verify the change
        ZKProofOfComplianceFull.VerificationMode newMode = hook.verificationMode();
        console.log("New Verification Mode:", uint8(newMode));
        console.log("");

        if (newMode == ZKProofOfComplianceFull.VerificationMode.BrevisOnly) {
            console.log("SUCCESS: Hook is now configured to use BrevisOnly verification");
            console.log("   Proof generation should work now");
        } else {
            console.log("ERROR: Failed to set verification mode");
        }

        vm.stopBroadcast();
    }
}

