// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice Represents the change in balance for a currency
type BalanceDelta is int256;

using {add as +, sub as -} for BalanceDelta global;

function add(BalanceDelta a, BalanceDelta b) pure returns (BalanceDelta) {
    return BalanceDelta.wrap(BalanceDelta.unwrap(a) + BalanceDelta.unwrap(b));
}

function sub(BalanceDelta a, BalanceDelta b) pure returns (BalanceDelta) {
    return BalanceDelta.wrap(BalanceDelta.unwrap(a) - BalanceDelta.unwrap(b));
}

