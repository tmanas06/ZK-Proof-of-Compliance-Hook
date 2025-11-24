// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";

/// @title CheckEnvScript
/// @notice Simple script to check environment variables without RPC connection
/// @dev Run this to verify your .env file is set up correctly
contract CheckEnvScript is Script {
    function run() external view {
        console.log("========================================");
        console.log("Environment Variables Check");
        console.log("========================================");
        console.log("");

        uint256 errors = 0;
        uint256 warnings = 0;

        // Test PRIVATE_KEY
        try vm.envUint("PRIVATE_KEY") returns (uint256 key) {
            console.log("[OK] PRIVATE_KEY loaded");
            // Check if it's the placeholder
            if (key == 0) {
                console.log("  WARNING: PRIVATE_KEY is 0x0 (placeholder value)");
                warnings++;
            } else {
                console.log("  Key loaded successfully");
            }
        } catch {
            console.log("[ERROR] PRIVATE_KEY not found or invalid");
            console.log("  Required for deployment");
            errors++;
        }

        console.log("");

        // Test POOL_MANAGER_ADDRESS
        try vm.envAddress("POOL_MANAGER_ADDRESS") returns (address addr) {
            console.log("[OK] POOL_MANAGER_ADDRESS loaded");
            console.log("  Address:", addr);
            if (addr == address(0)) {
                console.log("  NOTE: Using zero address (OK for local development)");
            }
        } catch {
            console.log("[ERROR] POOL_MANAGER_ADDRESS not found or invalid");
            console.log("  Required for deployment");
            errors++;
        }

        console.log("");

        // Test RPC URLs (optional)
        try vm.envString("LOCAL_RPC_URL") returns (string memory url) {
            console.log("[OK] LOCAL_RPC_URL loaded");
            console.log("  URL:", url);
        } catch {
            console.log("[WARN] LOCAL_RPC_URL not set (optional)");
            warnings++;
        }

        try vm.envString("SEPOLIA_RPC_URL") returns (string memory url) {
            console.log("[OK] SEPOLIA_RPC_URL loaded");
            console.log("  URL length:", vm.toString(bytes(url).length), "characters");
            if (bytes(url).length > 0) {
                console.log("  URL starts with: https://");
            }
        } catch {
            console.log("[WARN] SEPOLIA_RPC_URL not set (optional for testnet)");
            warnings++;
        }

        try vm.envString("MAINNET_RPC_URL") returns (string memory url) {
            console.log("[OK] MAINNET_RPC_URL loaded");
            console.log("  URL length:", vm.toString(bytes(url).length), "characters");
            if (bytes(url).length > 0) {
                console.log("  URL starts with: https://");
            }
        } catch {
            console.log("[WARN] MAINNET_RPC_URL not set (optional for mainnet)");
            warnings++;
        }

        console.log("");

        // Test ETHERSCAN_API_KEY (optional)
        try vm.envString("ETHERSCAN_API_KEY") returns (string memory key) {
            console.log("[OK] ETHERSCAN_API_KEY loaded");
            console.log("  Key length:", vm.toString(bytes(key).length), "characters");
            if (bytes(key).length < 10) {
                console.log("  WARNING: Key seems too short");
                warnings++;
            }
        } catch {
            console.log("[WARN] ETHERSCAN_API_KEY not set (optional, needed for verification)");
            warnings++;
        }

        console.log("");
        console.log("========================================");
        console.log("Summary");
        console.log("========================================");
        console.log("Errors:", vm.toString(errors));
        console.log("Warnings:", vm.toString(warnings));
        console.log("");

        if (errors == 0) {
            console.log("[SUCCESS] All required variables are set!");
            if (warnings > 0) {
                console.log("  Some optional variables are missing (this is OK)");
            }
        } else {
            console.log("[FAILED] Some required variables are missing or invalid");
            console.log("  Please check your .env file");
        }
    }
}

