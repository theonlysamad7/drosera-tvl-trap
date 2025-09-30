// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// Minimal TVL adapter interface used by collect()
interface IAdapter {
    /// Return TVL for a protocol (view). Implementations should avoid reverts.
    function getTVL(address protocol) external view returns (uint256);
}
