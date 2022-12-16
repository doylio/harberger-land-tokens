// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "openzeppelin-contracts/token/ERC721/ERC721.sol";
import "../interfaces/IPlotManager.sol";

contract PlotManager is IPlotManager {
    address public immutable estateRegistry;

    uint256 public plotCount;
    mapping(uint256 => Plot) public plots;

    event PlotCreated(uint256 plotId, int64 x1, int64 y1, int64 x2, int64 y2);
    event PlotDeleted(uint256 plotId);

    constructor(address _estateRegistry) {
        estateRegistry = _estateRegistry;
    }

    // TODO remove this and have the PlotManager check the ownership in the EstateRegistry
    modifier onlyEstateRegistry() {
        require(msg.sender == estateRegistry, "PlotManager: Only EstateRegistry can call this function");
        _;
    }

    function createNewPlot(int64 _x1, int64 _y1, int64 _x2, int64 _y2) external override returns (uint256) {
        require(isValidPlot(_x1, _y1, _x2, _y2), "PlotManager: Invalid plot");
        Plot memory newPlot = Plot(_x1, _y1, _x2, _y2);
        for (uint256 i = 0; i < plotCount; i++) {
            require(!plotsOverlap(plots[i], newPlot), "PlotManager: Plot overlaps with existing plot");
        }

        return _savePlot(newPlot);
    }

    function revokePlot(uint256 _plotId) external override onlyEstateRegistry returns (bool) {
        return _deletePlotById(_plotId);
    }

    function combinePlots(uint256 _plotIdA, uint256 _plotIdB, bool joinVertically)
        external
        override
        onlyEstateRegistry
        returns (uint256)
    {
        Plot memory plotA = plots[_plotIdA];
        Plot memory plotB = plots[_plotIdB];

        if (joinVertically) {
            require(plotsConnectVertically(plotA, plotB), "PlotManager: Plots must be joined vertically");
        } else {
            require(plotsConnectHorizontally(plotA, plotB), "PlotManager: Plots must be joined horizontally");
        }

        Plot memory newPlot = Plot(plotA.x1, plotA.y1, plotB.x2, plotB.y2);

        _deletePlotById(_plotIdA);
        _deletePlotById(_plotIdB);
        return _savePlot(newPlot);
    }

    function splitPlot(uint256 _plotId, bool _verticalSplit, int64 _lineOfSplit)
        external
        override
        onlyEstateRegistry
        returns (uint256, uint256)
    {
        Plot memory sourcePlot = plots[_plotId];
        Plot memory plotA;
        Plot memory plotB;
        if (_verticalSplit) {
            require(_lineOfSplit > sourcePlot.x1 && _lineOfSplit < sourcePlot.x2, "PlotManager: Invalid line of split");
            plotA = Plot(sourcePlot.x1, sourcePlot.y1, _lineOfSplit, sourcePlot.y2);
            plotB = Plot(_lineOfSplit, sourcePlot.y1, sourcePlot.x2, sourcePlot.y2);
        } else {
            require(_lineOfSplit > sourcePlot.y1 && _lineOfSplit < sourcePlot.y2, "PlotManager: Invalid line of split");
            plotA = Plot(sourcePlot.x1, sourcePlot.y1, sourcePlot.x2, _lineOfSplit);
            plotB = Plot(sourcePlot.x1, _lineOfSplit, sourcePlot.x2, sourcePlot.y2);
        }
        _deletePlotById(_plotId);
        return (_savePlot(plotA), _savePlot(plotB));
    }

    // INTERNAL FUNCTIONS

    function _savePlot(Plot memory _plot) internal returns (uint256) {
        uint256 plotId = plotCount;
        plots[plotId] = _plot;
        plotCount++;
        emit PlotCreated(plotId, _plot.x1, _plot.y1, _plot.x2, _plot.y2);
        return plotId;
    }

    function _deletePlotById(uint256 _plotId) internal returns (bool) {
        delete plots[_plotId];
        emit PlotDeleted(_plotId);
        return true;
    }

    // VIEWS AND PURE FUNCTIONS

    function getPlot(uint256 _plotId) external view override returns (Plot memory) {
        return plots[_plotId];
    }

    function plotsOverlap(Plot memory plotA, Plot memory plotB) public pure override returns (bool) {
        return (plotA.x1 < plotB.x2 && plotA.x2 > plotB.x1 && plotA.y1 < plotB.y2 && plotA.y2 > plotB.y1);
    }

    function isValidPlot(int64 _x1, int64 _y1, int64 _x2, int64 _y2) public pure override returns (bool) {
        return (_x1 < _x2 && _y1 < _y2);
    }

    function plotsConnectVertically(Plot memory plotA, Plot memory plotB) public pure override returns (bool) {
        return (plotA.x1 == plotB.x1 && plotA.x2 == plotB.x2 && plotA.y2 == plotB.y1);
    }

    function plotsConnectHorizontally(Plot memory plotA, Plot memory plotB) public pure override returns (bool) {
        return (plotA.y1 == plotB.y1 && plotA.y2 == plotB.y2 && plotA.x2 == plotB.x1);
    }
}
