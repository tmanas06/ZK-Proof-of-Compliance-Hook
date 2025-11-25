// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IEigenLayerAVS} from "../interfaces/IEigenLayerAVS.sol";

/// @title RealEigenLayerAVS
/// @notice Real implementation of EigenLayer AVS with state machine, retry, and timeout mechanisms
/// @dev This contract handles off-chain verification requests and on-chain result processing
contract RealEigenLayerAVS is IEigenLayerAVS {
    /// @notice Verification state enum
    enum VerificationState {
        Pending,        // Initial state - request submitted
        Processing,     // Off-chain verification in progress
        Verified,       // Verification successful
        Failed,         // Verification failed
        Timeout,        // Verification timed out
        Retrying        // Retry in progress
    }

    /// @notice Enhanced verification request with state tracking
    struct EnhancedVerificationRequest {
        VerificationRequest request;
        VerificationState state;
        uint256 retryCount;
        uint256 lastRetryTimestamp;
        address[] operatorVotes; // Operators who have verified
        mapping(address => bool) hasVoted; // Track operator votes
    }

    /// @notice Mapping from request ID to enhanced request
    mapping(bytes32 => EnhancedVerificationRequest) private enhancedRequests;

    /// @notice Mapping from request ID to verification result
    mapping(bytes32 => VerificationResult) private results;

    /// @notice Mapping from user address to latest request ID
    mapping(address => bytes32) private userLatestRequest;

    /// @notice Admin address
    address public admin;

    /// @notice EigenLayer operator addresses
    address[] public operators;

    /// @notice Minimum number of operator confirmations required
    uint256 public minOperatorConfirmations;

    /// @notice Verification timeout (default: 5 minutes)
    uint256 public verificationTimeout;

    /// @notice Maximum retry attempts
    uint256 public maxRetries;

    /// @notice Retry delay (time between retries)
    uint256 public retryDelay;

    /// @notice Event emitted when verification state changes
    event VerificationStateChanged(
        bytes32 indexed requestId,
        VerificationState oldState,
        VerificationState newState
    );

    /// @notice Event emitted when operator votes
    event OperatorVoted(
        bytes32 indexed requestId,
        address indexed operator,
        bool isValid
    );

    modifier onlyAdmin() {
        require(msg.sender == admin, "RealEigenLayerAVS: not admin");
        _;
    }

    modifier onlyOperator() {
        require(_isOperator(msg.sender), "RealEigenLayerAVS: not operator");
        _;
    }

    constructor(
        address[] memory _operators,
        uint256 _minOperatorConfirmations,
        uint256 _verificationTimeout,
        uint256 _maxRetries,
        uint256 _retryDelay
    ) {
        admin = msg.sender;
        operators = _operators;
        minOperatorConfirmations = _minOperatorConfirmations;
        verificationTimeout = _verificationTimeout;
        maxRetries = _maxRetries;
        retryDelay = _retryDelay;
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

        VerificationRequest memory request = VerificationRequest({
            requestId: requestId,
            user: user,
            proofHash: proofHash,
            complianceData: complianceData,
            timestamp: block.timestamp,
            isPending: true
        });

        EnhancedVerificationRequest storage enhancedRequest = enhancedRequests[requestId];
        enhancedRequest.request = request;
        enhancedRequest.state = VerificationState.Pending;
        enhancedRequest.retryCount = 0;
        enhancedRequest.lastRetryTimestamp = 0;

        userLatestRequest[user] = requestId;

        emit VerificationRequestSubmitted(requestId, user, proofHash, block.timestamp);
        emit VerificationStateChanged(requestId, VerificationState.Pending, VerificationState.Pending);

        // Trigger off-chain verification (in production, this would call EigenLayer API)
        _triggerOffChainVerification(requestId, user, proofHash, complianceData);
    }

    /// @notice Submit operator verification result
    /// @param requestId The verification request identifier
    /// @param isValid Whether the proof is valid
    /// @param dataHash Hash of verified compliance data
    /// @param reason Reason if invalid (empty if valid)
    function submitOperatorResult(
        bytes32 requestId,
        bool isValid,
        bytes32 dataHash,
        string calldata reason
    ) external onlyOperator {
        EnhancedVerificationRequest storage enhancedRequest = enhancedRequests[requestId];
        require(enhancedRequest.request.requestId != bytes32(0), "RealEigenLayerAVS: request not found");
        require(!enhancedRequest.hasVoted[msg.sender], "RealEigenLayerAVS: operator already voted");

        // Record vote
        enhancedRequest.hasVoted[msg.sender] = true;
        enhancedRequest.operatorVotes.push(msg.sender);

        emit OperatorVoted(requestId, msg.sender, isValid);

        // Update state to Processing if still Pending
        if (enhancedRequest.state == VerificationState.Pending) {
            enhancedRequest.state = VerificationState.Processing;
            emit VerificationStateChanged(requestId, VerificationState.Pending, VerificationState.Processing);
        }

        // Check if we have enough confirmations
        if (enhancedRequest.operatorVotes.length >= minOperatorConfirmations) {
            _finalizeVerification(requestId, isValid, dataHash, reason);
        }
    }

    /// @notice Retry a failed or timed-out verification
    /// @param requestId The verification request identifier
    function retryVerification(bytes32 requestId) external {
        EnhancedVerificationRequest storage enhancedRequest = enhancedRequests[requestId];
        require(enhancedRequest.request.requestId != bytes32(0), "RealEigenLayerAVS: request not found");
        require(
            enhancedRequest.state == VerificationState.Failed ||
            enhancedRequest.state == VerificationState.Timeout,
            "RealEigenLayerAVS: cannot retry in current state"
        );
        require(enhancedRequest.retryCount < maxRetries, "RealEigenLayerAVS: max retries exceeded");
        require(
            block.timestamp >= enhancedRequest.lastRetryTimestamp + retryDelay,
            "RealEigenLayerAVS: retry delay not met"
        );

        VerificationState oldState = enhancedRequest.state;
        enhancedRequest.state = VerificationState.Retrying;
        enhancedRequest.retryCount++;
        enhancedRequest.lastRetryTimestamp = block.timestamp;
        
        // Reset operator votes for retry
        delete enhancedRequest.operatorVotes;
        for (uint256 i = 0; i < operators.length; i++) {
            enhancedRequest.hasVoted[operators[i]] = false;
        }

        emit VerificationStateChanged(requestId, oldState, VerificationState.Retrying);

        // Trigger off-chain verification again
        _triggerOffChainVerification(
            requestId,
            enhancedRequest.request.user,
            enhancedRequest.request.proofHash,
            enhancedRequest.request.complianceData
        );
    }

    /// @notice Check and handle timeouts
    /// @param requestId The verification request identifier
    function checkTimeout(bytes32 requestId) external {
        EnhancedVerificationRequest storage enhancedRequest = enhancedRequests[requestId];
        require(enhancedRequest.request.requestId != bytes32(0), "RealEigenLayerAVS: request not found");
        
        if (
            (enhancedRequest.state == VerificationState.Pending ||
             enhancedRequest.state == VerificationState.Processing ||
             enhancedRequest.state == VerificationState.Retrying) &&
            block.timestamp > enhancedRequest.request.timestamp + verificationTimeout
        ) {
            VerificationState oldState = enhancedRequest.state;
            enhancedRequest.state = VerificationState.Timeout;
            emit VerificationStateChanged(requestId, oldState, VerificationState.Timeout);
        }
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
        EnhancedVerificationRequest storage enhancedRequest = enhancedRequests[requestId];
        if (enhancedRequest.request.requestId == bytes32(0)) {
            return false;
        }
        
        VerificationState state = enhancedRequest.state;
        return state == VerificationState.Pending ||
               state == VerificationState.Processing ||
               state == VerificationState.Retrying;
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
        return VerificationResult({
            requestId: bytes32(0),
            isValid: false,
            dataHash: bytes32(0),
            timestamp: 0,
            operator: address(0),
            reason: ""
        });
    }

    /// @notice Get verification state for a request
    /// @param requestId The verification request identifier
    /// @return state The current verification state
    /// @return retryCount Number of retry attempts
    /// @return operatorVoteCount Number of operator votes received
    function getVerificationState(bytes32 requestId) external view returns (
        VerificationState state,
        uint256 retryCount,
        uint256 operatorVoteCount
    ) {
        EnhancedVerificationRequest storage enhancedRequest = enhancedRequests[requestId];
        return (
            enhancedRequest.state,
            enhancedRequest.retryCount,
            enhancedRequest.operatorVotes.length
        );
    }

    /// @notice Internal function to finalize verification
    function _finalizeVerification(
        bytes32 requestId,
        bool isValid,
        bytes32 dataHash,
        string memory reason
    ) internal {
        EnhancedVerificationRequest storage enhancedRequest = enhancedRequests[requestId];
        
        results[requestId] = VerificationResult({
            requestId: requestId,
            isValid: isValid,
            dataHash: dataHash,
            timestamp: block.timestamp,
            operator: msg.sender,
            reason: reason
        });

        VerificationState oldState = enhancedRequest.state;
        enhancedRequest.state = isValid ? VerificationState.Verified : VerificationState.Failed;
        enhancedRequest.request.isPending = false;

        emit VerificationStateChanged(requestId, oldState, enhancedRequest.state);
        emit VerificationResultAvailable(
            requestId,
            enhancedRequest.request.user,
            isValid,
            dataHash,
            msg.sender
        );
    }

    /// @notice Trigger off-chain verification (in production, calls EigenLayer API)
    function _triggerOffChainVerification(
        bytes32 requestId,
        address user,
        bytes32 proofHash,
        bytes memory complianceData
    ) internal {
        // In production, this would:
        // 1. Make an API call to EigenLayer AVS service
        // 2. Submit the verification request to operators
        // 3. Set up event listeners for results
        // For now, this is a placeholder that operators will call manually
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

    /// @notice Admin function to add operator
    function addOperator(address operator) external onlyAdmin {
        require(!_isOperator(operator), "RealEigenLayerAVS: operator already exists");
        operators.push(operator);
    }

    /// @notice Admin function to update configuration
    function updateConfig(
        uint256 _minOperatorConfirmations,
        uint256 _verificationTimeout,
        uint256 _maxRetries,
        uint256 _retryDelay
    ) external onlyAdmin {
        minOperatorConfirmations = _minOperatorConfirmations;
        verificationTimeout = _verificationTimeout;
        maxRetries = _maxRetries;
        retryDelay = _retryDelay;
    }
}

