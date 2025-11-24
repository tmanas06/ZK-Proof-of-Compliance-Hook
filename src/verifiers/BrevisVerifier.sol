// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IBrevisVerifier} from "../interfaces/IBrevisVerifier.sol";

/// @title BrevisVerifier
/// @notice Mock implementation of Brevis ZK proof verifier for demonstration
/// @dev In production, this would integrate with actual Brevis verification contracts
/// This mock allows testing and demonstration without requiring a full Brevis setup
contract BrevisVerifier is IBrevisVerifier {
    /// @notice Mapping from user address to their compliance data hash
    mapping(address => bytes32) private userComplianceHashes;

    /// @notice Mapping from proof hash to whether it's been used (replay protection)
    mapping(bytes32 => bool) private usedProofs;

    /// @notice Mapping from user address to compliance status
    mapping(address => bool) private compliantUsers;

    /// @notice Admin address that can set compliance status (for testing)
    address public admin;

    /// @notice Proof expiration time (e.g., 30 days)
    uint256 public constant PROOF_EXPIRATION = 30 days;

    event ProofVerified(address indexed user, bytes32 proofHash, bytes32 dataHash);
    event UserComplianceSet(address indexed user, bool compliant, bytes32 dataHash);

    modifier onlyAdmin() {
        require(msg.sender == admin, "BrevisVerifier: not admin");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    /// @notice Verify a compliance proof
    /// @param proof The compliance proof to verify
    /// @param expectedDataHash Hash of expected compliance data
    /// @return isValid True if proof is valid
    /// @return dataHash Hash of the verified compliance data
    function verifyProof(
        ComplianceProof calldata proof,
        bytes32 expectedDataHash
    ) external view override returns (bool isValid, bytes32 dataHash) {
        // Check proof hasn't expired
        if (block.timestamp > proof.timestamp + PROOF_EXPIRATION) {
            return (false, bytes32(0));
        }

        // Note: Replay protection is handled by the hook contract
        // We don't check usedProofs here to avoid conflicts with hook's own tracking

        // In a real implementation, this would verify the ZK proof using Brevis contracts
        // For this mock, we verify that:
        // 1. The proof hash is valid (non-zero)
        // 2. The expected data hash matches the user's compliance hash
        // Note: We don't check proof.user == msg.sender because the hook calls this,
        // and msg.sender would be the hook contract, not the user

        if (proof.proofHash == bytes32(0)) {
            return (false, bytes32(0));
        }

        // Get the user's compliance hash from storage
        dataHash = userComplianceHashes[proof.user];
        
        // If no hash is stored for this user, they're not compliant
        if (dataHash == bytes32(0)) {
            return (false, bytes32(0));
        }

        // Verify the stored hash matches the expected hash
        isValid = (dataHash == expectedDataHash);
    }

    /// @notice Verify and record a proof (marks it as used)
    /// @param proof The compliance proof to verify and record
    /// @param expectedDataHash Hash of expected compliance data
    /// @return isValid True if proof is valid
    function verifyAndRecordProof(
        ComplianceProof calldata proof,
        bytes32 expectedDataHash
    ) external returns (bool isValid) {
        bytes32 dataHash;
        (isValid, dataHash) = this.verifyProof(proof, expectedDataHash);

        if (isValid) {
            // Mark proof as used to prevent replay attacks
            usedProofs[proof.proofHash] = true;
            emit ProofVerified(proof.user, proof.proofHash, dataHash);
        }
    }

    /// @notice Get the compliance data hash for a user
    /// @param user The user address
    /// @return dataHash The hash of the user's compliance data
    function getUserComplianceHash(address user) external view override returns (bytes32 dataHash) {
        return userComplianceHashes[user];
    }

    /// @notice Check if a user is compliant
    /// @param user The user address
    /// @return isCompliant True if user is compliant
    function isUserCompliant(address user) external view override returns (bool isCompliant) {
        return compliantUsers[user];
    }

    /// @notice Set user compliance status (admin only, for testing)
    /// @param user The user address
    /// @param compliant Whether the user is compliant
    /// @param dataHash The hash of the user's compliance data
    function setUserCompliance(
        address user,
        bool compliant,
        bytes32 dataHash
    ) external onlyAdmin {
        compliantUsers[user] = compliant;
        userComplianceHashes[user] = dataHash;
        emit UserComplianceSet(user, compliant, dataHash);
    }

    /// @notice Batch set user compliance status (admin only, for testing)
    /// @param users Array of user addresses
    /// @param compliant Array of compliance statuses
    /// @param dataHashes Array of compliance data hashes
    function batchSetUserCompliance(
        address[] calldata users,
        bool[] calldata compliant,
        bytes32[] calldata dataHashes
    ) external onlyAdmin {
        require(
            users.length == compliant.length && users.length == dataHashes.length,
            "BrevisVerifier: array length mismatch"
        );

        for (uint256 i = 0; i < users.length; i++) {
            compliantUsers[users[i]] = compliant[i];
            userComplianceHashes[users[i]] = dataHashes[i];
            emit UserComplianceSet(users[i], compliant[i], dataHashes[i]);
        }
    }

    /// @notice Check if a proof has been used
    /// @param proofHash The proof hash to check
    /// @return used True if proof has been used
    function isProofUsed(bytes32 proofHash) external view returns (bool used) {
        return usedProofs[proofHash];
    }
}

