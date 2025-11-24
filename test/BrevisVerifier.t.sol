// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {BrevisVerifier} from "../src/verifiers/BrevisVerifier.sol";
import {IBrevisVerifier} from "../src/interfaces/IBrevisVerifier.sol";
import {ComplianceData} from "../src/libraries/ComplianceData.sol";

/// @title BrevisVerifierTest
/// @notice Test suite for BrevisVerifier contract
contract BrevisVerifierTest is Test {
    BrevisVerifier public verifier;

    address public admin;
    address public user1;
    address public user2;

    bytes32 public compliantDataHash;
    bytes32 public nonCompliantDataHash;

    function setUp() public {
        admin = address(this);
        user1 = address(0x1);
        user2 = address(0x2);

        verifier = new BrevisVerifier();

        IBrevisVerifier.ComplianceData memory compliantData = ComplianceData.createCompliantData();
        compliantDataHash = ComplianceData.hashComplianceData(compliantData);

        IBrevisVerifier.ComplianceData memory nonCompliantData = ComplianceData
            .createNonCompliantData();
        nonCompliantDataHash = ComplianceData.hashComplianceData(nonCompliantData);
    }

    /// @notice Test setting user compliance
    function test_SetUserCompliance() public {
        verifier.setUserCompliance(user1, true, compliantDataHash);

        assertTrue(verifier.isUserCompliant(user1));
        assertEq(verifier.getUserComplianceHash(user1), compliantDataHash);
    }

    /// @notice Test batch setting user compliance
    function test_BatchSetUserCompliance() public {
        address[] memory users = new address[](2);
        users[0] = user1;
        users[1] = user2;

        bool[] memory compliant = new bool[](2);
        compliant[0] = true;
        compliant[1] = false;

        bytes32[] memory dataHashes = new bytes32[](2);
        dataHashes[0] = compliantDataHash;
        dataHashes[1] = nonCompliantDataHash;

        verifier.batchSetUserCompliance(users, compliant, dataHashes);

        assertTrue(verifier.isUserCompliant(user1));
        assertFalse(verifier.isUserCompliant(user2));
        assertEq(verifier.getUserComplianceHash(user1), compliantDataHash);
        assertEq(verifier.getUserComplianceHash(user2), nonCompliantDataHash);
    }

    /// @notice Test proof verification
    function test_VerifyProof() public {
        verifier.setUserCompliance(user1, true, compliantDataHash);

        IBrevisVerifier.ComplianceProof memory proof = IBrevisVerifier.ComplianceProof({
            proofHash: keccak256("test-proof"),
            publicInputs: abi.encode(compliantDataHash),
            timestamp: block.timestamp,
            user: user1
        });

        (bool isValid, bytes32 dataHash) = verifier.verifyProof(proof, compliantDataHash);

        assertTrue(isValid);
        assertEq(dataHash, compliantDataHash);
    }

    /// @notice Test proof verification with wrong hash
    function test_VerifyProof_WrongHash() public {
        verifier.setUserCompliance(user1, true, compliantDataHash);

        IBrevisVerifier.ComplianceProof memory proof = IBrevisVerifier.ComplianceProof({
            proofHash: keccak256("test-proof"),
            publicInputs: abi.encode(compliantDataHash),
            timestamp: block.timestamp,
            user: user1
        });

        (bool isValid, ) = verifier.verifyProof(proof, nonCompliantDataHash);

        assertFalse(isValid);
    }

    /// @notice Test proof verification with wrong user
    function test_VerifyProof_WrongUser() public {
        verifier.setUserCompliance(user1, true, compliantDataHash);

        IBrevisVerifier.ComplianceProof memory proof = IBrevisVerifier.ComplianceProof({
            proofHash: keccak256("test-proof"),
            publicInputs: abi.encode(compliantDataHash),
            timestamp: block.timestamp,
            user: user2 // Wrong user
        });

        vm.prank(user1);
        (bool isValid, ) = verifier.verifyProof(proof, compliantDataHash);

        assertFalse(isValid);
    }

    /// @notice Test expired proof
    function test_ExpiredProof() public {
        verifier.setUserCompliance(user1, true, compliantDataHash);

        IBrevisVerifier.ComplianceProof memory proof = IBrevisVerifier.ComplianceProof({
            proofHash: keccak256("test-proof"),
            publicInputs: abi.encode(compliantDataHash),
            timestamp: uint256(block.timestamp - 31 days), // Expired
            user: user1
        });

        vm.prank(user1);
        vm.expectRevert("BrevisVerifier: proof expired");
        verifier.verifyProof(proof, compliantDataHash);
    }

    /// @notice Test proof replay protection
    function test_ProofReplayProtection() public {
        verifier.setUserCompliance(user1, true, compliantDataHash);

        IBrevisVerifier.ComplianceProof memory proof = IBrevisVerifier.ComplianceProof({
            proofHash: keccak256("test-proof"),
            publicInputs: abi.encode(compliantDataHash),
            timestamp: block.timestamp,
            user: user1
        });

        vm.prank(user1);
        verifier.verifyAndRecordProof(proof, compliantDataHash);

        // Try to use the same proof again
        vm.prank(user1);
        vm.expectRevert("BrevisVerifier: proof already used");
        verifier.verifyAndRecordProof(proof, compliantDataHash);
    }

    /// @notice Test that only admin can set compliance
    function test_OnlyAdminCanSetCompliance() public {
        vm.prank(user1);
        vm.expectRevert("BrevisVerifier: not admin");
        verifier.setUserCompliance(user1, true, compliantDataHash);
    }
}

