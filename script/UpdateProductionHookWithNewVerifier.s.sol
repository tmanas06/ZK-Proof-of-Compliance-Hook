// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {ProductionComplianceHook} from "../src/hooks/ProductionComplianceHook.sol";
import {IGroth16Verifier} from "../src/hooks/ProductionComplianceHook.sol";
import {IPoolManager} from "../src/interfaces/IPoolManager.sol";

/// @title UpdateProductionHookWithNewVerifier
/// @notice Optional: Redeploy ProductionComplianceHook with the newly deployed Groth16 verifier
/// @dev This is optional - you can keep using the existing hook if it's already working
contract UpdateProductionHookWithNewVerifier is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address deployer = vm.addr(deployerPrivateKey);
        console.log("Deployer address:", deployer);
        console.log("");

        // Get the newly deployed Groth16 Verifier
        address groth16VerifierAddress = vm.envAddress("GROTH16_VERIFIER_ADDRESS");
        IGroth16Verifier groth16Verifier = IGroth16Verifier(groth16VerifierAddress);
        console.log("Using Groth16 Verifier at:", address(groth16Verifier));
        console.log("");

        // Get PoolManager address (use deployer as placeholder for testing)
        address poolManagerAddress = vm.envOr("POOL_MANAGER_ADDRESS", address(deployer));
        IPoolManager poolManager = IPoolManager(poolManagerAddress);
        console.log("Using PoolManager at:", address(poolManager));
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
        uint256 proofExpiration = 30 days;

        // Deploy ProductionComplianceHook
        console.log("Deploying ProductionComplianceHook...");
        ProductionComplianceHook hook = new ProductionComplianceHook(
            poolManager,
            groth16Verifier,
            requirements,
            proofExpiration
        );

        console.log("ProductionComplianceHook deployed at:");
        console.logAddress(address(hook));
        console.log("");
        console.log("Deployment complete!");
        console.log("");
        console.log("Update your .env file with:");
        console.log("PRODUCTION_HOOK_ADDRESS=", vm.toString(address(hook)));

        vm.stopBroadcast();
    }
}

