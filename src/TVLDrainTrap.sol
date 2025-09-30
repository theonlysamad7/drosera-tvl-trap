// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./interfaces/ITrap.sol";
import "./interfaces/IAdapter.sol";

/// @title TVLDrainTrap (Drosera style)
/// @notice Stateless trap: collect() is view; shouldRespond() is pure.
/// @dev Config that shouldRespond uses are compile-time constants so it can remain pure.
contract TVLDrainTrap is ITrap {
    IAdapter public immutable ADAPTER;
    address  public immutable PROTOCOL;

    // ====== CONFIGURE BEFORE COMPILING (change these constants if you want different behavior) ======
    // Use BPS for precision (10_000 = 100%)
    uint256 public constant DRAIN_THRESHOLD_BPS = 2_000; // 20%
    uint256 public constant BASELINE_WINDOW     = 3;     // examine up to 3 older samples for baseline
    uint256 public constant PERSISTENCE         = 1;     // how many samples (including current) must be <= floor to trigger
    // ================================================================================================

    constructor(address adapter_, address protocol_) {
        ADAPTER = IAdapter(adapter_);
        PROTOCOL = protocol_;
    }

    /// @notice Snapshot: (protocol, tvl, block.number)
    function collect() external view override returns (bytes memory) {
        uint256 tvl;
        // If adapter reverts, treat tvl as 0 (safe fallback)
        try ADAPTER.getTVL(PROTOCOL) returns (uint256 v) {
            tvl = v;
        } catch {
            tvl = 0;
        }
        return abi.encode(PROTOCOL, tvl, block.number);
    }

    /// @notice Decision logic based only on the supplied snapshots (newest -> oldest)
    function shouldRespond(bytes[] calldata data)
        external
        pure
        override
        returns (bool, bytes memory)
    {
        // need newest + at least one older sample
        if (data.length < 2) return (false, "");

        // newest snapshot
        (address protocolNow, uint256 tvlNow, uint256 blockNow) = abi.decode(data[0], (address, uint256, uint256));

        // how many previous samples we can use
        uint256 availablePrev = data.length - 1;
        uint256 window = BASELINE_WINDOW > availablePrev ? availablePrev : BASELINE_WINDOW;
        if (window == 0) return (false, "");

        // baseline = max of previous `window` tvl values
        uint256 baseline = 0;
        for (uint256 i = 1; i <= window; i++) {
            (, uint256 tvlPrev, ) = abi.decode(data[i], (address, uint256, uint256));
            if (tvlPrev > baseline) baseline = tvlPrev;
        }
        if (baseline == 0) return (false, "");

        // drop in BPS (0..10,000)
        uint256 dropBps = tvlNow >= baseline ? 0 : ((baseline - tvlNow) * 10_000) / baseline;

        // floor = baseline * (1 - threshold)
        uint256 floor = (baseline * (10_000 - DRAIN_THRESHOLD_BPS)) / 10_000;

        // count violations among previous samples (<= floor)
        uint256 violations = 0;
        for (uint256 i = 1; i <= window; i++) {
            (, uint256 tvlPrev, ) = abi.decode(data[i], (address, uint256, uint256));
            if (tvlPrev <= floor) violations++;
        }

        // include current sample if it's a violation
        uint256 currentIsViolation = tvlNow <= floor ? 1 : 0;

        bool trigger = (dropBps >= DRAIN_THRESHOLD_BPS) && (violations + currentIsViolation >= PERSISTENCE);

        // payload (for responder) = (protocol, tvlNow, baseline, dropBps, thresholdBps, blockNow)
        bytes memory payload = abi.encode(protocolNow, tvlNow, baseline, dropBps, DRAIN_THRESHOLD_BPS, blockNow);
        return (trigger, payload);
    }
}
