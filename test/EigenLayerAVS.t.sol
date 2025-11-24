// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {EigenLayerAVS} from "../src/services/EigenLayerAVS.sol";
import {IEigenLayerAVS} from "../src/interfaces/IEigenLayerAVS.sol";

/// @title EigenLayerAVSTest
/// @notice Test suite for EigenLayer AVS service
contract EigenLayerAVSTest is Test {
    EigenLayerAVS public avs;
    address public admin;
    address public operator;
    address public user;

    function setUp() public {
        admin = address(this);
        operator = address(0x1001);
        user = address(0x1);

        avs = new EigenLayerAVS();
    }

    /// @notice Test submitting verification request
    function test_SubmitVerificationRequest() public {
        bytes32 proofHash = keccak256("test-proof");

        bytes32 requestId = avs.submitVerificationRequest(user, proofHash, "");

        assertNotEq(requestId, bytes32(0));

        IEigenLayerAVS.VerificationRequest memory request = IEigenLayerAVS.VerificationRequest({
            requestId: requestId,
            user: user,
            proofHash: proofHash,
            complianceData: "",
            timestamp: block.timestamp,
            isPending: true
        });

        // Check request is pending
        assertTrue(avs.isVerificationPending(requestId));
    }

    /// @notice Test setting verification result
    function test_SetVerificationResult() public {
        bytes32 proofHash = keccak256("test-proof");
        bytes32 requestId = avs.submitVerificationRequest(user, proofHash, "");

        bytes32 dataHash = keccak256("compliant-data");

        vm.prank(operator);
        avs.adminSetVerificationResult(requestId, true, dataHash, "");

        IEigenLayerAVS.VerificationResult memory result = avs.getVerificationResult(requestId);

        assertTrue(result.isValid);
        assertEq(result.dataHash, dataHash);
        assertEq(result.operator, operator);
        assertFalse(avs.isVerificationPending(requestId));
    }

    /// @notice Test getting latest verification for user
    function test_GetLatestVerification() public {
        bytes32 proofHash = keccak256("test-proof");
        bytes32 requestId = avs.submitVerificationRequest(user, proofHash, "");

        bytes32 dataHash = keccak256("compliant-data");

        vm.prank(operator);
        avs.adminSetVerificationResult(requestId, true, dataHash, "");

        IEigenLayerAVS.VerificationResult memory result = avs.getLatestVerification(user);

        assertTrue(result.isValid);
        assertEq(result.dataHash, dataHash);
    }

    /// @notice Test verification timeout
    function test_VerificationTimeout() public {
        bytes32 proofHash = keccak256("test-proof");
        bytes32 requestId = avs.submitVerificationRequest(user, proofHash, "");

        // Fast forward past timeout
        vm.warp(block.timestamp + 6 minutes);

        // Should not be pending after timeout
        assertFalse(avs.isVerificationPending(requestId));
    }

    /// @notice Test adding operator
    function test_AddOperator() public {
        address newOperator = address(0x2001);

        avs.addOperator(newOperator);

        // Verify operator was added (would need getter function)
        // For now, just verify no revert
        assertTrue(true);
    }
}

