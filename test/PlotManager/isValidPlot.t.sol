// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./PlotManagerTestTemplate.t.sol";

contract PlotManager_isValidPlotTest is PlotManagerTestTemplate {
    function testNoHeight(int64 x1, int64 y, int64 x2) public {
        assertEq(plotManager.isValidPlot(x1, y, x2, y), false);
    }

    function testNoWidth(int64 x, int64 y1, int64 y2) public {
        assertEq(plotManager.isValidPlot(x, y1, x, y2), false);
    }

    function testCoordsWrongOrder(int64 x1, int64 y1, int64 x2, int64 y2) public {
        vm.assume(x1 >= x2);
        vm.assume(y1 >= y2);

        assertEq(plotManager.isValidPlot(x1, y1, x2, y2), false);
    }

    function testWrongCorners(int64 x1, int64 y1, int64 x2, int64 y2) public {
        vm.assume(x1 < x2);
        vm.assume(y1 < y2);

        assertEq(plotManager.isValidPlot(x1, y1, x2, y2), true);
        assertEq(plotManager.isValidPlot(x1, y2, x2, y1), false);
    }

    function testExamples() public {
        assertEq(plotManager.isValidPlot(0, 0, 1, 1), true);
        assertEq(plotManager.isValidPlot(0, 0, 0, 1), false);
        assertEq(plotManager.isValidPlot(0, 0, 1, 0), false);
        assertEq(plotManager.isValidPlot(0, 0, 0, 0), false);
        assertEq(plotManager.isValidPlot(0, 0, -1, 1), false);
        assertEq(plotManager.isValidPlot(0, 0, 1, -1), false);
        assertEq(plotManager.isValidPlot(0, 0, -1, -1), false);
    }
}
