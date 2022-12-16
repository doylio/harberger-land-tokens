// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../src/implementations/PlotManager.sol";

contract PlotManagerTestTemplate is Test {
    PlotManager public plotManager;

    // struct Plot {
    //     int64 x1;
    //     int64 y1;
    //     int64 x2;
    //     int64 y2;
    // }

    function setUp() public {
        plotManager = new PlotManager(address(this));
    }

    function isReasonableBounds(int64 n) public pure returns (bool) {
        return n >= -1000000000 && n <= 1000000000;
    }
}
