// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/TVLDrainTrap.sol";

contract TVLDrainTrapTest is Test {
    TVLDrainTrap trap;

    function setUp() public {
        // Use dummy adapter & protocol addresses; collect() won’t be called in these tests
        trap = new TVLDrainTrap(address(0x1), address(0xCAFE));
    }

    function testNoTriggerWhenSmallDrop() public {
        // Declare an array of 3 snapshots
        bytes ;

        // newest first: 900 (now), then older two at 1000
        data[0] = abi.encode(address(0xCAFE), 900 ether, block.number);
        data[1] = abi.encode(address(0xCAFE), 1000 ether, block.number - 1);
        data[2] = abi.encode(address(0xCAFE), 1000 ether, block.number - 2);

        (bool triggered, ) = trap.shouldRespond(data);
        assertFalse(triggered, "10% drop should not trigger (threshold 20%)");
    }

    function testTriggerOnLargeDrop() public {
        // Declare an array of 3 snapshots
        bytes ;

        // newest first: 700 (now), then older two at 1000
        data[0] = abi.encode(address(0xCAFE), 700 ether, block.number);
        data[1] = abi.encode(address(0xCAFE), 1000 ether, block.number - 1);
        data[2] = abi.encode(address(0xCAFE), 1000 ether, block.number - 2);

        (bool triggered, bytes memory payload) = trap.shouldRespond(data);
        assertTrue(triggered, "30% drop should trigger (threshold 20%)");

        // decode payload to verify contents
        (
            address protocolNow,
            uint256 tvlNow,
            uint256 baseline,
            uint256 dropBps,
            uint256 thresholdBps,
            uint256 blockNow
        ) = abi.decode(payload, (address, uint256, uint256, uint256, uint256, uint256));

        assertEq(protocolNow, address(0xCAFE));
        assertEq(tvlNow, 700 ether);
        assertEq(baseline, 1000 ether);
        assertGe(dropBps, 3000); // at least ~30%
        assertEq(thresholdBps, 2000); // from contract constant
        assertTrue(blockNow > 0);
    }
}
