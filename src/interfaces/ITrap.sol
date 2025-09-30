// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// Minimal Drosera trap interface (collect + shouldRespond)
interface ITrap {
    /// Take a snapshot (view-only)
    function collect() external view returns (bytes memory);

    /// Decide whether to respond using only snapshots (pure)
    /// snapshots are ordered newest -> oldest
    function shouldRespond(bytes[] calldata data) external pure returns (bool, bytes memory);
}
