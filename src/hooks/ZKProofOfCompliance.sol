// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IPoolManager} from "../interfaces/IPoolManager.sol";
import {IHooks} from "../interfaces/IPoolManager.sol";
import {BalanceDelta} from "../libraries/BalanceDelta.sol";
import {IBrevisVerifier} from "../interfaces/IBrevisVerifier.sol";
import {BrevisVerifier} from "../verifiers/BrevisVerifier.sol";

/// @title ZKProofOfCompliance
/// @notice Uniswap v4 hook that restricts swaps and LP actions to users with valid ZK compliance proofs
/// @dev This hook uses Brevis Network to verify compliance without exposing PII on-chain
contract ZKProofOfCompliance is IHooks {
    /// @notice The pool manager contract
    IPoolManager public immutable poolManager;

    /// @notice The Brevis verifier contract
    IBrevisVerifier public immutable brevisVerifier;

    /// @notice Mapping from user address to their compliance data hash
    mapping(address => bytes32) public userComplianceHashes;

    /// @notice Mapping from proof hash to whether it's been used (replay protection)
    mapping(bytes32 => bool) public usedProofs;

    /// @notice Admin address that can configure the hook
    address public admin;

    /// @notice Whether the hook is enabled
    bool public enabled;

    /// @notice Compliance requirements configuration
    struct ComplianceRequirements {
        bool requireKYC;
        bool requireAgeVerification;
        bool requireLocationCheck;
        bool requireSanctionsCheck;
        uint256 minAge; // Minimum age requirement (e.g., 18)
    }

    ComplianceRequirements public requirements;

    /// @notice Events
    event HookEnabled(bool enabled);
    event RequirementsUpdated(ComplianceRequirements requirements);
    event ProofSubmitted(address indexed user, bytes32 proofHash, bytes32 dataHash);
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
    /// @param _requirements Initial compliance requirements
    constructor(
        IPoolManager _poolManager,
        IBrevisVerifier _brevisVerifier,
        ComplianceRequirements memory _requirements
    ) {
        poolManager = _poolManager;
        brevisVerifier = _brevisVerifier;
        admin = msg.sender;
        enabled = true;
        requirements = _requirements;
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
        // Verify compliance proof
        _verifyCompliance(sender, hookData, "Swap");

        // Return the selector to indicate the hook was called successfully
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
        // No action needed after swap
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
        // Verify compliance proof
        _verifyCompliance(sender, hookData, "AddLiquidity");

        // Return the selector to indicate the hook was called successfully
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
        // No action needed after adding liquidity
        return this.afterAddLiquidity.selector;
    }

    /// @notice Internal function to verify compliance
    /// @param user The user address to verify
    /// @param hookData The hook data containing the compliance proof
    /// @param action The action being performed (for error messages)
    function _verifyCompliance(address user, bytes calldata hookData, string memory action) internal {
        // Check if user already has a valid compliance hash stored
        bytes32 storedHash = userComplianceHashes[user];
        bytes32 expectedDataHash = brevisVerifier.getUserComplianceHash(user);
        
        // If user has a stored hash that matches expected, allow the operation
        // This allows users to perform multiple operations without submitting new proofs each time
        if (storedHash != bytes32(0) && storedHash == expectedDataHash && expectedDataHash != bytes32(0)) {
            // User is already verified, allow the operation
            return;
        }

        // Otherwise, verify the proof from hookData
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

        // If no hash exists, user is not compliant
        if (expectedDataHash == bytes32(0)) {
            emit SwapBlocked(user, "User not compliant");
            revert UserNotCompliant();
        }

        // Verify the proof using Brevis verifier
        (bool isValid, bytes32 dataHash) = brevisVerifier.verifyProof(proof, expectedDataHash);

        if (!isValid) {
            emit SwapBlocked(user, "Invalid proof");
            revert InvalidProof();
        }

        // Check if proof has been used (replay protection)
        if (usedProofs[proof.proofHash]) {
            emit SwapBlocked(user, "Proof already used");
            revert ProofAlreadyUsed();
        }

        // Mark proof as used
        usedProofs[proof.proofHash] = true;

        // Record the user's compliance hash
        userComplianceHashes[user] = dataHash;

        emit ProofSubmitted(user, proof.proofHash, dataHash);
    }

    /// @notice Submit a compliance proof (can be called separately before swaps)
    /// @param proof The compliance proof to submit
    function submitProof(IBrevisVerifier.ComplianceProof calldata proof) external {
        // Verify the proof is for the correct user
        if (proof.user != msg.sender) {
            revert InvalidProof();
        }

        // Get expected hash from verifier
        bytes32 expectedDataHash = brevisVerifier.getUserComplianceHash(msg.sender);

        if (expectedDataHash == bytes32(0)) {
            revert UserNotCompliant();
        }

        // Check if proof has been used (replay protection) - check hook's mapping first
        if (usedProofs[proof.proofHash]) {
            revert ProofAlreadyUsed();
        }

        // Verify the proof using Brevis verifier
        // Note: We pass the expectedDataHash which we just retrieved
        (bool isValid, bytes32 dataHash) = brevisVerifier.verifyProof(proof, expectedDataHash);

        if (!isValid) {
            revert InvalidProof();
        }

        // Ensure we got a valid dataHash back
        if (dataHash == bytes32(0)) {
            revert InvalidProof();
        }

        // Mark proof as used
        usedProofs[proof.proofHash] = true;
        userComplianceHashes[msg.sender] = dataHash;

        emit ProofSubmitted(msg.sender, proof.proofHash, dataHash);
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
    /// @dev This tells Uniswap v4 which hooks this contract implements
    function getHookPermissions() external pure returns (uint16 permissions) {
        // Permissions: beforeSwap = 1, afterSwap = 2, beforeAddLiquidity = 4, afterAddLiquidity = 8
        // We only need beforeSwap and beforeAddLiquidity
        return 1 | 4; // 5 = beforeSwap (1) + beforeAddLiquidity (4)
    }
}

