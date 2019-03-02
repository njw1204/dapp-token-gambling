/// @author njw1204

pragma solidity ^0.5.0;
import "./ERC621BaseToken.sol";
import "./util/util.sol";


contract Custom {
    string public constant tokenName = "Game Medal";
    string public constant tokenSymbol = "MEDAL";
    uint8 public constant tokenDecimals = 0;
    uint256 internal constant initTokens = 10000;
}


contract GameMedal is ERC621BaseToken, Util, Custom {
    using SafeMath for uint256;

    bool public freeMode = false;

    modifier onlyFreeMode() {
        require(freeMode);
        _;
    }

    constructor () ERC621BaseToken(tokenName, tokenSymbol, tokenDecimals, initTokens) public {

    }

    function () external payable {

    }

    function burnToken(uint256 tokens) external returns (bool success) {
        return transfer(address(0), tokens);
    }

    function giveMeFreeToken() external onlyFreeMode returns (bool success) {
        // free token!! when freeMode is true
        uint256 limit = 100;
        // prvent too much supply
        require(_totalSupply.add(limit) <= UINT250_MAX);
        // make user balance to limit
        return _increaseSupply(limit.sub(balances[msg.sender]), msg.sender);
    }

    function transferAnyERC20Token(address tokenAddress, address to, uint256 tokens) external onlyOwner returns (bool success) {
        // transfer accidentally sent tokens to the original owner
        return ERC20Interface(tokenAddress).transfer(to, tokens);
    }

    function withdrawEther() external onlyOwner {
        // get donated ether
        msg.sender.transfer(address(this).balance);
    }

    function setFreeMode(bool free) external onlyOwner {
        // when freeMode you can call giveMeFreeToken() and get tokens
        freeMode = free;
    }
}