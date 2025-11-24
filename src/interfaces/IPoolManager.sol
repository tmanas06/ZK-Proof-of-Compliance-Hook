// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {BalanceDelta} from "../libraries/BalanceDelta.sol";

/// @notice The pool manager manages the state of the pool
interface IPoolManager {
    /// @notice The pool key for identifying a pool
    struct PoolKey {
        address currency0;
        address currency1;
        uint24 fee;
        int24 tickSpacing;
        IHooks hooks;
    }

    /// @notice Parameters for swap operations
    struct SwapParams {
        bool zeroForOne;
        int256 amountSpecified;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Parameters for modify liquidity operations
    struct ModifyLiquidityParams {
        int24 tickLower;
        int24 tickUpper;
        int256 liquidityDelta;
    }

    function lock(bytes calldata data) external returns (bytes memory result);
}

/// @notice Interface for Uniswap v4 hooks
interface IHooks {
    function beforeSwap(
        address sender,
        IPoolManager.PoolKey calldata key,
        IPoolManager.SwapParams calldata params,
        bytes calldata hookData
    ) external returns (bytes4);

    function afterSwap(
        address sender,
        IPoolManager.PoolKey calldata key,
        IPoolManager.SwapParams calldata params,
        BalanceDelta delta,
        bytes calldata hookData
    ) external returns (bytes4);

    function beforeAddLiquidity(
        address sender,
        IPoolManager.PoolKey calldata key,
        IPoolManager.ModifyLiquidityParams calldata params,
        bytes calldata hookData
    ) external returns (bytes4);

    function afterAddLiquidity(
        address sender,
        IPoolManager.PoolKey calldata key,
        IPoolManager.ModifyLiquidityParams calldata params,
        BalanceDelta delta,
        bytes calldata hookData
    ) external returns (bytes4);
}
