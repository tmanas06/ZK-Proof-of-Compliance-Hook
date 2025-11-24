// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IPoolManager} from "../interfaces/IPoolManager.sol";
import {BalanceDelta} from "../libraries/BalanceDelta.sol";

/// @title UniswapV4Router
/// @notice Simplified router for interacting with Uniswap v4 pools with hooks
/// @dev This router handles encoding swap and liquidity operations for the lock pattern
contract UniswapV4Router {
    IPoolManager public immutable poolManager;

    event SwapExecuted(
        address indexed user,
        address currency0,
        address currency1,
        bool zeroForOne,
        int256 amountSpecified
    );

    event LiquidityModified(
        address indexed user,
        address currency0,
        address currency1,
        int256 liquidityDelta
    );

    constructor(IPoolManager _poolManager) {
        poolManager = _poolManager;
    }

    /// @notice Execute a swap through the pool manager
    /// @param key The pool key identifying the pool
    /// @param params Swap parameters
    /// @param hookData Hook data (compliance proof for our hook)
    /// @return delta The balance delta from the swap
    function swap(
        IPoolManager.PoolKey calldata key,
        IPoolManager.SwapParams calldata params,
        bytes calldata hookData
    ) external returns (BalanceDelta delta) {
        // Encode the swap operation with operation type
        bytes memory operationData = abi.encode(uint8(1), params, hookData); // 1 = swap
        bytes memory lockData = abi.encode(key, operationData);
        
        // Call lock with the encoded data
        bytes memory result = poolManager.lock(lockData);
        
        // Decode and return the balance delta
        delta = abi.decode(result, (BalanceDelta));
        
        emit SwapExecuted(
            msg.sender,
            key.currency0,
            key.currency1,
            params.zeroForOne,
            params.amountSpecified
        );
    }

    /// @notice Modify liquidity (add or remove) through the pool manager
    /// @param key The pool key identifying the pool
    /// @param params Liquidity modification parameters
    /// @param hookData Hook data (compliance proof for our hook)
    /// @return delta The balance delta from the liquidity operation
    function modifyLiquidity(
        IPoolManager.PoolKey calldata key,
        IPoolManager.ModifyLiquidityParams calldata params,
        bytes calldata hookData
    ) external returns (BalanceDelta delta) {
        // Encode the liquidity operation with operation type
        bytes memory operationData = abi.encode(uint8(2), params, hookData); // 2 = liquidity
        bytes memory lockData = abi.encode(key, operationData);
        
        // Call lock with the encoded data
        bytes memory result = poolManager.lock(lockData);
        
        // Decode and return the balance delta
        delta = abi.decode(result, (BalanceDelta));
        
        emit LiquidityModified(
            msg.sender,
            key.currency0,
            key.currency1,
            params.liquidityDelta
        );
    }
}

