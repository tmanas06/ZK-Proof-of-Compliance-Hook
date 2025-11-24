// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {MockPoolManager} from "../src/mocks/MockPoolManager.sol";
import {UniswapV4Router} from "../src/router/UniswapV4Router.sol";
import {ZKProofOfCompliance} from "../src/hooks/ZKProofOfCompliance.sol";
import {BrevisVerifier} from "../src/verifiers/BrevisVerifier.sol";
import {IPoolManager} from "../src/interfaces/IPoolManager.sol";

/// @title DeployRouterScript
/// @notice Deploys MockPoolManager and Router for frontend integration
contract DeployRouterScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        console.log("Deploying MockPoolManager...");
        MockPoolManager poolManager = new MockPoolManager();
        console.log("MockPoolManager deployed at:", address(poolManager));

        console.log("Deploying UniswapV4Router...");
        UniswapV4Router router = new UniswapV4Router(IPoolManager(address(poolManager)));
        console.log("UniswapV4Router deployed at:", address(router));

        // Get existing hook address (from previous deployment)
        address hookAddress;
        try vm.envAddress("HOOK_ADDRESS") returns (address addr) {
            hookAddress = addr;
        } catch {
            hookAddress = address(0);
        }
        
        if (hookAddress == address(0)) {
            // Deploy new hook if not set
            console.log("Deploying new hook...");
            BrevisVerifier verifier = new BrevisVerifier();
            
            ZKProofOfCompliance.ComplianceRequirements memory requirements = ZKProofOfCompliance
                .ComplianceRequirements({
                    requireKYC: true,
                    requireAgeVerification: true,
                    requireLocationCheck: true,
                    requireSanctionsCheck: true,
                    minAge: 18
                });
            
            ZKProofOfCompliance hook = new ZKProofOfCompliance(
                IPoolManager(address(poolManager)),
                verifier,
                requirements
            );
            console.log("Hook deployed at:", address(hook));
            console.log("Verifier deployed at:", address(verifier));
        }

        console.log("");
        console.log("========================================");
        console.log("Deployment Complete!");
        console.log("========================================");
        console.log("PoolManager:", address(poolManager));
        console.log("Router:", address(router));
        if (hookAddress != address(0)) {
            console.log("Hook:", hookAddress);
        } else {
            console.log("Hook: See above (newly deployed)");
        }
        console.log("========================================");

        vm.stopBroadcast();
    }
}

