// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IEigenLayerAVS} from "../interfaces/IEigenLayerAVS.sol";

/// @title EigenLayerAVS
/// @notice Mock implementation of EigenLayer AVS for off-chain proof verification
/// @dev In production, this would interact with actual EigenLayer AVS operators
/// This mock allows testing and demonstration without requiring a full EigenLayer setup
contract EigenLayerAVS is IEigenLayerAVS {
    /// @notice Mapping from request ID to verification request
    mapping(bytes32 => VerificationRequest) private requests;

    /// @notice Mapping from request ID to verification result
    mapping(bytes32 => VerificationResult) private results;

    /// @notice Mapping from user address to latest request ID
    mapping(address => bytes32) private userLatestRequest;

    /// @notice Admin address that can set verification results (for testing)
    address public admin;

    /// @notice Mock EigenLayer operator addresses
    address[] public operators;

    /// @notice Verification timeout (e.g., 5 minutes)
    uint256 public constant VERIFICATION_TIMEOUT = 5 minutes;

    modifier onlyAdmin() {
        require(msg.sender == admin, "EigenLayerAVS: not admin");
        _;
    }

    modifier onlyOperator() {
        require(_isOperator(msg.sender), "EigenLayerAVS: not operator");
        _;
    }

    constructor() {
        admin = msg.sender;
        // Initialize with mock operators
        operators.push(address(0x1001));
        operators.push(address(0x1002));
        operators.push(address(0x1003));
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
    ) external override returns (bytes32 requestId) {
        requestId = keccak256(
            abi.encodePacked(user, proofHash, block.timestamp, block.number, msg.sender)
        );

        requests[requestId] = VerificationRequest({
            requestId: requestId,
            user: user,
            proofHash: proofHash,
            complianceData: complianceData,
            timestamp: block.timestamp,
            isPending: true
        });

        userLatestRequest[user] = requestId;

        emit VerificationRequestSubmitted(requestId, user, proofHash, block.timestamp);

        // In production, this would trigger off-chain verification by EigenLayer operators
        // For mock, we simulate async verification
        _simulateAsyncVerification(requestId, user, proofHash);
    }

    /// @notice Get verification result for a request
    /// @param requestId The verification request identifier
    /// @return result The verification result, or empty if pending
    function getVerificationResult(
        bytes32 requestId
    ) external view override returns (VerificationResult memory result) {
        return results[requestId];
    }

    /// @notice Check if a verification request is pending
    /// @param requestId The verification request identifier
    /// @return isPending True if verification is still pending
    function isVerificationPending(bytes32 requestId) external view override returns (bool isPending) {
        VerificationRequest memory request = requests[requestId];
        if (request.requestId == bytes32(0)) {
            return false; // Request doesn't exist
        }
        if (block.timestamp > request.timestamp + VERIFICATION_TIMEOUT) {
            return false; // Request timed out
        }
        return request.isPending && results[requestId].requestId == bytes32(0);
    }

    /// @notice Get the latest verification result for a user
    /// @param user The user address
    /// @return result The latest verification result, or empty if none exists
    function getLatestVerification(
        address user
    ) external view override returns (VerificationResult memory result) {
        bytes32 requestId = userLatestRequest[user];
        if (requestId != bytes32(0)) {
            return results[requestId];
        }
        // Return empty result
        return VerificationResult({
            requestId: bytes32(0),
            isValid: false,
            dataHash: bytes32(0),
            timestamp: 0,
            operator: address(0),
            reason: ""
        });
    }

    /// @notice Set verification result (admin/operator only, for testing)
    /// @param requestId The verification request identifier
    /// @param isValid Whether the proof is valid
    /// @param dataHash Hash of verified compliance data
    /// @param reason Reason if invalid (empty if valid)
    function setVerificationResult(
        bytes32 requestId,
        bool isValid,
        bytes32 dataHash,
        string calldata reason
    ) external onlyOperator {
        require(requests[requestId].requestId != bytes32(0), "EigenLayerAVS: request not found");
        require(requests[requestId].isPending, "EigenLayerAVS: request already processed");

        results[requestId] = VerificationResult({
            requestId: requestId,
            isValid: isValid,
            dataHash: dataHash,
            timestamp: block.timestamp,
            operator: msg.sender,
            reason: reason
        });

        requests[requestId].isPending = false;

        emit VerificationResultAvailable(
            requestId,
            requests[requestId].user,
            isValid,
            dataHash,
            msg.sender
        );
    }

    /// @notice Admin function to set verification result (for testing)
    function adminSetVerificationResult(
        bytes32 requestId,
        bool isValid,
        bytes32 dataHash,
        string calldata reason
    ) external onlyAdmin {
        require(requests[requestId].requestId != bytes32(0), "EigenLayerAVS: request not found");

        results[requestId] = VerificationResult({
            requestId: requestId,
            isValid: isValid,
            dataHash: dataHash,
            timestamp: block.timestamp,
            operator: msg.sender,
            reason: reason
        });

        requests[requestId].isPending = false;

        emit VerificationResultAvailable(
            requestId,
            requests[requestId].user,
            isValid,
            dataHash,
            msg.sender
        );
    }

    /// @notice Add an operator (admin only)
    function addOperator(address operator) external onlyAdmin {
        require(!_isOperator(operator), "EigenLayerAVS: operator already exists");
        operators.push(operator);
    }

    /// @notice Check if address is an operator
    function _isOperator(address addr) internal view returns (bool) {
        for (uint256 i = 0; i < operators.length; i++) {
            if (operators[i] == addr) {
                return true;
            }
        }
        return false;
    }

    /// @notice Simulate async verification (mock implementation)
    /// @dev In production, this would be handled by EigenLayer operators off-chain
    function _simulateAsyncVerification(bytes32 requestId, address user, bytes32 proofHash) internal {
        // In a real implementation, this would trigger off-chain verification
        // For mock, we'll leave it pending and let admin/operator set results
        // This simulates the asynchronous nature of EigenLayer AVS verification
    }
}

