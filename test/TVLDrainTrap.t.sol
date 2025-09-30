// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/TVLDrainTrap.sol";

contract TVLDrainTrapTest is Test {
    TVLDrainTrap trap;

    function setUp() public {
        trap = new TVLDrainTrap();
    }

    function testSimple() public {
        // ✅ Explicitly declare "data"
        bytes ;

        data[0] = abi.encode(address(0xCAFE), 1000 ether, block.number);
        data[1] = abi.encode(address(0xCAFE), 1000 ether, block.number - 1);
        data[2] = abi.encode(address(0xCAFE), 1000 ether, block.number - 2);

        (bool triggered, ) = trap.shouldRespond(data);

        assertFalse(triggered, "Trap should not trigger if TVL is stable");
    }
}
