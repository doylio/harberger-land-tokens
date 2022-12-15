// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract PlotManager {
    struct Plot {
        int256 x1;
        int256 y1;
        int256 x2;
        int256 y2;
    }

    uint256 public plotCount;
    mapping(uint256 => Plot) public plots;

    event PlotCreated(uint256 plotId, int256 x1, int256 y1, int256 x2, int256 y2);
    event PlotDeleted(uint256 plotId);

    function _createNewPlot(int256 _x1, int256 _y1, int256 _x2, int256 _y2) internal {
        require(isValidPlot(_x1, _y1, _x2, _y2), "PlotManager: Invalid plot");
        Plot memory newPlot = Plot( _x1, _y1, _x2, _y2);
        for (uint256 i = 0; i < plotCount; i++) {
            require(!plotsOverlap(plots[i], newPlot), "PlotManager: Plot overlaps with existing plot");
        }
        _savePlot(newPlot);
    }

    function plotsOverlap(Plot memory plot1, Plot memory plot2) public pure returns (bool) {
        return (plot1.x1 <= plot2.x2 
            && plot1.x2 >= plot2.x1 
            && plot1.y1 <= plot2.y2 
            && plot1.y2 >= plot2.y1
        );
    }

    function isValidPlot(int256 _x1, int256 _y1, int256 _x2, int256 _y2) public pure returns (bool) {
        return (_x1 < _x2 && _y1 < _y2);
    }

    function revokePlot(uint256 _plotId) external {
        _deletePlot(_plotId);
    }

    function combinePlots(uint256 _plotIdA, uint256 _plotIdB) external {
        Plot memory plotA = plots[_plotIdA];
        Plot memory plotB = plots[_plotIdB];

        bool joinedVertically = (plotA.x1 == plotB.x1 && plotA.x2 == plotB.x2 && plotA.y2 == plotB.y1);
        bool joinedHorizontally = (plotA.y1 == plotB.y1 && plotA.y2 == plotB.y2 && plotA.x2 == plotB.x1);

        Plot memory newPlot;
        if (joinedVertically) {
            newPlot = Plot(plotA.x1, plotA.y1, plotB.x2, plotB.y2);
        } else if (joinedHorizontally) {
            newPlot = Plot(plotA.x1, plotA.y1, plotB.x2, plotB.y2);
        } else {
            revert("PlotManager: Plots must be joined vertically or horizontally");
        }

        _deletePlot(_plotIdA);
        _deletePlot(_plotIdB);
        _savePlot(newPlot);
    }

    function splitPlot(uint256 _plotId, bool _splitThruXAxis, int256 _lineOfSplit) external {
        Plot memory sourcePlot = plots[_plotId];
        Plot memory plotA;
        Plot memory plotB;
        if (_splitThruXAxis) {
            plotA = Plot(sourcePlot.x1, sourcePlot.y1, sourcePlot.x2, _lineOfSplit);
            plotB = Plot(sourcePlot.x1, _lineOfSplit, sourcePlot.x2, sourcePlot.y2);
        } else {
            plotA = Plot(sourcePlot.x1, sourcePlot.y1, _lineOfSplit, sourcePlot.y2);
            plotB = Plot(_lineOfSplit, sourcePlot.y1, sourcePlot.x2, sourcePlot.y2);
        }
        _deletePlot(_plotId);
        _savePlot(plotA);
        _savePlot(plotB);
    }

    function _savePlot(Plot memory _plot) internal returns(uint256) {
        uint256 plotId = plotCount;
        plots[plotId] = _plot;
        plotCount++;
        emit PlotCreated(plotId, _plot.x1, _plot.y1, _plot.x2, _plot.y2);
        return plotId;
    }

    function _deletePlot(uint256 _plotId) internal {
        delete plots[_plotId];
        emit PlotDeleted(_plotId);
    }
}
