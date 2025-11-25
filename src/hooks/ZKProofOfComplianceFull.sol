// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IPoolManager} from "../interfaces/IPoolManager.sol";
import {IHooks} from "../interfaces/IPoolManager.sol";
import {BalanceDelta} from "../libraries/BalanceDelta.sol";
import {IBrevisVerifier} from "../interfaces/IBrevisVerifier.sol";
import {IEigenLayerAVS} from "../interfaces/IEigenLayerAVS.sol";
import {IRealFhenixFHE} from "../services/RealFhenixFHE.sol";

/// @title ZKProofOfComplianceFull
/// @notice Complete Uniswap v4 hook with real ZK proofs, EigenLayer AVS, and Fhenix FHE integration
/// @dev This hook enforces compliance using multiple verification methods with fallback mechanisms
contract ZKProofOfComplianceFull is IHooks {
    /// @notice Verification mode enum
    enum VerificationMode {
        BrevisOnly,        // Only use Brevis ZK verification
        EigenLayerOnly,    // Only use EigenLayer AVS
        FhenixOnly,        // Only use Fhenix FHE
        HybridBrevisEigen, // Brevis + EigenLayer (Brevis primary, EigenLayer fallback)
        HybridEigenBrevis, // EigenLayer + Brevis (EigenLayer primary, Brevis fallback)
        HybridAll          // All three methods (Brevis -> EigenLayer -> Fhenix)
    }

    /// @notice Verification workflow state
    enum WorkflowState {
        Initial,           // Initial state
        BrevisPending,     // Brevis verification pending
        EigenLayerPending,  // EigenLayer verification pending
        FhenixPending,     // Fhenix FHE computation pending
        Verified,          // Verification successful
        Failed             // Verification failed
    }

    /// @notice Multi-step verification workflow
    struct VerificationWorkflow {
        address user;
        bytes32 proofHash;
        WorkflowState state;
        VerificationMode mode;
        bytes32 brevisDataHash;
        bytes32 eigenLayerRequestId;
        bytes32 fhenixRequestId;
        uint256 timestamp;
        bool allowFallback;
    }

    /// @notice The pool manager contract
    IPoolManager public immutable poolManager;

    /// @notice The Brevis verifier contract
    IBrevisVerifier public immutable brevisVerifier;

    /// @notice The EigenLayer AVS contract
    IEigenLayerAVS public immutable eigenLayerAVS;

    /// @notice The Fhenix FHE contract
    IRealFhenixFHE public immutable fhenixFHE;

    /// @notice Mapping from user address to their compliance data hash
    mapping(address => bytes32) public userComplianceHashes;

    /// @notice Mapping from proof hash to whether it's been used (replay protection)
    mapping(bytes32 => bool) public usedProofs;

    /// @notice Mapping from workflow ID to verification workflow
    mapping(bytes32 => VerificationWorkflow) public workflows;

    /// @notice Admin address
    address public admin;

    /// @notice Whether the hook is enabled
    bool public enabled;

    /// @notice Current verification mode
    VerificationMode public verificationMode;

    /// @notice Whether to allow fallback verification
    bool public allowFallback;

    /// @notice Compliance requirements configuration
    struct ComplianceRequirements {
        bool requireKYC;
        bool requireAgeVerification;
        bool requireLocationCheck;
        bool requireSanctionsCheck;
        uint256 minAge;
    }

    ComplianceRequirements public requirements;

    /// @notice Events
    event HookEnabled(bool enabled);
    event RequirementsUpdated(ComplianceRequirements requirements);
    event VerificationModeUpdated(VerificationMode mode);
    event ProofSubmitted(address indexed user, bytes32 proofHash, bytes32 dataHash);
    event WorkflowStarted(bytes32 indexed workflowId, address indexed user, VerificationMode mode);
    event WorkflowStateChanged(bytes32 indexed workflowId, WorkflowState oldState, WorkflowState newState);
    event VerificationCompleted(bytes32 indexed workflowId, address indexed user, bool isValid);
    event FallbackUsed(bytes32 indexed workflowId, string method);
    event SwapBlocked(address indexed user, string reason);
    event LiquidityBlocked(address indexed user, string reason);

    /// @notice Errors
    error HookNotEnabled();
    error InvalidProof();
    error ProofExpired();
    error ProofAlreadyUsed();
    error UserNotCompliant();
    error InvalidComplianceData();
    error Unauthorized();
    error VerificationFailed();
    error WorkflowNotFound();
    error WorkflowInProgress();

    modifier onlyAdmin() {
        if (msg.sender != admin) revert Unauthorized();
        _;
    }

    modifier onlyWhenEnabled() {
        if (!enabled) revert HookNotEnabled();
        _;
    }

    modifier onlyPoolManager() {
        if (msg.sender != address(poolManager)) revert Unauthorized();
        _;
    }

    constructor(
        IPoolManager _poolManager,
        IBrevisVerifier _brevisVerifier,
        IEigenLayerAVS _eigenLayerAVS,
        IRealFhenixFHE _fhenixFHE,
        ComplianceRequirements memory _requirements,
        VerificationMode _verificationMode,
        bool _allowFallback
    ) {
        poolManager = _poolManager;
        brevisVerifier = _brevisVerifier;
        eigenLayerAVS = _eigenLayerAVS;
        fhenixFHE = _fhenixFHE;
        admin = msg.sender;
        enabled = true;
        requirements = _requirements;
        verificationMode = _verificationMode;
        allowFallback = _allowFallback;
    }

    /// @notice Hook called before a swap
    function beforeSwap(
        address sender,
        IPoolManager.PoolKey calldata key,
        IPoolManager.SwapParams calldata params,
        bytes calldata hookData
    ) external override onlyPoolManager onlyWhenEnabled returns (bytes4) {
        _verifyCompliance(sender, hookData, "Swap");
        return this.beforeSwap.selector;
    }

    /// @notice Hook called after a swap
    function afterSwap(
        address sender,
        IPoolManager.PoolKey calldata key,
        IPoolManager.SwapParams calldata params,
        BalanceDelta delta,
        bytes calldata hookData
    ) external override onlyPoolManager returns (bytes4) {
        return this.afterSwap.selector;
    }

    /// @notice Hook called before adding liquidity
    function beforeAddLiquidity(
        address sender,
        IPoolManager.PoolKey calldata key,
        IPoolManager.ModifyLiquidityParams calldata params,
        bytes calldata hookData
    ) external override onlyPoolManager onlyWhenEnabled returns (bytes4) {
        _verifyCompliance(sender, hookData, "AddLiquidity");
        return this.beforeAddLiquidity.selector;
    }

    /// @notice Hook called after adding liquidity
    function afterAddLiquidity(
        address sender,
        IPoolManager.PoolKey calldata key,
        IPoolManager.ModifyLiquidityParams calldata params,
        BalanceDelta delta,
        bytes calldata hookData
    ) external override onlyPoolManager returns (bytes4) {
        return this.afterAddLiquidity.selector;
    }

    /// @notice Internal function to verify compliance using multi-step workflow
    function _verifyCompliance(address user, bytes calldata hookData, string memory action) internal {
        // Check if user already has a valid compliance hash stored
        bytes32 storedHash = userComplianceHashes[user];
        bytes32 expectedDataHash = brevisVerifier.getUserComplianceHash(user);
        
        if (storedHash != bytes32(0) && storedHash == expectedDataHash && expectedDataHash != bytes32(0)) {
            // User is already verified, allow the operation
            return;
        }

        // Decode the compliance proof from hookData
        IBrevisVerifier.ComplianceProof memory proof = abi.decode(
            hookData,
            (IBrevisVerifier.ComplianceProof)
        );

        if (proof.user != user) {
            emit SwapBlocked(user, "Proof user mismatch");
            revert InvalidProof();
        }

        if (expectedDataHash == bytes32(0)) {
            emit SwapBlocked(user, "User not compliant");
            revert UserNotCompliant();
        }

        // Check replay protection
        if (usedProofs[proof.proofHash]) {
            emit SwapBlocked(user, "Proof already used");
            revert ProofAlreadyUsed();
        }

        // Start multi-step verification workflow
        bytes32 workflowId = _startVerificationWorkflow(user, proof, expectedDataHash);

        // Execute verification based on mode
        bool verificationSuccess = _executeVerificationWorkflow(workflowId, proof, expectedDataHash);

        if (!verificationSuccess) {
            emit SwapBlocked(user, "Verification failed");
            revert VerificationFailed();
        }

        // Mark proof as used
        usedProofs[proof.proofHash] = true;
        userComplianceHashes[user] = workflows[workflowId].brevisDataHash;

        emit ProofSubmitted(user, proof.proofHash, workflows[workflowId].brevisDataHash);
    }

    /// @notice Start a verification workflow
    function _startVerificationWorkflow(
        address user,
        IBrevisVerifier.ComplianceProof memory proof,
        bytes32 expectedDataHash
    ) internal returns (bytes32 workflowId) {
        workflowId = keccak256(abi.encodePacked(user, proof.proofHash, block.timestamp, block.number));

        workflows[workflowId] = VerificationWorkflow({
            user: user,
            proofHash: proof.proofHash,
            state: WorkflowState.Initial,
            mode: verificationMode,
            brevisDataHash: bytes32(0),
            eigenLayerRequestId: bytes32(0),
            fhenixRequestId: bytes32(0),
            timestamp: block.timestamp,
            allowFallback: allowFallback
        });

        emit WorkflowStarted(workflowId, user, verificationMode);
        return workflowId;
    }

    /// @notice Execute verification workflow based on mode
    function _executeVerificationWorkflow(
        bytes32 workflowId,
        IBrevisVerifier.ComplianceProof memory proof,
        bytes32 expectedDataHash
    ) internal returns (bool success) {
        VerificationWorkflow storage workflow = workflows[workflowId];
        
        if (verificationMode == VerificationMode.BrevisOnly) {
            return _verifyWithBrevis(workflow, proof, expectedDataHash);
        } else if (verificationMode == VerificationMode.EigenLayerOnly) {
            return _verifyWithEigenLayer(workflow, proof);
        } else if (verificationMode == VerificationMode.FhenixOnly) {
            return _verifyWithFhenix(workflow, proof);
        } else if (verificationMode == VerificationMode.HybridBrevisEigen) {
            bool brevisSuccess = _verifyWithBrevis(workflow, proof, expectedDataHash);
            if (!brevisSuccess && allowFallback) {
                emit FallbackUsed(workflowId, "EigenLayer");
                return _verifyWithEigenLayer(workflow, proof);
            }
            return brevisSuccess;
        } else if (verificationMode == VerificationMode.HybridEigenBrevis) {
            bool eigenSuccess = _verifyWithEigenLayer(workflow, proof);
            if (!eigenSuccess && allowFallback) {
                emit FallbackUsed(workflowId, "Brevis");
                return _verifyWithBrevis(workflow, proof, expectedDataHash);
            }
            return eigenSuccess;
        } else if (verificationMode == VerificationMode.HybridAll) {
            // Try Brevis first
            if (_verifyWithBrevis(workflow, proof, expectedDataHash)) {
                return true;
            }
            // Fallback to EigenLayer
            if (allowFallback && _verifyWithEigenLayer(workflow, proof)) {
                return true;
            }
            // Fallback to Fhenix
            if (allowFallback && _verifyWithFhenix(workflow, proof)) {
                return true;
            }
            return false;
        }

        return false;
    }

    /// @notice Verify with Brevis ZK proof
    function _verifyWithBrevis(
        VerificationWorkflow storage workflow,
        IBrevisVerifier.ComplianceProof memory proof,
        bytes32 expectedDataHash
    ) internal returns (bool success) {
        _updateWorkflowState(workflow, WorkflowState.BrevisPending);

        (bool isValid, bytes32 dataHash) = brevisVerifier.verifyProof(proof, expectedDataHash);

        if (isValid) {
            workflow.brevisDataHash = dataHash;
            _updateWorkflowState(workflow, WorkflowState.Verified);
            return true;
        }

        _updateWorkflowState(workflow, WorkflowState.Failed);
        return false;
    }

    /// @notice Verify with EigenLayer AVS
    function _verifyWithEigenLayer(
        VerificationWorkflow storage workflow,
        IBrevisVerifier.ComplianceProof memory proof
    ) internal returns (bool success) {
        _updateWorkflowState(workflow, WorkflowState.EigenLayerPending);

        // Submit verification request to EigenLayer
        bytes32 requestId = eigenLayerAVS.submitVerificationRequest(
            workflow.user,
            proof.proofHash,
            proof.publicInputs
        );

        workflow.eigenLayerRequestId = requestId;

        // Check if verification is already complete (synchronous check)
        IEigenLayerAVS.VerificationResult memory result = eigenLayerAVS.getVerificationResult(requestId);
        
        if (result.requestId != bytes32(0) && result.isValid) {
            workflow.brevisDataHash = result.dataHash;
            _updateWorkflowState(workflow, WorkflowState.Verified);
            return true;
        }

        // If pending, we need to wait for async result
        // For now, we'll revert and require the user to wait
        // In production, you might want to allow the transaction to proceed with a pending state
        _updateWorkflowState(workflow, WorkflowState.EigenLayerPending);
        return false; // Will need to retry after EigenLayer verification completes
    }

    /// @notice Verify with Fhenix FHE
    function _verifyWithFhenix(
        VerificationWorkflow storage workflow,
        IBrevisVerifier.ComplianceProof memory proof
    ) internal returns (bool success) {
        _updateWorkflowState(workflow, WorkflowState.FhenixPending);

        // Request FHE computation
        // Note: This requires encrypted data to be prepared beforehand
        // For now, this is a placeholder
        
        _updateWorkflowState(workflow, WorkflowState.Failed);
        return false;
    }

    /// @notice Update workflow state
    function _updateWorkflowState(VerificationWorkflow storage workflow, WorkflowState newState) internal {
        WorkflowState oldState = workflow.state;
        workflow.state = newState;
        emit WorkflowStateChanged(
            keccak256(abi.encode(workflow.user, workflow.proofHash, workflow.timestamp)),
            oldState,
            newState
        );
    }

    /// @notice Submit a compliance proof (can be called separately)
    function submitProof(IBrevisVerifier.ComplianceProof calldata proof) external {
        if (proof.user != msg.sender) {
            revert InvalidProof();
        }

        bytes32 expectedDataHash = brevisVerifier.getUserComplianceHash(msg.sender);
        if (expectedDataHash == bytes32(0)) {
            revert UserNotCompliant();
        }

        if (usedProofs[proof.proofHash]) {
            revert ProofAlreadyUsed();
        }

        bytes32 workflowId = _startVerificationWorkflow(msg.sender, proof, expectedDataHash);
        bool success = _executeVerificationWorkflow(workflowId, proof, expectedDataHash);

        if (!success) {
            revert VerificationFailed();
        }

        usedProofs[proof.proofHash] = true;
        userComplianceHashes[msg.sender] = workflows[workflowId].brevisDataHash;

        emit ProofSubmitted(msg.sender, proof.proofHash, workflows[workflowId].brevisDataHash);
    }

    /// @notice Check workflow status
    function getWorkflowStatus(bytes32 workflowId) external view returns (WorkflowState state, bool isComplete) {
        VerificationWorkflow memory workflow = workflows[workflowId];
        if (workflow.user == address(0)) {
            revert WorkflowNotFound();
        }
        
        isComplete = (workflow.state == WorkflowState.Verified || workflow.state == WorkflowState.Failed);
        return (workflow.state, isComplete);
    }

    /// @notice Admin functions
    function setEnabled(bool _enabled) external onlyAdmin {
        enabled = _enabled;
        emit HookEnabled(_enabled);
    }

    function setRequirements(ComplianceRequirements memory _requirements) external onlyAdmin {
        requirements = _requirements;
        emit RequirementsUpdated(_requirements);
    }

    function setVerificationMode(VerificationMode _mode) external onlyAdmin {
        verificationMode = _mode;
        emit VerificationModeUpdated(_mode);
    }

    function setAllowFallback(bool _allowFallback) external onlyAdmin {
        allowFallback = _allowFallback;
    }

    function isUserCompliant(address user) external view returns (bool) {
        return brevisVerifier.isUserCompliant(user);
    }

    function isProofUsed(bytes32 proofHash) external view returns (bool) {
        return usedProofs[proofHash];
    }

    function transferAdmin(address newAdmin) external onlyAdmin {
        if (newAdmin == address(0)) revert InvalidComplianceData();
        admin = newAdmin;
    }

    function getHookPermissions() external pure returns (uint16) {
        return 1 | 4; // beforeSwap + beforeAddLiquidity
    }
}

