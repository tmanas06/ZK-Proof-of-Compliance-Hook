// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {ProductionComplianceHook} from "../src/hooks/ProductionComplianceHook.sol";
import {IGroth16Verifier} from "../src/hooks/ProductionComplianceHook.sol";
import {MockGroth16Verifier} from "../src/verifiers/MockGroth16Verifier.sol";
import {IPoolManager} from "../src/interfaces/IPoolManager.sol";

/// @title DeployWithMockVerifier
/// @notice Deploy ProductionComplianceHook with MockGroth16Verifier for immediate testing
/// @dev This allows testing while the real Groth16 verifier is being generated
contract DeployWithMockVerifier is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address deployer = vm.addr(deployerPrivateKey);
        console.log("Deployer address:", deployer);
        console.log("");

        // Deploy MockGroth16Verifier for testing
        console.log("=== Deploying MockGroth16Verifier (for testing) ===");
        MockGroth16Verifier mockVerifier = new MockGroth16Verifier();
        console.log("MockGroth16Verifier deployed at:", address(mockVerifier));
        console.log("");

        // Get PoolManager address
        IPoolManager poolManager = IPoolManager(vm.envOr("POOL_MANAGER_ADDRESS", address(0)));
        if (address(poolManager) == address(0)) {
            console.log("WARNING: POOL_MANAGER_ADDRESS not set - using zero address for testing");
        }
        console.log("PoolManager address:", address(poolManager));
        console.log("");

        // Set up compliance requirements
        ProductionComplianceHook.ComplianceRequirements memory requirements = 
            ProductionComplianceHook.ComplianceRequirements({
                requireKYC: true,
                requireAgeVerification: true,
                requireLocationCheck: true,
                requireSanctionsCheck: true,
                minAge: 18,
                allowedCountryCode: bytes2("US")
            });

        // Get proof expiration (default: 30 days)
        uint256 proofExpiration = vm.envOr("PROOF_EXPIRATION", uint256(30 days));

        // Deploy ProductionComplianceHook
        console.log("=== Deploying ProductionComplianceHook ===");
        ProductionComplianceHook hook = new ProductionComplianceHook(
            poolManager,
            IGroth16Verifier(address(mockVerifier)),
            requirements,
            proofExpiration
        );
        console.log("ProductionComplianceHook deployed at:", address(hook));
        console.log("");

        // Output deployment summary
        console.log("=== DEPLOYMENT SUMMARY ===");
        console.log("Copy these addresses to your .env file:");
        console.log("");
        console.log("GROTH16_VERIFIER_ADDRESS=", address(mockVerifier));
        console.log("PRODUCTION_HOOK_ADDRESS=", address(hook));
        console.log("POOL_MANAGER_ADDRESS=", address(poolManager));
        console.log("");
        console.log("NOTE: This uses MockGroth16Verifier for testing.");
        console.log("Once the real Groth16 verifier is generated, update GROTH16_VERIFIER_ADDRESS.");
        console.log("");

        vm.stopBroadcast();
    }
}

