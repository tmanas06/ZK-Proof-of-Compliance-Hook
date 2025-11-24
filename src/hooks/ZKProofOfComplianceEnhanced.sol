// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IPoolManager} from "../interfaces/IPoolManager.sol";
import {IHooks} from "../interfaces/IPoolManager.sol";
import {BalanceDelta} from "../libraries/BalanceDelta.sol";
import {IBrevisVerifier} from "../interfaces/IBrevisVerifier.sol";
import {IEigenLayerAVS} from "../interfaces/IEigenLayerAVS.sol";

/// @title ZKProofOfComplianceEnhanced
/// @notice Enhanced Uniswap v4 hook with EigenLayer AVS integration and fallback handling
/// @dev This hook uses Brevis Network for ZK proofs and EigenLayer AVS for decentralized verification
/// It includes fallback mechanisms for failed proofs or AVS responses
contract ZKProofOfComplianceEnhanced is IHooks {
    /// @notice The pool manager contract
    IPoolManager public immutable poolManager;

    /// @notice The Brevis verifier contract
    IBrevisVerifier public immutable brevisVerifier;

    /// @notice The EigenLayer AVS contract for off-chain verification
    IEigenLayerAVS public immutable eigenLayerAVS;

    /// @notice Mapping from user address to their compliance data hash
    mapping(address => bytes32) public userComplianceHashes;

    /// @notice Mapping from proof hash to whether it's been used (replay protection)
    mapping(bytes32 => bool) public usedProofs;

    /// @notice Mapping from user to pending verification request ID
    mapping(address => bytes32) public pendingVerifications;

    /// @notice Admin address that can configure the hook
    address public admin;

    /// @notice Whether the hook is enabled
    bool public enabled;

    /// @notice Whether to use EigenLayer AVS as primary verification (fallback to Brevis if false)
    bool public useEigenLayerPrimary;

    /// @notice Whether to allow fallback to Brevis if EigenLayer fails
    bool public allowBrevisFallback;

    /// @notice Compliance requirements configuration
    struct ComplianceRequirements {
        bool requireKYC;
        bool requireAgeVerification;
        bool requireLocationCheck;
        bool requireSanctionsCheck;
        uint256 minAge; // Minimum age requirement (e.g., 18)
    }

    ComplianceRequirements public requirements;

    /// @notice Verification mode enum
    enum VerificationMode {
        BrevisOnly,      // Use only Brevis verification
        EigenLayerOnly,  // Use only EigenLayer AVS
        Hybrid,          // Try EigenLayer first, fallback to Brevis
        HybridReverse    // Try Brevis first, fallback to EigenLayer
    }

    VerificationMode public verificationMode;

    /// @notice Events
    event HookEnabled(bool enabled);
    event RequirementsUpdated(ComplianceRequirements requirements);
    event ProofSubmitted(address indexed user, bytes32 proofHash, bytes32 dataHash);
    event SwapBlocked(address indexed user, string reason);
    event LiquidityBlocked(address indexed user, string reason);
    event EigenLayerVerificationRequested(address indexed user, bytes32 requestId);
    event FallbackVerificationUsed(address indexed user, string fallbackType);
    event VerificationModeUpdated(VerificationMode mode);

    /// @notice Errors
    error HookNotEnabled();
    error InvalidProof();
    error ProofExpired();
    error ProofAlreadyUsed();
    error UserNotCompliant();
    error InvalidComplianceData();
    error Unauthorized();
    error VerificationPending();
    error EigenLayerVerificationFailed();
    error BrevisVerificationFailed();
    error AllVerificationMethodsFailed();

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

    /// @notice Constructor
    /// @param _poolManager The Uniswap v4 pool manager address
    /// @param _brevisVerifier The Brevis verifier contract address
    /// @param _eigenLayerAVS The EigenLayer AVS contract address
    /// @param _requirements Initial compliance requirements
    /// @param _verificationMode Initial verification mode
    constructor(
        IPoolManager _poolManager,
        IBrevisVerifier _brevisVerifier,
        IEigenLayerAVS _eigenLayerAVS,
        ComplianceRequirements memory _requirements,
        VerificationMode _verificationMode
    ) {
        poolManager = _poolManager;
        brevisVerifier = _brevisVerifier;
        eigenLayerAVS = _eigenLayerAVS;
        admin = msg.sender;
        enabled = true;
        requirements = _requirements;
        verificationMode = _verificationMode;
        useEigenLayerPrimary = (_verificationMode == VerificationMode.EigenLayerOnly || 
                                _verificationMode == VerificationMode.Hybrid);
        allowBrevisFallback = (_verificationMode == VerificationMode.Hybrid || 
                              _verificationMode == VerificationMode.HybridReverse);
    }

    /// @notice Hook called before a swap
    /// @param sender The address initiating the swap
    /// @param key The pool key
    /// @param params Swap parameters
    /// @param hookData Additional hook data (should contain compliance proof)
    /// @return selector The function selector to indicate hook was called
    function beforeSwap(
        address sender,
        IPoolManager.PoolKey calldata key,
        IPoolManager.SwapParams calldata params,
        bytes calldata hookData
    ) external override onlyPoolManager onlyWhenEnabled returns (bytes4) {
        // Verify compliance with fallback handling
        _verifyComplianceWithFallback(sender, hookData, "Swap");

        return this.beforeSwap.selector;
    }

    /// @notice Hook called after a swap
    /// @param sender The address that initiated the swap
    /// @param key The pool key
    /// @param params Swap parameters
    /// @param delta The balance delta from the swap
    /// @param hookData Additional hook data
    /// @return selector The function selector
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
    /// @param sender The address initiating the liquidity addition
    /// @param key The pool key
    /// @param params Modify liquidity parameters
    /// @param hookData Additional hook data (should contain compliance proof)
    /// @return selector The function selector to indicate hook was called
    function beforeAddLiquidity(
        address sender,
        IPoolManager.PoolKey calldata key,
        IPoolManager.ModifyLiquidityParams calldata params,
        bytes calldata hookData
    ) external override onlyPoolManager onlyWhenEnabled returns (bytes4) {
        // Verify compliance with fallback handling
        _verifyComplianceWithFallback(sender, hookData, "AddLiquidity");

        return this.beforeAddLiquidity.selector;
    }

    /// @notice Hook called after adding liquidity
    /// @param sender The address that initiated the liquidity addition
    /// @param key The pool key
    /// @param params Modify liquidity parameters
    /// @param delta The balance delta from the liquidity addition
    /// @param hookData Additional hook data
    /// @return selector The function selector
    function afterAddLiquidity(
        address sender,
        IPoolManager.PoolKey calldata key,
        IPoolManager.ModifyLiquidityParams calldata params,
        BalanceDelta delta,
        bytes calldata hookData
    ) external override onlyPoolManager returns (bytes4) {
        return this.afterAddLiquidity.selector;
    }

    /// @notice Internal function to verify compliance with fallback handling
    /// @param user The user address to verify
    /// @param hookData The hook data containing the compliance proof
    /// @param action The action being performed (for error messages)
    function _verifyComplianceWithFallback(
        address user,
        bytes calldata hookData,
        string memory action
    ) internal {
        // Decode the compliance proof from hookData
        IBrevisVerifier.ComplianceProof memory proof = abi.decode(
            hookData,
            (IBrevisVerifier.ComplianceProof)
        );

        // Verify the proof is for the correct user
        if (proof.user != user) {
            emit SwapBlocked(user, "Proof user mismatch");
            revert InvalidProof();
        }

        // Check if proof has been used (replay protection)
        if (usedProofs[proof.proofHash]) {
            emit SwapBlocked(user, "Proof already used");
            revert ProofAlreadyUsed();
        }

        bool verificationSuccess = false;
        bytes32 dataHash = bytes32(0);
        string memory fallbackUsed = "";

        // Try verification based on mode
        if (verificationMode == VerificationMode.BrevisOnly) {
            (verificationSuccess, dataHash) = _verifyWithBrevis(user, proof);
            if (!verificationSuccess) {
                emit SwapBlocked(user, "Brevis verification failed");
                revert BrevisVerificationFailed();
            }
        } else if (verificationMode == VerificationMode.EigenLayerOnly) {
            verificationSuccess = _verifyWithEigenLayer(user, proof);
            if (!verificationSuccess) {
                emit SwapBlocked(user, "EigenLayer verification failed");
                revert EigenLayerVerificationFailed();
            }
        } else if (verificationMode == VerificationMode.Hybrid) {
            // Try EigenLayer first, fallback to Brevis
            verificationSuccess = _verifyWithEigenLayer(user, proof);
            if (!verificationSuccess && allowBrevisFallback) {
                emit FallbackVerificationUsed(user, "Brevis");
                fallbackUsed = "Brevis";
                (verificationSuccess, dataHash) = _verifyWithBrevis(user, proof);
            }
        } else if (verificationMode == VerificationMode.HybridReverse) {
            // Try Brevis first, fallback to EigenLayer
            (verificationSuccess, dataHash) = _verifyWithBrevis(user, proof);
            if (!verificationSuccess && allowBrevisFallback) {
                emit FallbackVerificationUsed(user, "EigenLayer");
                fallbackUsed = "EigenLayer";
                verificationSuccess = _verifyWithEigenLayer(user, proof);
            }
        }

        if (!verificationSuccess) {
            emit SwapBlocked(user, "All verification methods failed");
            revert AllVerificationMethodsFailed();
        }

        // Mark proof as used
        usedProofs[proof.proofHash] = true;

        // Record the user's compliance hash
        if (dataHash != bytes32(0)) {
            userComplianceHashes[user] = dataHash;
        } else {
            // Get from EigenLayer result if Brevis wasn't used
            IEigenLayerAVS.VerificationResult memory result = eigenLayerAVS.getLatestVerification(user);
            if (result.dataHash != bytes32(0)) {
                userComplianceHashes[user] = result.dataHash;
            }
        }

        emit ProofSubmitted(user, proof.proofHash, userComplianceHashes[user]);
    }

    /// @notice Verify proof using Brevis
    /// @param user The user address
    /// @param proof The compliance proof
    /// @return isValid Whether verification succeeded
    /// @return dataHash The compliance data hash
    function _verifyWithBrevis(
        address user,
        IBrevisVerifier.ComplianceProof memory proof
    ) internal view returns (bool isValid, bytes32 dataHash) {
        bytes32 expectedDataHash = brevisVerifier.getUserComplianceHash(user);

        if (expectedDataHash == bytes32(0)) {
            return (false, bytes32(0));
        }

        return brevisVerifier.verifyProof(proof, expectedDataHash);
    }

    /// @notice Verify proof using EigenLayer AVS
    /// @param user The user address
    /// @param proof The compliance proof
    /// @return isValid Whether verification succeeded
    function _verifyWithEigenLayer(
        address user,
        IBrevisVerifier.ComplianceProof memory proof
    ) internal returns (bool isValid) {
        // Check if there's a pending verification
        bytes32 pendingRequestId = pendingVerifications[user];
        if (pendingRequestId != bytes32(0)) {
            // Check if verification is complete
            if (!eigenLayerAVS.isVerificationPending(pendingRequestId)) {
                IEigenLayerAVS.VerificationResult memory result = eigenLayerAVS.getVerificationResult(
                    pendingRequestId
                );
                if (result.isValid) {
                    pendingVerifications[user] = bytes32(0);
                    return true;
                } else {
                    pendingVerifications[user] = bytes32(0);
                    return false;
                }
            } else {
                // Verification still pending
                revert VerificationPending();
            }
        }

        // Check for existing verification result
        IEigenLayerAVS.VerificationResult memory latestResult = eigenLayerAVS.getLatestVerification(user);
        if (latestResult.requestId != bytes32(0) && latestResult.isValid) {
            // Use existing valid verification
            return true;
        }

        // Submit new verification request
        bytes32 requestId = eigenLayerAVS.submitVerificationRequest(
            user,
            proof.proofHash,
            "" // Empty compliance data (would use Fhenix encrypted data in production)
        );

        pendingVerifications[user] = requestId;
        emit EigenLayerVerificationRequested(user, requestId);

        // For synchronous verification in test/mock, check immediately
        // In production, this would be async and require off-chain polling
        if (!eigenLayerAVS.isVerificationPending(requestId)) {
            IEigenLayerAVS.VerificationResult memory result = eigenLayerAVS.getVerificationResult(requestId);
            if (result.isValid) {
                pendingVerifications[user] = bytes32(0);
                return true;
            }
        }

        revert VerificationPending();
    }

    /// @notice Submit a compliance proof (can be called separately before swaps)
    /// @param proof The compliance proof to submit
    function submitProof(IBrevisVerifier.ComplianceProof calldata proof) external {
        // Decode and verify directly
        IBrevisVerifier.ComplianceProof memory proofMem = proof;
        
        // Verify the proof is for the correct user
        if (proofMem.user != msg.sender) {
            revert InvalidProof();
        }

        // Check if proof has been used (replay protection)
        if (usedProofs[proofMem.proofHash]) {
            revert ProofAlreadyUsed();
        }

        bool verificationSuccess = false;
        bytes32 dataHash = bytes32(0);

        // Try verification based on mode
        if (verificationMode == VerificationMode.BrevisOnly) {
            (verificationSuccess, dataHash) = _verifyWithBrevis(msg.sender, proofMem);
            if (!verificationSuccess) {
                revert BrevisVerificationFailed();
            }
        } else if (verificationMode == VerificationMode.EigenLayerOnly) {
            verificationSuccess = _verifyWithEigenLayer(msg.sender, proofMem);
            if (!verificationSuccess) {
                revert EigenLayerVerificationFailed();
            }
        } else if (verificationMode == VerificationMode.Hybrid) {
            verificationSuccess = _verifyWithEigenLayer(msg.sender, proofMem);
            if (!verificationSuccess && allowBrevisFallback) {
                emit FallbackVerificationUsed(msg.sender, "Brevis");
                (verificationSuccess, dataHash) = _verifyWithBrevis(msg.sender, proofMem);
            }
        } else if (verificationMode == VerificationMode.HybridReverse) {
            (verificationSuccess, dataHash) = _verifyWithBrevis(msg.sender, proofMem);
            if (!verificationSuccess && allowBrevisFallback) {
                emit FallbackVerificationUsed(msg.sender, "EigenLayer");
                verificationSuccess = _verifyWithEigenLayer(msg.sender, proofMem);
            }
        }

        if (!verificationSuccess) {
            revert AllVerificationMethodsFailed();
        }

        // Mark proof as used
        usedProofs[proofMem.proofHash] = true;

        // Record the user's compliance hash
        if (dataHash != bytes32(0)) {
            userComplianceHashes[msg.sender] = dataHash;
        } else {
            IEigenLayerAVS.VerificationResult memory result = eigenLayerAVS.getLatestVerification(msg.sender);
            if (result.dataHash != bytes32(0)) {
                userComplianceHashes[msg.sender] = result.dataHash;
            }
        }

        emit ProofSubmitted(msg.sender, proofMem.proofHash, userComplianceHashes[msg.sender]);
    }

    /// @notice Submit verification request to EigenLayer AVS (for async verification)
    /// @param proof The compliance proof
    /// @return requestId The verification request identifier
    function submitEigenLayerVerification(
        IBrevisVerifier.ComplianceProof calldata proof
    ) external returns (bytes32 requestId) {
        bytes32 requestIdResult = eigenLayerAVS.submitVerificationRequest(
            msg.sender,
            proof.proofHash,
            "" // Empty compliance data (would use Fhenix encrypted data in production)
        );

        pendingVerifications[msg.sender] = requestIdResult;
        emit EigenLayerVerificationRequested(msg.sender, requestIdResult);

        return requestIdResult;
    }

    /// @notice Check EigenLayer verification status
    /// @param user The user address
    /// @return isPending Whether verification is pending
    /// @return isValid Whether verification is valid (if complete)
    function checkEigenLayerStatus(
        address user
    ) external view returns (bool isPending, bool isValid) {
        bytes32 requestId = pendingVerifications[user];
        if (requestId == bytes32(0)) {
            // Check latest verification
            IEigenLayerAVS.VerificationResult memory result = eigenLayerAVS.getLatestVerification(user);
            return (false, result.isValid);
        }

        isPending = eigenLayerAVS.isVerificationPending(requestId);
        if (!isPending) {
            IEigenLayerAVS.VerificationResult memory result = eigenLayerAVS.getVerificationResult(requestId);
            isValid = result.isValid;
        }
    }

    /// @notice Enable or disable the hook
    /// @param _enabled Whether to enable the hook
    function setEnabled(bool _enabled) external onlyAdmin {
        enabled = _enabled;
        emit HookEnabled(_enabled);
    }

    /// @notice Update compliance requirements
    /// @param _requirements New compliance requirements
    function setRequirements(ComplianceRequirements memory _requirements) external onlyAdmin {
        requirements = _requirements;
        emit RequirementsUpdated(_requirements);
    }

    /// @notice Update verification mode
    /// @param _mode New verification mode
    function setVerificationMode(VerificationMode _mode) external onlyAdmin {
        verificationMode = _mode;
        useEigenLayerPrimary = (_mode == VerificationMode.EigenLayerOnly || 
                                _mode == VerificationMode.Hybrid);
        allowBrevisFallback = (_mode == VerificationMode.Hybrid || 
                              _mode == VerificationMode.HybridReverse);
        emit VerificationModeUpdated(_mode);
    }

    /// @notice Check if a user is compliant
    /// @param user The user address to check
    /// @return isCompliant True if user is compliant
    function isUserCompliant(address user) external view returns (bool isCompliant) {
        return brevisVerifier.isUserCompliant(user);
    }

    /// @notice Check if a proof has been used
    /// @param proofHash The proof hash to check
    /// @return used True if proof has been used
    function isProofUsed(bytes32 proofHash) external view returns (bool used) {
        return usedProofs[proofHash];
    }

    /// @notice Transfer admin rights to a new address
    /// @param newAdmin The new admin address
    function transferAdmin(address newAdmin) external onlyAdmin {
        if (newAdmin == address(0)) revert InvalidComplianceData();
        admin = newAdmin;
    }

    /// @notice Get the hook permissions
    /// @return permissions The hook permissions flags
    function getHookPermissions() external pure returns (uint16 permissions) {
        return 1 | 4; // beforeSwap (1) + beforeAddLiquidity (4)
    }
}

