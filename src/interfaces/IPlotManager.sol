// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IPlotManager {
    struct Plot {
        int64 x1;
        int64 y1;
        int64 x2;
        int64 y2;
    }

    function estateRegistry() external view returns (address);

    function plotCount() external view returns (uint256);

    function getPlot(uint256 _plotId) external view returns (Plot memory);

    function createNewPlot(int64 _x1, int64 _y1, int64 _x2, int64 _y2) external returns (uint256);

    function revokePlot(uint256 _plotId) external returns (bool);

    function combinePlots(uint256 _plotIdA, uint256 _plotIdB, bool joinVertically) external returns (uint256);

    function splitPlot(uint256 _plotId, bool _verticalSplit, int64 _lineOfSplit) external returns (uint256, uint256);

    function plotsOverlap(Plot memory plotA, Plot memory plotB) external pure returns (bool);

    function isValidPlot(int64 _x1, int64 _y1, int64 _x2, int64 _y2) external pure returns (bool);

    function plotsConnectVertically(Plot memory plotA, Plot memory plotB) external pure returns (bool);

    function plotsConnectHorizontally(Plot memory plotA, Plot memory plotB) external pure returns (bool);
}
