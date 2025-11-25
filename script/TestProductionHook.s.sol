// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {ProductionComplianceHook} from "../src/hooks/ProductionComplianceHook.sol";
import {IGroth16Verifier} from "../src/hooks/ProductionComplianceHook.sol";

/// @title TestProductionHook
/// @notice Test script to verify ProductionComplianceHook is working
contract TestProductionHook is Script {
    function run() external view {
        address hookAddress = vm.envAddress("PRODUCTION_HOOK_ADDRESS");
        ProductionComplianceHook hook = ProductionComplianceHook(hookAddress);

        console.log("========================================");
        console.log("Production Compliance Hook Test");
        console.log("========================================");
        console.log("");
        console.log("Hook Address:", address(hook));
        console.log("Admin:", hook.admin());
        console.log("Enabled:", hook.enabled());
        console.log("Proof Expiration:", hook.proofExpiration());
        console.log("Groth16 Verifier:", address(hook.groth16Verifier()));
        console.log("");

        // Test user
        address testUser = address(0x70997970C51812dc3A010C7d01b50e0d17dc79C8);
        (bool isCompliant, bytes32 hash, uint256 time) = hook.checkCompliance(testUser);
        
        console.log("Test User Compliance Status:");
        console.log("  Address:", testUser);
        console.log("  Is Compliant:", isCompliant);
        console.log("  Compliance Hash:", vm.toString(hash));
        console.log("  Last Proof Time:", time);
        console.log("");

        // Requirements
        (bool reqKYC, bool reqAge, bool reqLoc, bool reqSanctions, uint256 minAge, bytes2 country) = hook.requirements();
        console.log("Compliance Requirements:");
        console.log("  Require KYC:", reqKYC);
        console.log("  Require Age Verification:", reqAge);
        console.log("  Require Location Check:", reqLoc);
        console.log("  Require Sanctions Check:", reqSanctions);
        console.log("  Min Age:", minAge);
        console.log("  Allowed Country:", string(abi.encodePacked(country)));
        console.log("");

        console.log("========================================");
        console.log("Hook is deployed and accessible!");
        console.log("========================================");
    }
}

