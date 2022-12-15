pragma solidity ^0.8.9;

import "../interfaces/ERC5320.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PropertyRegistry is IERC5320, Ownable, ERC721 {
    address public paymentToken;
    uint256 public numTokens;

    int256 public TOKEN_REVOKAL_THRESHOLD;

    /// @dev 18 decimals
    /// @dev Per second
    int256 public taxRate;

    mapping(uint256 => uint256) private _valuations;
    int256 public totalValuations;

    mapping(uint256 => uint256) public lastTokenCheckpointTime;
    mapping(uint256 => int256) public lastTokenCheckpointBalance;

    uint256 public lastGlobalCheckpointTime;
    int256 public lastGlobalCheckpointBalance;

    constructor(string memory _name, string memory _symbol, address _paymentToken, int256 _taxRate) ERC721(_name, _symbol) {
        paymentToken = _paymentToken;
        taxRate = _taxRate;
    }

    function mint(address _owner, uint256 _valuation) external {
        require(_valuation > 0, "PropertyRegistry: Valuation must be greater than 0");
        uint256 tokenId = numTokens;
        _mint(_owner, tokenId);
        _valuations[tokenId] = _valuation;
        numTokens++;
    }


    function fund(uint256 _tokenId, uint256 _value) external {
        int256 userBalance = tokenBalance(_tokenId);
        _updateTokenBalance(_tokenId, int256(_value));
        IERC20(paymentToken).transferFrom(msg.sender, address(this), _value);
    }

    function defund(uint256 _tokenId, uint256 _value) external {
        int256 userBalance = tokenBalance(_tokenId);
        _updateTokenBalance(_tokenId, int256(_value) * -1);
        IERC20(paymentToken).transferFrom(address(this), msg.sender, _value);
        
    }

    function buy(uint256 _tokenId, uint256 _offer, uint256 _valuation, uint256 _fund) external {
        // Prevents front-running
        require(_offer == valuations(_tokenId), "PropertyRegistry: Offer must be equal to valuation");

        int256 remainingBalance = tokenBalance(_tokenId);
        address currentOwner = ownerOf(_tokenId);

        int256 valuationDelta = int256(_valuation - _offer);
        _updateValuation(_tokenId, valuationDelta);

        int256 balanceDelta = int256(_fund) - remainingBalance;
        _updateTokenBalance(_tokenId, balanceDelta);

        _transfer(currentOwner, msg.sender, _tokenId);
        IERC20(paymentToken).transferFrom(msg.sender, address(this), _fund + _offer);
        IERC20(paymentToken).transferFrom(address(this), currentOwner, _offer + uint256(remainingBalance));
    }

    function revoke(uint256 _tokenId) external onlyOwner {
        require(tokenBalance(_tokenId) <= TOKEN_REVOKAL_THRESHOLD, "PropertyRegistry: Token balance must be less than revokal threshold");
        _revokeToken(_tokenId);
    }

    function collect(uint256 _tokenId) external {
        // TODO
    }

    function changeValuation(uint256 _tokenId, uint256 _valuation) external {
        // TODO
    }

    function _updateTokenBalance(uint256 _tokenId, int256 _delta) internal {
        // Update the token balance
        int256 currentTokenBalance = tokenBalance(_tokenId);
        int256 newBalance = currentTokenBalance + _delta;
        require(newBalance >= 0, "PropertyRegistry: Token balance cannot be negative");

        lastTokenCheckpointBalance[_tokenId] = newBalance;
        lastTokenCheckpointTime[_tokenId] = block.timestamp;

        // Update the global balance
        int256 currentGlobalBalance = globalBalance();
        lastGlobalCheckpointBalance = currentGlobalBalance + _delta;
        lastGlobalCheckpointTime = block.timestamp;
    }

    function _updateValuation(uint256 _tokenId, int256 _delta) internal {
        // Checkpoint the token balance
        lastTokenCheckpointBalance[_tokenId] = tokenBalance(_tokenId);
        lastTokenCheckpointTime[_tokenId] = block.timestamp;

        // Checkpoint the global balance
        lastGlobalCheckpointBalance = globalBalance();
        lastGlobalCheckpointTime = block.timestamp;

        // Update the token valuation
        int256 currentValuation = int256(valuations(_tokenId));
        _valuations[_tokenId] = uint256(currentValuation + _delta);
        totalValuations += _delta;
    }

    function _revokeToken(uint256 _tokenId) internal {
        int256 currentTokenBalance = tokenBalance(_tokenId);
        _updateTokenBalance(_tokenId, int256(-currentTokenBalance));
        int256 currentTokenValuation = int256(valuations(_tokenId));
        _updateValuation(_tokenId, int256(-currentTokenValuation));

        // Update the global balance
        lastGlobalCheckpointBalance = globalBalance();
        lastGlobalCheckpointTime = block.timestamp;
        _burn(_tokenId);
    }

    // GETTERS
    function valuations(uint _tokenId) public view returns (uint256) {
        require(_tokenId < numTokens, "PropertyRegistry: Token ID is out of range");
        return _valuations[_tokenId];
    }

    function tokenBalance(uint256 _tokenId) public view returns (int256) {
        int256 timeDelta = int256(block.timestamp - lastTokenCheckpointTime[_tokenId]);
        int256 valuation = int256(valuations(_tokenId));
        return lastTokenCheckpointBalance[_tokenId] - (valuation * timeDelta * taxRate);
    }

    function globalBalance() public view returns (int256) {
        int256 timeDelta = int256(block.timestamp - lastGlobalCheckpointTime);
        return lastGlobalCheckpointBalance - (totalValuations * timeDelta * taxRate);
    }


    // OVERRIDES
    function transferFrom(address from, address to, uint256 tokenId) public pure override(ERC721, IERC721) {
        revert("PropertyRegistry: Transfer from is not allowed");
    }



}