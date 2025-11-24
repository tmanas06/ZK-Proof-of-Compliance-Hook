// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {ZKProofOfCompliance} from "../src/hooks/ZKProofOfCompliance.sol";
import {BrevisVerifier} from "../src/verifiers/BrevisVerifier.sol";
import {IBrevisVerifier} from "../src/interfaces/IBrevisVerifier.sol";
import {IPoolManager} from "../src/interfaces/IPoolManager.sol";
import {ComplianceData} from "../src/libraries/ComplianceData.sol";

/// @title ZKProofOfComplianceTest
/// @notice Comprehensive test suite for ZKProofOfCompliance hook
contract ZKProofOfComplianceTest is Test {
    ZKProofOfCompliance public hook;
    BrevisVerifier public verifier;
    IPoolManager public poolManager;

    address public admin;
    address public compliantUser;
    address public nonCompliantUser;
    address public attacker;

    bytes32 public compliantDataHash;
    bytes32 public nonCompliantDataHash;

    IBrevisVerifier.ComplianceData public compliantData;
    IBrevisVerifier.ComplianceData public nonCompliantData;

    function setUp() public {
        admin = address(this);
        compliantUser = address(0x1);
        nonCompliantUser = address(0x2);
        attacker = address(0x3);

        // Deploy Brevis verifier
        verifier = new BrevisVerifier();

        // Create mock pool manager (we'll use a mock for testing)
        poolManager = IPoolManager(address(0x1000));

        // Create compliance data
        compliantData = ComplianceData.createCompliantData();
        compliantDataHash = ComplianceData.hashComplianceData(compliantData);

        nonCompliantData = ComplianceData.createNonCompliantData();
        nonCompliantDataHash = ComplianceData.hashComplianceData(nonCompliantData);

        // Set up compliance requirements
        ZKProofOfCompliance.ComplianceRequirements memory requirements = ZKProofOfCompliance
            .ComplianceRequirements({
                requireKYC: true,
                requireAgeVerification: true,
                requireLocationCheck: true,
                requireSanctionsCheck: true,
                minAge: 18
            });

        // Deploy hook
        hook = new ZKProofOfCompliance(poolManager, verifier, requirements);

        // Set user compliance in verifier
        verifier.setUserCompliance(compliantUser, true, compliantDataHash);
        verifier.setUserCompliance(nonCompliantUser, false, nonCompliantDataHash);
    }

    /// @notice Test that compliant users can submit proofs
    function test_CompliantUserCanSubmitProof() public {
        IBrevisVerifier.ComplianceProof memory proof = _createProof(
            compliantUser,
            compliantDataHash
        );

        vm.prank(compliantUser);
        hook.submitProof(proof);

        assertTrue(hook.isProofUsed(proof.proofHash));
        assertEq(hook.userComplianceHashes(compliantUser), compliantDataHash);
    }

    /// @notice Test that non-compliant users cannot submit proofs
    function test_NonCompliantUserCannotSubmitProof() public {
        IBrevisVerifier.ComplianceProof memory proof = _createProof(
            nonCompliantUser,
            nonCompliantDataHash
        );

        vm.prank(nonCompliantUser);
        vm.expectRevert(ZKProofOfCompliance.UserNotCompliant.selector);
        hook.submitProof(proof);
    }

    /// @notice Test that proofs cannot be reused (replay protection)
    function test_ProofReplayProtection() public {
        IBrevisVerifier.ComplianceProof memory proof = _createProof(
            compliantUser,
            compliantDataHash
        );

        vm.prank(compliantUser);
        hook.submitProof(proof);

        // Try to use the same proof again
        vm.prank(compliantUser);
        vm.expectRevert(ZKProofOfCompliance.ProofAlreadyUsed.selector);
        hook.submitProof(proof);
    }

    /// @notice Test that beforeSwap allows compliant users
    function test_BeforeSwap_CompliantUser() public {
        IBrevisVerifier.ComplianceProof memory proof = _createProof(
            compliantUser,
            compliantDataHash
        );

        bytes memory hookData = abi.encode(proof);

        IPoolManager.PoolKey memory key = IPoolManager.PoolKey({
            currency0: address(0xA),
            currency1: address(0xB),
            fee: 3000,
            tickSpacing: 60,
            hooks: hook
        });

        IPoolManager.SwapParams memory params = IPoolManager.SwapParams({
            zeroForOne: true,
            amountSpecified: 1000,
            sqrtPriceLimitX96: 0
        });

        vm.prank(address(poolManager));
        bytes4 selector = hook.beforeSwap(compliantUser, key, params, hookData);

        assertEq(selector, hook.beforeSwap.selector);
        assertTrue(hook.isProofUsed(proof.proofHash));
    }

    /// @notice Test that beforeSwap blocks non-compliant users
    function test_BeforeSwap_NonCompliantUser() public {
        IBrevisVerifier.ComplianceProof memory proof = _createProof(
            nonCompliantUser,
            nonCompliantDataHash
        );

        bytes memory hookData = abi.encode(proof);

        IPoolManager.PoolKey memory key = IPoolManager.PoolKey({
            currency0: address(0xA),
            currency1: address(0xB),
            fee: 3000,
            tickSpacing: 60,
            hooks: hook
        });

        IPoolManager.SwapParams memory params = IPoolManager.SwapParams({
            zeroForOne: true,
            amountSpecified: 1000,
            sqrtPriceLimitX96: 0
        });

        vm.prank(address(poolManager));
        vm.expectRevert(ZKProofOfCompliance.UserNotCompliant.selector);
        hook.beforeSwap(nonCompliantUser, key, params, hookData);
    }

    /// @notice Test that beforeSwap blocks users with invalid proofs
    function test_BeforeSwap_InvalidProof() public {
        IBrevisVerifier.ComplianceProof memory proof = _createProof(
            compliantUser,
            bytes32(uint256(0xDEAD)) // Invalid hash
        );

        bytes memory hookData = abi.encode(proof);

        IPoolManager.PoolKey memory key = IPoolManager.PoolKey({
            currency0: address(0xA),
            currency1: address(0xB),
            fee: 3000,
            tickSpacing: 60,
            hooks: hook
        });

        IPoolManager.SwapParams memory params = IPoolManager.SwapParams({
            zeroForOne: true,
            amountSpecified: 1000,
            sqrtPriceLimitX96: 0
        });

        vm.prank(address(poolManager));
        vm.expectRevert(ZKProofOfCompliance.InvalidProof.selector);
        hook.beforeSwap(compliantUser, key, params, hookData);
    }

    /// @notice Test that beforeSwap blocks users with mismatched proof user
    function test_BeforeSwap_ProofUserMismatch() public {
        IBrevisVerifier.ComplianceProof memory proof = _createProof(
            attacker, // Proof for attacker
            compliantDataHash
        );

        bytes memory hookData = abi.encode(proof);

        IPoolManager.PoolKey memory key = IPoolManager.PoolKey({
            currency0: address(0xA),
            currency1: address(0xB),
            fee: 3000,
            tickSpacing: 60,
            hooks: hook
        });

        IPoolManager.SwapParams memory params = IPoolManager.SwapParams({
            zeroForOne: true,
            amountSpecified: 1000,
            sqrtPriceLimitX96: 0
        });

        vm.prank(address(poolManager));
        vm.expectRevert(ZKProofOfCompliance.InvalidProof.selector);
        hook.beforeSwap(compliantUser, key, params, hookData);
    }

    /// @notice Test that beforeAddLiquidity allows compliant users
    function test_BeforeAddLiquidity_CompliantUser() public {
        IBrevisVerifier.ComplianceProof memory proof = _createProof(
            compliantUser,
            compliantDataHash
        );

        bytes memory hookData = abi.encode(proof);

        IPoolManager.PoolKey memory key = IPoolManager.PoolKey({
            currency0: address(0xA),
            currency1: address(0xB),
            fee: 3000,
            tickSpacing: 60,
            hooks: hook
        });

        IPoolManager.ModifyLiquidityParams memory params = IPoolManager.ModifyLiquidityParams({
            tickLower: -100,
            tickUpper: 100,
            liquidityDelta: 1000
        });

        vm.prank(address(poolManager));
        bytes4 selector = hook.beforeAddLiquidity(compliantUser, key, params, hookData);

        assertEq(selector, hook.beforeAddLiquidity.selector);
        assertTrue(hook.isProofUsed(proof.proofHash));
    }

    /// @notice Test that beforeAddLiquidity blocks non-compliant users
    function test_BeforeAddLiquidity_NonCompliantUser() public {
        IBrevisVerifier.ComplianceProof memory proof = _createProof(
            nonCompliantUser,
            nonCompliantDataHash
        );

        bytes memory hookData = abi.encode(proof);

        IPoolManager.PoolKey memory key = IPoolManager.PoolKey({
            currency0: address(0xA),
            currency1: address(0xB),
            fee: 3000,
            tickSpacing: 60,
            hooks: hook
        });

        IPoolManager.ModifyLiquidityParams memory params = IPoolManager.ModifyLiquidityParams({
            tickLower: -100,
            tickUpper: 100,
            liquidityDelta: 1000
        });

        vm.prank(address(poolManager));
        vm.expectRevert(ZKProofOfCompliance.UserNotCompliant.selector);
        hook.beforeAddLiquidity(nonCompliantUser, key, params, hookData);
    }

    /// @notice Test that hook can be disabled
    function test_HookCanBeDisabled() public {
        hook.setEnabled(false);

        IBrevisVerifier.ComplianceProof memory proof = _createProof(
            compliantUser,
            compliantDataHash
        );

        bytes memory hookData = abi.encode(proof);

        IPoolManager.PoolKey memory key = IPoolManager.PoolKey({
            currency0: address(0xA),
            currency1: address(0xB),
            fee: 3000,
            tickSpacing: 60,
            hooks: hook
        });

        IPoolManager.SwapParams memory params = IPoolManager.SwapParams({
            zeroForOne: true,
            amountSpecified: 1000,
            sqrtPriceLimitX96: 0
        });

        vm.prank(address(poolManager));
        vm.expectRevert(ZKProofOfCompliance.HookNotEnabled.selector);
        hook.beforeSwap(compliantUser, key, params, hookData);
    }

    /// @notice Test that requirements can be updated
    function test_RequirementsCanBeUpdated() public {
        ZKProofOfCompliance.ComplianceRequirements memory newRequirements = ZKProofOfCompliance
            .ComplianceRequirements({
                requireKYC: false,
                requireAgeVerification: true,
                requireLocationCheck: false,
                requireSanctionsCheck: true,
                minAge: 21
            });

        hook.setRequirements(newRequirements);

        // Public structs return tuples, so we destructure directly
        (
            bool requireKYC,
            bool requireAgeVerification,
            bool requireLocationCheck,
            bool requireSanctionsCheck,
            uint256 minAge
        ) = hook.requirements();

        assertEq(requireKYC, false);
        assertEq(requireAgeVerification, true);
        assertEq(requireLocationCheck, false);
        assertEq(requireSanctionsCheck, true);
        assertEq(minAge, 21);
    }

    /// @notice Test that only admin can update settings
    function test_OnlyAdminCanUpdateSettings() public {
        vm.prank(attacker);
        vm.expectRevert(ZKProofOfCompliance.Unauthorized.selector);
        hook.setEnabled(false);

        vm.prank(attacker);
        vm.expectRevert(ZKProofOfCompliance.Unauthorized.selector);
        ZKProofOfCompliance.ComplianceRequirements memory newRequirements = ZKProofOfCompliance
            .ComplianceRequirements({
                requireKYC: false,
                requireAgeVerification: false,
                requireLocationCheck: false,
                requireSanctionsCheck: false,
                minAge: 0
            });
        hook.setRequirements(newRequirements);
    }

    /// @notice Test that expired proofs are rejected
    function test_ExpiredProofRejected() public {
        IBrevisVerifier.ComplianceProof memory proof = _createProof(
            compliantUser,
            compliantDataHash
        );

        // Set proof timestamp to be expired (more than 30 days ago)
        proof.timestamp = uint256(block.timestamp - 31 days);

        bytes memory hookData = abi.encode(proof);

        IPoolManager.PoolKey memory key = IPoolManager.PoolKey({
            currency0: address(0xA),
            currency1: address(0xB),
            fee: 3000,
            tickSpacing: 60,
            hooks: hook
        });

        IPoolManager.SwapParams memory params = IPoolManager.SwapParams({
            zeroForOne: true,
            amountSpecified: 1000,
            sqrtPriceLimitX96: 0
        });

        vm.prank(address(poolManager));
        vm.expectRevert();
        hook.beforeSwap(compliantUser, key, params, hookData);
    }

    /// @notice Test gas limits (ensure operations don't exceed gas limits)
    function test_GasLimits() public {
        IBrevisVerifier.ComplianceProof memory proof = _createProof(
            compliantUser,
            compliantDataHash
        );

        bytes memory hookData = abi.encode(proof);

        IPoolManager.PoolKey memory key = IPoolManager.PoolKey({
            currency0: address(0xA),
            currency1: address(0xB),
            fee: 3000,
            tickSpacing: 60,
            hooks: hook
        });

        IPoolManager.SwapParams memory params = IPoolManager.SwapParams({
            zeroForOne: true,
            amountSpecified: 1000,
            sqrtPriceLimitX96: 0
        });

        vm.prank(address(poolManager));
        uint256 gasBefore = gasleft();
        hook.beforeSwap(compliantUser, key, params, hookData);
        uint256 gasUsed = gasBefore - gasleft();

        // Ensure gas usage is reasonable (less than 100k gas)
        assertLt(gasUsed, 100000);
    }

    /// @notice Helper function to create a proof
    function _createProof(
        address user,
        bytes32 dataHash
    ) internal view returns (IBrevisVerifier.ComplianceProof memory) {
        return
            IBrevisVerifier.ComplianceProof({
                proofHash: keccak256(abi.encodePacked(user, dataHash, block.timestamp)),
                publicInputs: abi.encode(dataHash),
                timestamp: block.timestamp,
                user: user
            });
    }
}

