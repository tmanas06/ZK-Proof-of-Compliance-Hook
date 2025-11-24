// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {ZKProofOfCompliance} from "../src/hooks/ZKProofOfCompliance.sol";
import {BrevisVerifier} from "../src/verifiers/BrevisVerifier.sol";
import {IPoolManager} from "../src/interfaces/IPoolManager.sol";

/// @title DeployWithAnvilAccountScript
/// @notice Deployment script that uses Anvil's default account (for local testing)
/// @dev This uses Anvil's first account which has 10,000 ETH
contract DeployWithAnvilAccountScript is Script {
    function run() external {
        // Use Anvil's default account (has 10,000 ETH)
        // Private key: 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
        uint256 deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        vm.startBroadcast(deployerPrivateKey);

        console.log("Deploying BrevisVerifier...");
        BrevisVerifier verifier = new BrevisVerifier();
        console.log("BrevisVerifier deployed at:", address(verifier));

        // For local testing, use zero address as PoolManager
        // In production, use actual PoolManager address
        IPoolManager poolManager = IPoolManager(address(0x0000000000000000000000000000000000000000));

        console.log("Setting up compliance requirements...");
        ZKProofOfCompliance.ComplianceRequirements memory requirements = ZKProofOfCompliance
            .ComplianceRequirements({
                requireKYC: true,
                requireAgeVerification: true,
                requireLocationCheck: true,
                requireSanctionsCheck: true,
                minAge: 18
            });

        console.log("Deploying ZKProofOfCompliance hook...");
        ZKProofOfCompliance hook = new ZKProofOfCompliance(
            poolManager,
            verifier,
            requirements
        );
        console.log("ZKProofOfCompliance hook deployed at:", address(hook));

        console.log("");
        console.log("========================================");
        console.log("Deployment Summary");
        console.log("========================================");
        console.log("BrevisVerifier:", address(verifier));
        console.log("ZKProofOfCompliance Hook:", address(hook));
        console.log("Deployer:", vm.addr(deployerPrivateKey));
        console.log("========================================");

        vm.stopBroadcast();
    }
}

