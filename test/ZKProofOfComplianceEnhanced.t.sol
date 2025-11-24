// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {ZKProofOfComplianceEnhanced} from "../src/hooks/ZKProofOfComplianceEnhanced.sol";
import {BrevisVerifier} from "../src/verifiers/BrevisVerifier.sol";
import {EigenLayerAVS} from "../src/services/EigenLayerAVS.sol";
import {IBrevisVerifier} from "../src/interfaces/IBrevisVerifier.sol";
import {IPoolManager} from "../src/interfaces/IPoolManager.sol";
import {ComplianceData} from "../src/libraries/ComplianceData.sol";

/// @title ZKProofOfComplianceEnhancedTest
/// @notice Comprehensive test suite for enhanced hook with EigenLayer AVS integration
contract ZKProofOfComplianceEnhancedTest is Test {
    ZKProofOfComplianceEnhanced public hook;
    BrevisVerifier public verifier;
    EigenLayerAVS public eigenLayerAVS;
    IPoolManager public poolManager;

    address public admin;
    address public compliantUser;
    address public nonCompliantUser;
    address public operator;

    bytes32 public compliantDataHash;
    bytes32 public nonCompliantDataHash;

    IBrevisVerifier.ComplianceData public compliantData;
    IBrevisVerifier.ComplianceData public nonCompliantData;

    function setUp() public {
        admin = address(this);
        compliantUser = address(0x1);
        nonCompliantUser = address(0x2);
        operator = address(0x1001);

        // Deploy Brevis verifier
        verifier = new BrevisVerifier();

        // Deploy EigenLayer AVS
        eigenLayerAVS = new EigenLayerAVS();

        // Create mock pool manager
        poolManager = IPoolManager(address(0x1000));

        // Create compliance data
        compliantData = ComplianceData.createCompliantData();
        compliantDataHash = ComplianceData.hashComplianceData(compliantData);

        nonCompliantData = ComplianceData.createNonCompliantData();
        nonCompliantDataHash = ComplianceData.hashComplianceData(nonCompliantData);

        // Set up compliance requirements
        ZKProofOfComplianceEnhanced.ComplianceRequirements memory requirements = ZKProofOfComplianceEnhanced
            .ComplianceRequirements({
                requireKYC: true,
                requireAgeVerification: true,
                requireLocationCheck: true,
                requireSanctionsCheck: true,
                minAge: 18
            });

        // Deploy hook with hybrid verification mode
        hook = new ZKProofOfComplianceEnhanced(
            poolManager,
            verifier,
            eigenLayerAVS,
            requirements,
            ZKProofOfComplianceEnhanced.VerificationMode.Hybrid
        );

        // Set user compliance in verifier
        verifier.setUserCompliance(compliantUser, true, compliantDataHash);
        verifier.setUserCompliance(nonCompliantUser, false, nonCompliantDataHash);
    }

    /// @notice Test Brevis-only verification mode
    function test_BrevisOnlyMode() public {
        // Set to Brevis-only mode
        hook.setVerificationMode(ZKProofOfComplianceEnhanced.VerificationMode.BrevisOnly);

        IBrevisVerifier.ComplianceProof memory proof = _createProof(
            compliantUser,
            compliantDataHash
        );

        bytes memory hookData = abi.encode(proof);

        IPoolManager.PoolKey memory key = _createPoolKey();
        IPoolManager.SwapParams memory params = _createSwapParams();

        vm.prank(address(poolManager));
        bytes4 selector = hook.beforeSwap(compliantUser, key, params, hookData);

        assertEq(selector, hook.beforeSwap.selector);
    }

    /// @notice Test EigenLayer-only verification mode
    function test_EigenLayerOnlyMode() public {
        hook.setVerificationMode(ZKProofOfComplianceEnhanced.VerificationMode.EigenLayerOnly);

        IBrevisVerifier.ComplianceProof memory proof = _createProof(
            compliantUser,
            compliantDataHash
        );

        // Submit verification request first
        bytes32 requestId = hook.submitEigenLayerVerification(proof);

        // Set verification result as operator
        vm.prank(operator);
        eigenLayerAVS.adminSetVerificationResult(requestId, true, compliantDataHash, "");

        bytes memory hookData = abi.encode(proof);
        IPoolManager.PoolKey memory key = _createPoolKey();
        IPoolManager.SwapParams memory params = _createSwapParams();

        vm.prank(address(poolManager));
        bytes4 selector = hook.beforeSwap(compliantUser, key, params, hookData);

        assertEq(selector, hook.beforeSwap.selector);
    }

    /// @notice Test hybrid mode with EigenLayer fallback to Brevis
    function test_HybridMode_EigenLayerFallbackToBrevis() public {
        hook.setVerificationMode(ZKProofOfComplianceEnhanced.VerificationMode.Hybrid);

        IBrevisVerifier.ComplianceProof memory proof = _createProof(
            compliantUser,
            compliantDataHash
        );

        bytes memory hookData = abi.encode(proof);
        IPoolManager.PoolKey memory key = _createPoolKey();
        IPoolManager.SwapParams memory params = _createSwapParams();

        // EigenLayer will fail (no verification set), should fallback to Brevis
        vm.prank(address(poolManager));
        bytes4 selector = hook.beforeSwap(compliantUser, key, params, hookData);

        assertEq(selector, hook.beforeSwap.selector);
    }

    /// @notice Test that pending EigenLayer verification blocks transaction
    function test_PendingEigenLayerVerificationBlocks() public {
        hook.setVerificationMode(ZKProofOfComplianceEnhanced.VerificationMode.EigenLayerOnly);

        IBrevisVerifier.ComplianceProof memory proof = _createProof(
            compliantUser,
            compliantDataHash
        );

        // Submit verification request (will be pending)
        hook.submitEigenLayerVerification(proof);

        bytes memory hookData = abi.encode(proof);
        IPoolManager.PoolKey memory key = _createPoolKey();
        IPoolManager.SwapParams memory params = _createSwapParams();

        vm.prank(address(poolManager));
        vm.expectRevert(ZKProofOfComplianceEnhanced.VerificationPending.selector);
        hook.beforeSwap(compliantUser, key, params, hookData);
    }

    /// @notice Test EigenLayer verification status check
    function test_CheckEigenLayerStatus() public {
        IBrevisVerifier.ComplianceProof memory proof = _createProof(
            compliantUser,
            compliantDataHash
        );

        bytes32 requestId = hook.submitEigenLayerVerification(proof);

        // Check status (should be pending)
        (bool isPending, bool isValid) = hook.checkEigenLayerStatus(compliantUser);
        assertTrue(isPending);
        assertFalse(isValid);

        // Set verification result
        vm.prank(operator);
        eigenLayerAVS.adminSetVerificationResult(requestId, true, compliantDataHash, "");

        // Check status again (should be complete and valid)
        (isPending, isValid) = hook.checkEigenLayerStatus(compliantUser);
        assertFalse(isPending);
        assertTrue(isValid);
    }

    /// @notice Test that all verification methods failing reverts
    function test_AllVerificationMethodsFail() public {
        hook.setVerificationMode(ZKProofOfComplianceEnhanced.VerificationMode.EigenLayerOnly);

        IBrevisVerifier.ComplianceProof memory proof = _createProof(
            nonCompliantUser,
            nonCompliantDataHash
        );

        bytes memory hookData = abi.encode(proof);
        IPoolManager.PoolKey memory key = _createPoolKey();
        IPoolManager.SwapParams memory params = _createSwapParams();

        vm.prank(address(poolManager));
        vm.expectRevert(ZKProofOfComplianceEnhanced.AllVerificationMethodsFailed.selector);
        hook.beforeSwap(nonCompliantUser, key, params, hookData);
    }

    /// @notice Test verification mode update
    function test_UpdateVerificationMode() public {
        assertEq(
            uint256(hook.verificationMode()),
            uint256(ZKProofOfComplianceEnhanced.VerificationMode.Hybrid)
        );

        hook.setVerificationMode(ZKProofOfComplianceEnhanced.VerificationMode.BrevisOnly);

        assertEq(
            uint256(hook.verificationMode()),
            uint256(ZKProofOfComplianceEnhanced.VerificationMode.BrevisOnly)
        );
    }

    /// @notice Test beforeAddLiquidity with EigenLayer verification
    function test_BeforeAddLiquidity_EigenLayer() public {
        hook.setVerificationMode(ZKProofOfComplianceEnhanced.VerificationMode.EigenLayerOnly);

        IBrevisVerifier.ComplianceProof memory proof = _createProof(
            compliantUser,
            compliantDataHash
        );

        bytes32 requestId = hook.submitEigenLayerVerification(proof);
        vm.prank(operator);
        eigenLayerAVS.adminSetVerificationResult(requestId, true, compliantDataHash, "");

        bytes memory hookData = abi.encode(proof);
        IPoolManager.PoolKey memory key = _createPoolKey();
        IPoolManager.ModifyLiquidityParams memory params = _createLiquidityParams();

        vm.prank(address(poolManager));
        bytes4 selector = hook.beforeAddLiquidity(compliantUser, key, params, hookData);

        assertEq(selector, hook.beforeAddLiquidity.selector);
    }

    /// @notice Helper functions
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

    function _createPoolKey() internal view returns (IPoolManager.PoolKey memory) {
        return
            IPoolManager.PoolKey({
                currency0: address(0xA),
                currency1: address(0xB),
                fee: 3000,
                tickSpacing: 60,
                hooks: hook
            });
    }

    function _createSwapParams() internal pure returns (IPoolManager.SwapParams memory) {
        return
            IPoolManager.SwapParams({
                zeroForOne: true,
                amountSpecified: 1000,
                sqrtPriceLimitX96: 0
            });
    }

    function _createLiquidityParams()
        internal
        pure
        returns (IPoolManager.ModifyLiquidityParams memory)
    {
        return
            IPoolManager.ModifyLiquidityParams({
                tickLower: -100,
                tickUpper: 100,
                liquidityDelta: 1000
            });
    }
}

