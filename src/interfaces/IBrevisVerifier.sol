// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title IBrevisVerifier
/// @notice Interface for Brevis ZK proof verification
/// @dev This interface abstracts the Brevis verification system
interface IBrevisVerifier {
    /// @notice Compliance proof structure
    struct ComplianceProof {
        bytes32 proofHash; // Hash of the ZK proof
        bytes publicInputs; // Public inputs to the proof
        uint256 timestamp; // Timestamp when proof was generated
        address user; // User address this proof is for
    }

    /// @notice Compliance data structure (what the proof verifies)
    struct ComplianceData {
        bool kycPassed; // KYC verification status
        bool ageVerified; // Age >= 18 verification
        bool locationAllowed; // Geographic location allowed
        bool notSanctioned; // Not on sanctions list
        uint256 age; // User's age (if applicable)
        string countryCode; // ISO country code (if applicable)
    }

    /// @notice Verify a compliance proof
    /// @param proof The compliance proof to verify
    /// @param expectedDataHash Hash of expected compliance data
    /// @return isValid True if proof is valid
    /// @return dataHash Hash of the verified compliance data
    function verifyProof(
        ComplianceProof calldata proof,
        bytes32 expectedDataHash
    ) external view returns (bool isValid, bytes32 dataHash);

    /// @notice Get the compliance data hash for a user
    /// @param user The user address
    /// @return dataHash The hash of the user's compliance data
    function getUserComplianceHash(address user) external view returns (bytes32 dataHash);

    /// @notice Check if a user is compliant
    /// @param user The user address
    /// @return isCompliant True if user is compliant
    function isUserCompliant(address user) external view returns (bool isCompliant);
}

