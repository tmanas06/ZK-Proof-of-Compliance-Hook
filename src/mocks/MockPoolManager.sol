// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IPoolManager} from "../interfaces/IPoolManager.sol";
import {BalanceDelta} from "../libraries/BalanceDelta.sol";
import {IHooks} from "../interfaces/IPoolManager.sol";

/// @title MockPoolManager
/// @notice Mock implementation of Uniswap v4 PoolManager for testing
/// @dev This simulates the PoolManager's lock pattern and hook calls
contract MockPoolManager is IPoolManager {
    /// @notice Mock lock function that calls hooks
    /// @param data Encoded pool key, params, and hook data
    /// @return result Encoded balance delta
    event LockCalled(address indexed caller, bytes data);

    function lock(bytes calldata data) external override returns (bytes memory result) {
        emit LockCalled(msg.sender, data);
        
        // Decode the data
        (
            IPoolManager.PoolKey memory key,
            bytes memory operationData
        ) = abi.decode(data, (IPoolManager.PoolKey, bytes));
        
        // Decode operation type (1 = swap, 2 = liquidity)
        uint8 operationType = uint8(operationData[0]);
        
        if (operationType == 1) {
            // Decode swap params (skip first byte which is operation type)
            // Create new bytes array without first byte
            bytes memory swapData = new bytes(operationData.length - 1);
            for (uint i = 0; i < swapData.length; i++) {
                swapData[i] = operationData[i + 1];
            }
            IPoolManager.SwapParams memory swapParams;
            bytes memory hookData;
            (swapParams, hookData) = abi.decode(swapData, (IPoolManager.SwapParams, bytes));
            
            // Call hook's beforeSwap
            if (address(key.hooks) != address(0)) {
                IHooks(key.hooks).beforeSwap(
                    msg.sender,
                    key,
                    swapParams,
                    hookData
                );
            }
            
            // Simulate swap (in real implementation, this would execute the swap)
            // For mock, we just return a balance delta
            // BalanceDelta is a type alias for int256, so we encode it directly
            int256 deltaValue = swapParams.zeroForOne 
                ? -swapParams.amountSpecified 
                : swapParams.amountSpecified;
            BalanceDelta delta = BalanceDelta.wrap(deltaValue);
            
            // Call hook's afterSwap
            if (address(key.hooks) != address(0)) {
                IHooks(key.hooks).afterSwap(
                    msg.sender,
                    key,
                    swapParams,
                    delta,
                    hookData
                );
            }
            
            return abi.encode(delta);
        } else if (operationType == 2) {
            // Decode liquidity params (skip first byte which is operation type)
            bytes memory liqData = new bytes(operationData.length - 1);
            for (uint i = 0; i < liqData.length; i++) {
                liqData[i] = operationData[i + 1];
            }
            IPoolManager.ModifyLiquidityParams memory liqParams;
            bytes memory hookData;
            (liqParams, hookData) = abi.decode(liqData, (IPoolManager.ModifyLiquidityParams, bytes));
            
            // Call hook's beforeAddLiquidity
            if (address(key.hooks) != address(0)) {
                IHooks(key.hooks).beforeAddLiquidity(
                    msg.sender,
                    key,
                    liqParams,
                    hookData
                );
            }
            
            // Simulate liquidity operation
            // BalanceDelta is a type alias for int256
            BalanceDelta delta = BalanceDelta.wrap(liqParams.liquidityDelta);
            
            // Call hook's afterAddLiquidity
            if (address(key.hooks) != address(0)) {
                IHooks(key.hooks).afterAddLiquidity(
                    msg.sender,
                    key,
                    liqParams,
                    delta,
                    hookData
                );
            }
            
            return abi.encode(delta);
        } else {
            revert("Invalid operation type");
        }
    }
}

