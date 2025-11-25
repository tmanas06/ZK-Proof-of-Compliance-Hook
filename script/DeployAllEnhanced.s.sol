// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {RealBrevisVerifier} from "../src/verifiers/RealBrevisVerifier.sol";
import {MockGroth16Verifier} from "../src/verifiers/MockGroth16Verifier.sol";
import {RealEigenLayerAVS} from "../src/services/RealEigenLayerAVS.sol";
import {RealFhenixFHE} from "../src/services/RealFhenixFHE.sol";
import {ZKProofOfComplianceFull} from "../src/hooks/ZKProofOfComplianceFull.sol";
import {IPoolManager} from "../src/interfaces/IPoolManager.sol";

/// @title DeployAllEnhanced
/// @notice Comprehensive deployment script for all enhanced contracts
/// @dev Deploys in order: Groth16 Verifier -> RealBrevisVerifier -> RealEigenLayerAVS -> RealFhenixFHE -> ZKProofOfComplianceFull
contract DeployAllEnhanced is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address deployer = vm.addr(deployerPrivateKey);
        console.log("Deployer address:", deployer);

        // Step 1: Deploy Groth16 Verifier (or use existing)
        address groth16Verifier = vm.envOr("GROTH16_VERIFIER_ADDRESS", address(0));
        
        if (groth16Verifier == address(0)) {
            console.log("GROTH16_VERIFIER_ADDRESS not set - deploying MockGroth16Verifier for testing");
            console.log("NOTE: For production, generate and deploy actual Groth16Verifier.sol using:");
            console.log("  snarkjs zkey export solidityverifier compliance_0001.zkey verifier.sol");
            console.log("Then deploy verifier.sol and set GROTH16_VERIFIER_ADDRESS in .env");
            
            // Deploy a mock verifier for testing
            MockGroth16Verifier mockVerifier = new MockGroth16Verifier();
            groth16Verifier = address(mockVerifier);
            console.log("MockGroth16Verifier deployed at:", groth16Verifier);
        } else {
            console.log("Using existing Groth16 Verifier at:", groth16Verifier);
        }

        // Step 2: Deploy RealBrevisVerifier
        console.log("\n=== Deploying RealBrevisVerifier ===");
        RealBrevisVerifier brevisVerifier = new RealBrevisVerifier(groth16Verifier);
        console.log("RealBrevisVerifier deployed at:", address(brevisVerifier));

        // Step 3: Deploy RealEigenLayerAVS
        console.log("\n=== Deploying RealEigenLayerAVS ===");
        // For now, use default test operators
        // In production, parse EIGENLAYER_OPERATORS from env as comma-separated addresses
        address[] memory operators = new address[](2);
        operators[0] = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
        operators[1] = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;
        console.log("Using default test operators");
        
        uint256 minConfirmations = vm.envOr("EIGENLAYER_MIN_CONFIRMATIONS", uint256(2));
        uint256 timeout = vm.envOr("EIGENLAYER_TIMEOUT", uint256(300)); // 5 minutes
        uint256 maxRetries = vm.envOr("EIGENLAYER_MAX_RETRIES", uint256(3));
        uint256 retryDelay = vm.envOr("EIGENLAYER_RETRY_DELAY", uint256(60)); // 1 minute

        RealEigenLayerAVS eigenLayerAVS = new RealEigenLayerAVS(
            operators,
            minConfirmations,
            timeout,
            maxRetries,
            retryDelay
        );
        console.log("RealEigenLayerAVS deployed at:", address(eigenLayerAVS));
        console.log("Operators:", operators.length);
        console.log("Min confirmations:", minConfirmations);

        // Step 4: Deploy RealFhenixFHE
        console.log("\n=== Deploying RealFhenixFHE ===");
        address fhenixService = vm.envOr("FHENIX_SERVICE_ADDRESS", address(0));
        if (fhenixService == address(0)) {
            fhenixService = deployer; // Use deployer as service for testing
        }
        
        RealFhenixFHE fhenixFHE = new RealFhenixFHE(fhenixService);
        console.log("RealFhenixFHE deployed at:", address(fhenixFHE));
        console.log("Fhenix service address:", fhenixService);

        // Step 5: Get Fhenix FHE address (from env or use placeholder)
        address fhenixFHEAddress = vm.envOr("FHENIX_FHE_ADDRESS", address(0));
        if (fhenixFHEAddress == address(0)) {
            console.log("WARNING: FHENIX_FHE_ADDRESS not set - using placeholder");
            fhenixFHEAddress = address(0x1111111111111111111111111111111111111111);
        }

        // Step 6: Deploy ZKProofOfComplianceFull Hook
        console.log("\n=== Deploying ZKProofOfComplianceFull Hook ===");
        IPoolManager poolManager = IPoolManager(vm.envOr("POOL_MANAGER_ADDRESS", address(0)));
        if (address(poolManager) == address(0)) {
            console.log("WARNING: POOL_MANAGER_ADDRESS not set - using zero address for testing");
        }

        // Set up compliance requirements
        ZKProofOfComplianceFull.ComplianceRequirements memory requirements = 
            ZKProofOfComplianceFull.ComplianceRequirements({
                requireKYC: true,
                requireAgeVerification: true,
                requireLocationCheck: true,
                requireSanctionsCheck: true,
                minAge: 18
            });

        uint8 verificationMode = uint8(vm.envOr("VERIFICATION_MODE", uint256(0))); // 0 = BrevisOnly
        bool allowFallback = vm.envOr("ALLOW_FALLBACK", true);

        ZKProofOfComplianceFull hook = new ZKProofOfComplianceFull(
            poolManager,
            brevisVerifier,
            eigenLayerAVS,
            fhenixFHE,
            requirements,
            ZKProofOfComplianceFull.VerificationMode(verificationMode),
            allowFallback
        );
        console.log("ZKProofOfComplianceFull hook deployed at:", address(hook));

        // Output all addresses for .env
        console.log("\n=== DEPLOYMENT SUMMARY ===");
        console.log("Copy these addresses to your .env file:\n");
        console.log("GROTH16_VERIFIER_ADDRESS=", groth16Verifier);
        console.log("BREVIS_VERIFIER_ADDRESS=", address(brevisVerifier));
        console.log("EIGENLAYER_AVS_ADDRESS=", address(eigenLayerAVS));
        console.log("FHENIX_FHE_ADDRESS=", fhenixFHEAddress);
        console.log("FHENIX_SERVICE_ADDRESS=", fhenixService);
        console.log("HOOK_ADDRESS=", address(hook));
        console.log("\n=== Additional Configuration ===");
        console.log("EIGENLAYER_OPERATORS=", _formatAddresses(operators));
        console.log("EIGENLAYER_MIN_CONFIRMATIONS=", minConfirmations);
        console.log("EIGENLAYER_TIMEOUT=", timeout);
        console.log("EIGENLAYER_MAX_RETRIES=", maxRetries);
        console.log("EIGENLAYER_RETRY_DELAY=", retryDelay);
        console.log("VERIFICATION_MODE=", verificationMode);
        console.log("ALLOW_FALLBACK=", allowFallback);

        vm.stopBroadcast();
    }

    function _formatAddresses(address[] memory addresses) internal pure returns (string memory) {
        if (addresses.length == 0) return "";
        string memory result = "";
        for (uint256 i = 0; i < addresses.length; i++) {
            if (i > 0) {
                result = string(abi.encodePacked(result, ","));
            }
            result = string(abi.encodePacked(result, _addressToString(addresses[i])));
        }
        return result;
    }

    function _addressToString(address addr) internal pure returns (string memory) {
        bytes32 value = bytes32(uint256(uint160(addr)));
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(42);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < 20; i++) {
            str[2 + i * 2] = alphabet[uint8(value[i + 12] >> 4)];
            str[3 + i * 2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }
        return string(str);
    }
}

