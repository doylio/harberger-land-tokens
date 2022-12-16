pragma solidity ^0.8.9;

import "../interfaces/ERC5320.sol";
import "../interfaces/IPlotManager.sol";
import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/token/ERC721/ERC721.sol";
import "openzeppelin-contracts/token/ERC20/IERC20.sol";

contract EstateRegistry is IERC5320, Ownable, ERC721 {
    address public plotManager;

    address public paymentToken;
    uint256 public numEstates;

    uint256 public liquidationMarginBps;
    uint256 public constant BPS = 10000;

    mapping(uint256 => uint256) public plotsToEstate;

    /// @dev 18 decimals
    /// @dev Percent of valuation per year
    uint256 public taxRate;

    // Token Id to current valuation
    mapping(uint256 => uint256) private _valuations;
    uint256 public totalValuations;

    mapping(uint256 => uint256) public lastTokenCheckpointTime;
    mapping(uint256 => uint256) public lastTokenCheckpointBalance;

    uint256 public lastGlobalCheckpointTime;
    uint256 public lastGlobalCheckpointBalance;

    event EstateCreated(uint256 estateId, address owner, uint256 valuation);

    constructor(string memory _name, string memory _symbol, address _paymentToken, uint256 _taxRate)
        ERC721(_name, _symbol)
    {
        paymentToken = _paymentToken;
        taxRate = _taxRate;
    }

    // ADMIN FUNCTIONS

    function setPlotManager(address _plotManager) external onlyOwner {
        plotManager = _plotManager;
    }

    function revoke(uint256 _tokenId) external onlyOwner {
        _removeToken(_tokenId);
    }

    // PUBLIC FUNCTIONS

    function mint(uint256 valuation, uint256 initialPayment) external {
        uint256 estateId = numEstates;
        numEstates++;
        _mint(msg.sender, estateId);

        _checkpointToken(estateId, initialPayment, valuation);

        IERC20(paymentToken).transferFrom(msg.sender, address(this), initialPayment);
        emit EstateCreated(estateId, msg.sender, valuation);
    }

    function fund(uint256 _tokenId, uint256 _value) external {
        uint256 balance = tokenBalance(_tokenId);
        _checkpointToken(_tokenId, balance + _value, valuations(_tokenId));
        IERC20(paymentToken).transferFrom(msg.sender, address(this), _value);
    }

    function defund(uint256 _tokenId, uint256 _value) external {
        require(ownerOf(_tokenId) == msg.sender, "PropertyRegistry: Only owner can defund");

        uint256 balance = tokenBalance(_tokenId);
        require(balance > _value, "PropertyRegistry: Insufficient balance");

        _checkpointToken(_tokenId, balance - _value, valuations(_tokenId));
        IERC20(paymentToken).transferFrom(address(this), msg.sender, _value);
    }

    function buy(uint256 _tokenId, uint256 _offer, uint256 _valuation, uint256 _fund) external override {
        // Prevents front-running
        require(_offer == valuations(_tokenId), "PropertyRegistry: Offer must be equal to valuation");

        uint256 remainingBalance = tokenBalance(_tokenId);
        address currentOwner = ownerOf(_tokenId);

        // Remove the remaining balance
        _checkpointToken(_tokenId, 0, 0);
        _transfer(currentOwner, msg.sender, _tokenId);
        _checkpointToken(_tokenId, _fund, _valuation);

        IERC20(paymentToken).transferFrom(msg.sender, address(this), _fund + _offer);
        IERC20(paymentToken).transferFrom(address(this), currentOwner, _offer + remainingBalance);
    }

    function abandon(uint256 _tokenId) external {
        require(ownerOf(_tokenId) == msg.sender, "PropertyRegistry: Only owner can abandon");
        uint256 balance = tokenBalance(_tokenId);
        _removeToken(_tokenId);
        IERC20(paymentToken).transferFrom(address(this), msg.sender, balance);
    }

    function liquidate(uint256 _tokenId) external {
        uint256 liquidationThreshold = valuations(_tokenId) * liquidationMarginBps / BPS;
        uint256 balance = tokenBalance(_tokenId);
        require(balance < liquidationThreshold, "PropertyRegistry: Token is not liquidatable");
        _removeToken(_tokenId);
        IERC20(paymentToken).transferFrom(address(this), msg.sender, balance);
    }

    function collect(uint256 _tokenId) external override {
        // NO OP
    }

    function collectAll() external {
        uint256 taxCollected = IERC20(paymentToken).balanceOf(address(this)) - globalBalance();
        IERC20(paymentToken).transferFrom(address(this), owner(), taxCollected);
    }

    function changeValuation(uint256 _tokenId, uint256 _valuation) external {
        require(ownerOf(_tokenId) == msg.sender, "PropertyRegistry: Only owner can change valuation");
        uint256 balance = tokenBalance(_tokenId);
        _checkpointToken(_tokenId, balance, _valuation);
    }

    // INTERNAL FUNCTIONS

    function _checkpointToken(uint256 _tokenId, uint256 _balance, uint256 _valuation) internal {
        uint256 prevBalance = tokenBalance(_tokenId);

        // Update the token balance
        lastTokenCheckpointBalance[_tokenId] = _balance;
        lastTokenCheckpointTime[_tokenId] = block.timestamp;

        // Update the global balance
        uint256 currentGlobalBalance = globalBalance();
        lastGlobalCheckpointBalance = currentGlobalBalance + _balance - prevBalance;
        lastGlobalCheckpointTime = block.timestamp;

        _valuations[_tokenId] = _valuation;
        totalValuations += _valuation;
    }

    function _removeToken(uint256 _tokenId) internal {
        uint256 currentTokenBalance = tokenBalance(_tokenId);
        _checkpointToken(_tokenId, 0, 0);
        _burn(_tokenId);
    }

    // VIEW FUNCTIONS

    function valuations(uint256 _tokenId) public view returns (uint256) {
        require(_tokenId < numEstates, "PropertyRegistry: Token ID is out of range");
        return _valuations[_tokenId];
    }

    function tokenBalance(uint256 _tokenId) public view returns (uint256) {
        uint256 timeDelta = block.timestamp - lastTokenCheckpointTime[_tokenId];
        return lastTokenCheckpointBalance[_tokenId] - (valuations(_tokenId) * timeDelta * taxRate / 52 weeks);
    }

    function globalBalance() public view returns (uint256) {
        uint256 timeDelta = block.timestamp - lastGlobalCheckpointTime;
        return lastGlobalCheckpointBalance - (totalValuations * timeDelta * taxRate / 52 weeks);
    }

    // OVERRIDES

    function _transfer(address from, address to, uint256 tokenId) internal override (ERC721) {
        revert("PropertyRegistry: Transfer from is not allowed");
    }
}
