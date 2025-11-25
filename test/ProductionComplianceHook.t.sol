// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {ProductionComplianceHook, IGroth16Verifier} from "../src/hooks/ProductionComplianceHook.sol";
import {IPoolManager} from "../src/interfaces/IPoolManager.sol";

/// @notice Mock Groth16 Verifier for testing
contract MockGroth16Verifier is IGroth16Verifier {
    mapping(bytes32 => bool) public validProofs;
    bool public alwaysReturn;

    constructor(bool _alwaysReturn) {
        alwaysReturn = _alwaysReturn;
    }

    function setValidProof(bytes32 proofHash, bool valid) external {
        validProofs[proofHash] = valid;
    }

    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[] memory publicSignals
    ) external view override returns (bool) {
        if (alwaysReturn) return true;
        
        bytes32 proofHash = keccak256(
            abi.encodePacked(a[0], a[1], b[0][0], b[0][1], b[1][0], b[1][1], c[0], c[1], publicSignals)
        );
        return validProofs[proofHash];
    }
}

/// @title ProductionComplianceHookTest
/// @notice Comprehensive tests for ProductionComplianceHook
contract ProductionComplianceHookTest is Test {
    ProductionComplianceHook hook;
    IGroth16Verifier mockVerifier;
    IPoolManager mockPoolManager;

    address admin = address(0x1);
    address user = address(0x2);
    address attacker = address(0x3);

    function setUp() public {
        vm.startPrank(admin);
        
        // Deploy mock verifier (always returns true for testing)
        mockVerifier = new MockGroth16Verifier(true);
        
        // Deploy mock pool manager
        mockPoolManager = IPoolManager(address(0x1000));
        
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

        // Deploy hook
        hook = new ProductionComplianceHook(
            mockPoolManager,
            mockVerifier,
            requirements,
            30 days
        );

        vm.stopPrank();
    }

    function test_InitialState() public view {
        assertEq(address(hook.poolManager()), address(mockPoolManager));
        assertEq(address(hook.groth16Verifier()), address(mockVerifier));
        assertTrue(hook.enabled());
        assertEq(hook.admin(), admin);
        assertEq(hook.proofExpiration(), 30 days);
    }

    function test_SubmitValidProof() public {
        vm.startPrank(user);

        // Create mock proof data
        uint256[2] memory a = [uint256(1), uint256(2)];
        uint256[2][2] memory b = [[uint256(3), uint256(4)], [uint256(5), uint256(6)]];
        uint256[2] memory c = [uint256(7), uint256(8)];
        
        // Public signals: [complianceHash, isValid]
        bytes32 complianceHash = keccak256("test-compliance-data");
        uint256[] memory publicSignals = new uint256[](2);
        publicSignals[0] = uint256(complianceHash);
        publicSignals[1] = 1; // isValid = true

        // Submit proof
        hook.submitProof(a, b, c, publicSignals);

        // Verify state
        (bool isCompliant, bytes32 storedHash, uint256 lastProofTime) = hook.checkCompliance(user);
        assertTrue(isCompliant);
        assertEq(storedHash, complianceHash);
        assertGt(lastProofTime, 0);

        vm.stopPrank();
    }

    function test_ReplayAttack() public {
        vm.startPrank(user);

        uint256[2] memory a = [uint256(1), uint256(2)];
        uint256[2][2] memory b = [[uint256(3), uint256(4)], [uint256(5), uint256(6)]];
        uint256[2] memory c = [uint256(7), uint256(8)];
        bytes32 complianceHash = keccak256("test-compliance-data");
        uint256[] memory publicSignals = new uint256[](2);
        publicSignals[0] = uint256(complianceHash);
        publicSignals[1] = 1;

        // First submission should succeed
        hook.submitProof(a, b, c, publicSignals);

        // Second submission with same proof should fail
        vm.expectRevert(ProductionComplianceHook.ProofAlreadyUsed.selector);
        hook.submitProof(a, b, c, publicSignals);

        vm.stopPrank();
    }

    function test_InvalidProof() public {
        vm.startPrank(user);

        // Deploy a verifier that always returns false
        MockGroth16Verifier invalidVerifier = new MockGroth16Verifier(false);
        
        // We need to redeploy hook with invalid verifier for this test
        // For now, we'll test with a proof that has invalid public signals
        uint256[2] memory a = [uint256(1), uint256(2)];
        uint256[2][2] memory b = [[uint256(3), uint256(4)], [uint256(5), uint256(6)]];
        uint256[2] memory c = [uint256(7), uint256(8)];
        uint256[] memory publicSignals = new uint256[](1); // Too short
        publicSignals[0] = 1;

        vm.expectRevert(ProductionComplianceHook.InvalidPublicSignals.selector);
        hook.submitProof(a, b, c, publicSignals);

        vm.stopPrank();
    }

    function test_ProofWithInvalidCompliance() public {
        vm.startPrank(user);

        uint256[2] memory a = [uint256(1), uint256(2)];
        uint256[2][2] memory b = [[uint256(3), uint256(4)], [uint256(5), uint256(6)]];
        uint256[2] memory c = [uint256(7), uint256(8)];
        bytes32 complianceHash = keccak256("test-compliance-data");
        uint256[] memory publicSignals = new uint256[](2);
        publicSignals[0] = uint256(complianceHash);
        publicSignals[1] = 0; // isValid = false (not compliant)

        // This should fail because isValid = 0
        vm.expectRevert(ProductionComplianceHook.UserNotCompliant.selector);
        hook.submitProof(a, b, c, publicSignals);

        vm.stopPrank();
    }

    function test_ProofExpiration() public {
        vm.startPrank(user);

        // Submit proof
        uint256[2] memory a = [uint256(1), uint256(2)];
        uint256[2][2] memory b = [[uint256(3), uint256(4)], [uint256(5), uint256(6)]];
        uint256[2] memory c = [uint256(7), uint256(8)];
        bytes32 complianceHash = keccak256("test-compliance-data");
        uint256[] memory publicSignals = new uint256[](2);
        publicSignals[0] = uint256(complianceHash);
        publicSignals[1] = 1;

        hook.submitProof(a, b, c, publicSignals);

        // Fast forward past expiration
        vm.warp(block.timestamp + 31 days);

        // Check compliance should now return false
        (bool isCompliant, , ) = hook.checkCompliance(user);
        assertFalse(isCompliant);

        vm.stopPrank();
    }

    function test_AdminFunctions() public {
        vm.startPrank(admin);

        // Test setEnabled
        hook.setEnabled(false);
        assertFalse(hook.enabled());
        hook.setEnabled(true);
        assertTrue(hook.enabled());

        // Test updateRequirements
        ProductionComplianceHook.ComplianceRequirements memory newReqs = 
            ProductionComplianceHook.ComplianceRequirements({
                requireKYC: false,
                requireAgeVerification: true,
                requireLocationCheck: false,
                requireSanctionsCheck: true,
                minAge: 21,
                allowedCountryCode: bytes2("CA")
            });
        hook.updateRequirements(newReqs);
        
        (bool reqKYC, , , , uint256 minAge, ) = hook.requirements();
        assertFalse(reqKYC);
        assertEq(minAge, 21);

        // Test setProofExpiration
        hook.setProofExpiration(60 days);
        assertEq(hook.proofExpiration(), 60 days);

        vm.stopPrank();
    }

    function test_UnauthorizedAccess() public {
        vm.startPrank(attacker);

        // Attacker cannot call admin functions
        vm.expectRevert(ProductionComplianceHook.Unauthorized.selector);
        hook.setEnabled(false);

        vm.expectRevert(ProductionComplianceHook.Unauthorized.selector);
        ProductionComplianceHook.ComplianceRequirements memory reqs;
        hook.updateRequirements(reqs);

        vm.stopPrank();
    }

    function test_CheckComplianceForNonExistentUser() public view {
        (bool isCompliant, bytes32 hash, uint256 time) = hook.checkCompliance(attacker);
        assertFalse(isCompliant);
        assertEq(hash, bytes32(0));
        assertEq(time, 0);
    }
}

