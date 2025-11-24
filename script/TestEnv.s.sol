// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";

/// @title TestEnvScript
/// @notice Simple script to test environment variable loading
/// @dev Run this to verify your .env file is set up correctly
contract TestEnvScript is Script {
    function run() external view {
        console.log("Testing environment variables...");
        console.log("");

        // Test PRIVATE_KEY
        try vm.envUint("PRIVATE_KEY") returns (uint256 key) {
            console.log("[OK] PRIVATE_KEY loaded");
            console.log("  Key starts with: 0x", vm.toString(key));
        } catch {
            console.log("[ERROR] PRIVATE_KEY not found or invalid");
        }

        // Test POOL_MANAGER_ADDRESS
        try vm.envAddress("POOL_MANAGER_ADDRESS") returns (address addr) {
            console.log("[OK] POOL_MANAGER_ADDRESS loaded");
            console.log("  Address:", addr);
        } catch {
            console.log("[ERROR] POOL_MANAGER_ADDRESS not found or invalid");
        }

        // Test RPC URLs (optional)
        try vm.envString("MAINNET_RPC_URL") returns (string memory url) {
            console.log("[OK] MAINNET_RPC_URL loaded");
            console.log("  URL:", url);
        } catch {
            console.log("[WARN] MAINNET_RPC_URL not set (optional)");
        }

        try vm.envString("SEPOLIA_RPC_URL") returns (string memory url) {
            console.log("[OK] SEPOLIA_RPC_URL loaded");
            console.log("  URL:", url);
        } catch {
            console.log("[WARN] SEPOLIA_RPC_URL not set (optional)");
        }

        try vm.envString("LOCAL_RPC_URL") returns (string memory url) {
            console.log("[OK] LOCAL_RPC_URL loaded");
            console.log("  URL:", url);
        } catch {
            console.log("[WARN] LOCAL_RPC_URL not set (optional)");
        }

        // Test ETHERSCAN_API_KEY (optional)
        try vm.envString("ETHERSCAN_API_KEY") returns (string memory key) {
            console.log("[OK] ETHERSCAN_API_KEY loaded");
            console.log("  Key length:", vm.toString(bytes(key).length));
        } catch {
            console.log("[WARN] ETHERSCAN_API_KEY not set (optional)");
        }

        console.log("");
        console.log("Environment test complete!");
        console.log("");
        console.log("If you see errors, check your .env file.");
        console.log("Required: PRIVATE_KEY, POOL_MANAGER_ADDRESS");
    }
}

