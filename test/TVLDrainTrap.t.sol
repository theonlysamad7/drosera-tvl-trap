// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/TVLDrainTrap.sol";

contract TVLDrainTrapTest is Test {
    TVLDrainTrap trap;

    function setUp() public {
        trap = new TVLDrainTrap();
    }

    function testTrapTrigger() public {
        // ✅ Declare a bytes array with 3 slots
        bytes ;

        // Encode fake TVL datapoints
        data[0] = abi.encode(address(0xCAFE), 700 ether, block.number);
        data[1] = abi.encode(address(0xCAFE), 1000 ether, block.number - 1);
        data[2] = abi.encode(address(0xCAFE), 1000 ether, block.number - 2);

        // Call trap
        (bool triggered, bytes memory payload) = trap.shouldRespond(data);

        // Assert
        assertTrue(triggered, "Trap should trigger on a 30% TVL drop");
        assertGt(payload.length, 0, "Payload should not be empty");
    }

    function testTrapNotTriggered() public {
        bytes ;

        // Encode fake TVL datapoints without big drop
        data[0] = abi.encode(address(0xCAFE), 1000 ether, block.number);
        data[1] = abi.encode(address(0xCAFE), 1000 ether, block.number - 1);
        data[2] = abi.encode(address(0xCAFE), 1000 ether, block.number - 2);

        (bool triggered, ) = trap.shouldRespond(data);

        assertFalse(triggered, "Trap should not trigger if TVL is stable");
    }
}
