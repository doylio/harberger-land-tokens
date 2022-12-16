// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./PlotManagerTestTemplate.t.sol";

contract PlotManager_createNewPlotTest is PlotManagerTestTemplate {
    function testSinglePlot(int64 x1, int64 y1, int64 x2, int64 y2) public {
        vm.assume(x1 < x2);
        vm.assume(y1 < y2);

        uint256 plotId = plotManager.createNewPlot(x1, y1, x2, y2);
        assertEq(plotId, 0);
        assertEq(plotManager.plotCount(), 1);

        PlotManager.Plot memory plot = plotManager.getPlot(plotId);
        assertEq(plot.x1, x1);
        assertEq(plot.y1, y1);
        assertEq(plot.x2, x2);
        assertEq(plot.y2, y2);
    }

    function testNotRegistry() public {
        vm.prank(address(0));
        vm.expectRevert("PlotManager: Only EstateRegistry can call this function");
        plotManager.createNewPlot(0, 0, 1, 1);
    }

    function testInvalidPlot(int64 x1, int64 y1, int64 x2, int64 y2) public {
        vm.assume(x1 >= x2);
        vm.assume(y1 >= y2);

        vm.expectRevert("PlotManager: Invalid plot");
        plotManager.createNewPlot(x1, y1, x2, y2);
    }

    function testPlotsOverlap(int64 x1, int64 y1, int64 x2, int64 y2) public {
        vm.assume(isReasonableBounds(x1));
        vm.assume(isReasonableBounds(y1));
        vm.assume(isReasonableBounds(x2));
        vm.assume(isReasonableBounds(y2));
        vm.assume(x2 - x1 > 1);
        vm.assume(y2 - y1 > 1);

        uint256 plotId = plotManager.createNewPlot(x1, y1, x2, y2);
        assertEq(plotId, 0);
        assertEq(plotManager.plotCount(), 1);

        // Move the plot by 1 in each direction, so it overlaps with the first plot
        x1 = x1 + 1;
        x2 = x2 + 1;
        y1 = y1 + 1;
        y2 = y2 + 1;

        vm.expectRevert("PlotManager: Plot overlaps with existing plot");
        plotManager.createNewPlot(x1, y1, x2, y2);
    }

    function testAdjoiningPlots(int64 x1, int64 y1, int64 x2, int64 y2, int64 x3, int64 y3) public {
        // vm.assume(x1 < x2);
        // vm.assume(y1 < y2);
        // vm.assume(x2 < x3);
        // vm.assume(y2 < y3);

        // uint256 plotId = plotManager.createNewPlot(x1, y1, x2, y2);
        // assertEq(plotId, 0);
        // assertEq(plotManager.plotCount(), 1);
        // PlotManager.Plot memory plot = plotManager.getPlot(plotId);
        // assertEq(plot.x1, x1);
        // assertEq(plot.y1, y1);
        // assertEq(plot.x2, x2);
        // assertEq(plot.y2, y2);

        // plotId = plotManager.createNewPlot(x2, y2, x3, y3);
        // assertEq(plotId, 1);
        // assertEq(plotManager.plotCount(), 2);
        // plot = plotManager.getPlot(plotId);
        // assertEq(plot.x1, x2);
        // assertEq(plot.y1, y2);
        // assertEq(plot.x2, x3);
        // assertEq(plot.y2, y3);
    }
}
