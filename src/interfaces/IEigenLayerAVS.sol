// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title IEigenLayerAVS
/// @notice Interface for EigenLayer AVS (Actively Validated Service) for decentralized proof validation
/// @dev This interface allows the hook to query off-chain verification results from EigenLayer operators
interface IEigenLayerAVS {
    /// @notice Verification request structure
    struct VerificationRequest {
        bytes32 requestId; // Unique request identifier
        address user; // User address being verified
        bytes32 proofHash; // Hash of the ZK proof
        bytes complianceData; // Encrypted compliance data (if using Fhenix)
        uint256 timestamp; // Request timestamp
        bool isPending; // Whether verification is still pending
    }

    /// @notice Verification result structure
    struct VerificationResult {
        bytes32 requestId; // Request identifier
        bool isValid; // Whether the proof is valid
        bytes32 dataHash; // Hash of verified compliance data
        uint256 timestamp; // Verification timestamp
        address operator; // EigenLayer operator that verified
        string reason; // Reason if invalid (empty if valid)
    }

    /// @notice Submit a verification request to EigenLayer AVS
    /// @param user The user address to verify
    /// @param proofHash Hash of the ZK proof
    /// @param complianceData Encrypted compliance data (optional, for Fhenix)
    /// @return requestId Unique identifier for the verification request
    function submitVerificationRequest(
        address user,
        bytes32 proofHash,
        bytes calldata complianceData
    ) external returns (bytes32 requestId);

    /// @notice Get verification result for a request
    /// @param requestId The verification request identifier
    /// @return result The verification result, or empty if pending
    function getVerificationResult(
        bytes32 requestId
    ) external view returns (VerificationResult memory result);

    /// @notice Check if a verification request is pending
    /// @param requestId The verification request identifier
    /// @return isPending True if verification is still pending
    function isVerificationPending(bytes32 requestId) external view returns (bool isPending);

    /// @notice Get the latest verification result for a user
    /// @param user The user address
    /// @return result The latest verification result, or empty if none exists
    function getLatestVerification(
        address user
    ) external view returns (VerificationResult memory result);

    /// @notice Event emitted when a verification request is submitted
    event VerificationRequestSubmitted(
        bytes32 indexed requestId,
        address indexed user,
        bytes32 proofHash,
        uint256 timestamp
    );

    /// @notice Event emitted when a verification result is available
    event VerificationResultAvailable(
        bytes32 indexed requestId,
        address indexed user,
        bool isValid,
        bytes32 dataHash,
        address operator
    );
}

