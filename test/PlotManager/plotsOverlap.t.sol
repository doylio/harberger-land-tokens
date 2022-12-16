// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./PlotManagerTestTemplate.t.sol";
import "../../src/interfaces/IPlotManager.sol";

contract PlotManager_plotsOverlapTest is PlotManagerTestTemplate {
    function testPassingExamples() public {
        IPlotManager.Plot memory plot1 = IPlotManager.Plot(0, 0, 10, 10);
        IPlotManager.Plot memory plot2 = IPlotManager.Plot(20, 20, 30, 30);
        assertEq(plotManager.plotsOverlap(plot1, plot2), false, "No overlap");

        plot1 = IPlotManager.Plot(0, 0, 10, 10);
        plot2 = IPlotManager.Plot(10, 10, 20, 20);
        assertEq(plotManager.plotsOverlap(plot1, plot2), false, "Shared bottom right corner");

        plot1 = IPlotManager.Plot(0, 0, 10, 10);
        plot2 = IPlotManager.Plot(0, 10, 10, 20);
        assertEq(plotManager.plotsOverlap(plot1, plot2), false, "Shared bottom edge");

        plot1 = IPlotManager.Plot(0, 0, 10, 10);
        plot2 = IPlotManager.Plot(10, 0, 20, 10);
        assertEq(plotManager.plotsOverlap(plot1, plot2), false, "Shared right edge");

        plot1 = IPlotManager.Plot(10, 10, 20, 20);
        plot2 = IPlotManager.Plot(0, 0, 10, 10);
        assertEq(plotManager.plotsOverlap(plot1, plot2), false, "Shared top left corner");

        plot1 = IPlotManager.Plot(0, 10, 10, 20);
        plot2 = IPlotManager.Plot(0, 0, 10, 10);
        assertEq(plotManager.plotsOverlap(plot1, plot2), false, "Shared top edge");

        plot1 = IPlotManager.Plot(10, 0, 20, 10);
        plot2 = IPlotManager.Plot(0, 0, 10, 10);
        assertEq(plotManager.plotsOverlap(plot1, plot2), false, "Shared left edge");
    }

    function testSharedBottomEdge(int64 x1, int64 y1, int64 x2, int64 y2, int64 y3) public {
        vm.assume(x1 < x2);
        vm.assume(y1 < y2);
        vm.assume(y2 < y3);

        IPlotManager.Plot memory plot1 = IPlotManager.Plot(x1, y1, x2, y2);
        IPlotManager.Plot memory plot2 = IPlotManager.Plot(x1, y2, x2, y3);
        assertEq(plotManager.plotsOverlap(plot1, plot2), false);
    }

    function testSharedRightEdge(int64 x1, int64 y1, int64 x2, int64 y2, int64 x3) public {
        vm.assume(x1 < x2);
        vm.assume(y1 < y2);
        vm.assume(x2 < x3);

        IPlotManager.Plot memory plot1 = IPlotManager.Plot(x1, y1, x2, y2);
        IPlotManager.Plot memory plot2 = IPlotManager.Plot(x2, y1, x3, y2);
        assertEq(plotManager.plotsOverlap(plot1, plot2), false);
    }

    function testSharedTopEdge(int64 x1, int64 y1, int64 x2, int64 y2, int64 y3) public {
        vm.assume(x1 < x2);
        vm.assume(y1 < y2);
        vm.assume(y3 < y1);

        IPlotManager.Plot memory plot1 = IPlotManager.Plot(x1, y1, x2, y2);
        IPlotManager.Plot memory plot2 = IPlotManager.Plot(x1, y3, x1, y2);
        assertEq(plotManager.plotsOverlap(plot1, plot2), false);
    }

    function testSharedLeftEdge(int64 x1, int64 y1, int64 x2, int64 y2, int64 x3) public {
        vm.assume(x1 < x2);
        vm.assume(y1 < y2);
        vm.assume(x3 < x1);

        IPlotManager.Plot memory plot1 = IPlotManager.Plot(x1, y1, x2, y2);
        IPlotManager.Plot memory plot2 = IPlotManager.Plot(x3, y1, x1, y2);
        assertEq(plotManager.plotsOverlap(plot1, plot2), false);
    }

    function testCornerOverlaps() public {
        IPlotManager.Plot memory plot1 = IPlotManager.Plot(0, 0, 10, 10);
        IPlotManager.Plot memory plot2 = IPlotManager.Plot(5, 5, 15, 15);
        assertEq(plotManager.plotsOverlap(plot1, plot2), true, "Bottom right corner overlap");

        plot1 = IPlotManager.Plot(0, 0, 10, 10);
        plot2 = IPlotManager.Plot(-5, 5, 5, 15);
        assertEq(plotManager.plotsOverlap(plot1, plot2), true, "Bottom left corner overlap");

        plot1 = IPlotManager.Plot(0, 0, 10, 10);
        plot2 = IPlotManager.Plot(-5, -5, 5, 5);
        assertEq(plotManager.plotsOverlap(plot1, plot2), true, "Top left corner overlap");

        plot1 = IPlotManager.Plot(0, 0, 10, 10);
        plot2 = IPlotManager.Plot(5, -5, 15, 5);
        assertEq(plotManager.plotsOverlap(plot1, plot2), true, "Top right corner overlap");
    }

    function testEdgeOverlaps() public {
        IPlotManager.Plot memory plot1 = IPlotManager.Plot(0, 0, 10, 10);
        IPlotManager.Plot memory plot2 = IPlotManager.Plot(5, 0, 15, 10);
        assertEq(plotManager.plotsOverlap(plot1, plot2), true, "Right edge overlap");

        plot1 = IPlotManager.Plot(0, 0, 10, 10);
        plot2 = IPlotManager.Plot(-5, 0, 5, 10);
        assertEq(plotManager.plotsOverlap(plot1, plot2), true, "Left edge overlap");

        plot1 = IPlotManager.Plot(0, 0, 10, 10);
        plot2 = IPlotManager.Plot(0, 5, 10, 15);
        assertEq(plotManager.plotsOverlap(plot1, plot2), true, "Bottom edge overlap");

        plot1 = IPlotManager.Plot(0, 0, 10, 10);
        plot2 = IPlotManager.Plot(0, -5, 10, 5);
        assertEq(plotManager.plotsOverlap(plot1, plot2), true, "Top edge overlap");
    }

    function testEnclaves() public {
        IPlotManager.Plot memory plot1 = IPlotManager.Plot(0, 0, 10, 10);
        IPlotManager.Plot memory plot2 = IPlotManager.Plot(2, 2, 8, 8);
        assertEq(plotManager.plotsOverlap(plot1, plot2), true, "Second plot inside first");

        plot1 = IPlotManager.Plot(2, 2, 8, 8);
        plot2 = IPlotManager.Plot(0, 0, 10, 10);
        assertEq(plotManager.plotsOverlap(plot1, plot2), true, "First plot inside second");
    }

    function testMiddleSplits() public {
        IPlotManager.Plot memory plot1 = IPlotManager.Plot(0, 0, 10, 10);
        IPlotManager.Plot memory plot2 = IPlotManager.Plot(-5, 2, 15, 8);
        assertEq(plotManager.plotsOverlap(plot1, plot2), true, "Middle split horizontally");

        plot1 = IPlotManager.Plot(0, 0, 10, 10);
        plot2 = IPlotManager.Plot(2, -5, 8, 15);
        assertEq(plotManager.plotsOverlap(plot1, plot2), true, "Middle split vertically");
    }
}
