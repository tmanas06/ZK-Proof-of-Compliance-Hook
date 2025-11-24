// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {ZKProofOfCompliance} from "../src/hooks/ZKProofOfCompliance.sol";
import {BrevisVerifier} from "../src/verifiers/BrevisVerifier.sol";
import {IPoolManager} from "../src/interfaces/IPoolManager.sol";

/// @title DeployScript
/// @notice Script to deploy the ZKProofOfCompliance hook and related contracts
contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        console.log("Deploying BrevisVerifier...");
        BrevisVerifier verifier = new BrevisVerifier();
        console.log("BrevisVerifier deployed at:", address(verifier));

        // Note: In production, you would deploy or get the actual PoolManager address
        // For testing, we'll use a placeholder
        IPoolManager poolManager = IPoolManager(vm.envAddress("POOL_MANAGER_ADDRESS"));

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

        console.log("Deployment complete!");
        console.log("Verifier address:", address(verifier));
        console.log("Hook address:", address(hook));

        vm.stopBroadcast();
    }
}

