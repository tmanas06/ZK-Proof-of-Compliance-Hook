// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {ProductionComplianceHook} from "../src/hooks/ProductionComplianceHook.sol";
import {IGroth16Verifier} from "../src/hooks/ProductionComplianceHook.sol";
import {IPoolManager} from "../src/interfaces/IPoolManager.sol";

/// @title DeployProductionHook
/// @notice Deployment script for ProductionComplianceHook with Groth16 verifier
contract DeployProductionHook is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address deployer = vm.addr(deployerPrivateKey);
        console.log("Deployer address:", deployer);
        console.log("");

        // Step 1: Get or deploy Groth16 Verifier
        address groth16VerifierAddress = vm.envOr("GROTH16_VERIFIER_ADDRESS", address(0));
        
        if (groth16VerifierAddress == address(0)) {
            console.log("ERROR: GROTH16_VERIFIER_ADDRESS not set in .env");
            console.log("");
            console.log("Please generate the Groth16 verifier first:");
            console.log("  Windows: .\\scripts\\generate-groth16-verifier.ps1");
            console.log("  Linux/Mac: bash scripts/generate-groth16-verifier.sh");
            console.log("");
            console.log("Then deploy the generated Groth16Verifier.sol contract");
            console.log("and set GROTH16_VERIFIER_ADDRESS in .env");
            revert("Groth16 verifier address required");
        }

        IGroth16Verifier groth16Verifier = IGroth16Verifier(groth16VerifierAddress);
        console.log("Using Groth16 Verifier at:", address(groth16Verifier));
        console.log("");

        // Step 2: Get PoolManager address
        IPoolManager poolManager = IPoolManager(vm.envOr("POOL_MANAGER_ADDRESS", address(0)));
        if (address(poolManager) == address(0)) {
            console.log("WARNING: POOL_MANAGER_ADDRESS not set - using zero address for testing");
        }
        console.log("PoolManager address:", address(poolManager));
        console.log("");

        // Step 3: Set up compliance requirements
        ProductionComplianceHook.ComplianceRequirements memory requirements = 
            ProductionComplianceHook.ComplianceRequirements({
                requireKYC: true,
                requireAgeVerification: true,
                requireLocationCheck: true,
                requireSanctionsCheck: true,
                minAge: 18,
                allowedCountryCode: bytes2("US") // ISO country code
            });

        // Step 4: Get proof expiration (default: 30 days)
        uint256 proofExpiration = vm.envOr("PROOF_EXPIRATION", uint256(30 days));

        // Step 5: Deploy ProductionComplianceHook
        console.log("=== Deploying ProductionComplianceHook ===");
        ProductionComplianceHook hook = new ProductionComplianceHook(
            poolManager,
            groth16Verifier,
            requirements,
            proofExpiration
        );
        console.log("ProductionComplianceHook deployed at:", address(hook));
        console.log("");

        // Step 6: Output deployment summary
        console.log("=== DEPLOYMENT SUMMARY ===");
        console.log("Copy these addresses to your .env file:");
        console.log("");
        console.log("GROTH16_VERIFIER_ADDRESS=", groth16VerifierAddress);
        console.log("PRODUCTION_HOOK_ADDRESS=", address(hook));
        console.log("POOL_MANAGER_ADDRESS=", address(poolManager));
        console.log("");
        console.log("=== Configuration ===");
        console.log("Proof expiration:", proofExpiration, "seconds");
        console.log("Requirements:");
        console.log("  Require KYC:", requirements.requireKYC);
        console.log("  Require age verification:", requirements.requireAgeVerification);
        console.log("  Require location check:", requirements.requireLocationCheck);
        console.log("  Require sanctions check:", requirements.requireSanctionsCheck);
        console.log("  Min age:", requirements.minAge);
        console.log("  Allowed country:", string(abi.encodePacked(requirements.allowedCountryCode)));
        console.log("");

        vm.stopBroadcast();
    }
}

