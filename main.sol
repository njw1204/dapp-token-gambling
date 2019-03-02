/// @author njw1204

pragma solidity ^0.5.0;
import "./ERC621BaseToken.sol";
import "./util/util.sol";
import "./lib/oraclizeAPI_0.5.sol";


contract Custom {
    string public constant tokenName = "Game Medal";
    string public constant tokenSymbol = "MEDAL";
    uint8 public constant tokenDecimals = 0;
    uint256 internal constant initTokens = 10000;
    uint256 internal constant donateForTokenMinBound = 0.1 ether;
    uint256 internal constant donateForTokenRatio = 0.01 ether;

    bool public freeMode = false;
    bool internal enableFixedBonusDonate = true;
    bool internal enableRandomBonusDonate = true;
    uint256 internal oraclizeGasPrice = 1000000000; // 1 gwei
    uint256 internal oraclizeGasLimit = 150000;
}


contract GameMedal is ERC621BaseToken, usingOraclize, Util, Custom {
    using SafeMath for uint256;

    enum QueryType {
        DONATE_BONUS, TOKEN_BET
    }

    struct RandomQuery {
        QueryType typ;
        address who;
        uint256 blockNumber;
        uint256 minBound;
        uint256 maxBound;
        uint256 param1;
        uint256 param2;
    }

    mapping (bytes32 => RandomQuery) QQ;

    event Donate(address indexed from, uint256 value);
    event DonateForRandomBonusToken(address indexed from, uint256 value);
    event DonateForFixedBonusToken(address indexed from, uint256 value);
    event DonateBonusResult(address indexed user, uint256 minBound, uint256 maxBound, uint256 resultValue);
    event LogNewOraclizeQuery(bytes32 indexed queryId, uint256 queryPrice, string description);
    event LogOraclizeCallback(bytes32 indexed queryId, string result);

    modifier onlyFreeMode() {
        require(freeMode);
        _;
    }

    constructor () ERC621BaseToken(tokenName, tokenSymbol, tokenDecimals, initTokens) public {
        oraclize_setCustomGasPrice(oraclizeGasPrice);
    }

    function () external payable {
        // thanks for donate (no bonus token)
        emit Donate(msg.sender, msg.value);
    }

    function __callback(bytes32 myid, string memory result) public {
        // callback from oraclize (random query)
        require(msg.sender == oraclize_cbAddress());
        RandomQuery storage query = QQ[myid];

        emit LogOraclizeCallback(myid, result);

        // use blockhash together for security reason
        uint256 randomHash = uint256(keccak256(abi.encodePacked(blockhash(query.blockNumber), result)));
        // minBound <= diceResult <= maxBound
        uint256 diceResult = randomHash.mod(query.maxBound.sub(query.minBound).add(1)).add(query.minBound);

        if (query.typ == QueryType.DONATE_BONUS) {
            // query for ether donate
            emit DonateBonusResult(query.who, query.minBound, query.maxBound, diceResult);
            _increaseSupply(diceResult, query.who);
        }
        else {
            revert();
        }
    }

    function donateForFixedBonusToken() external payable {
        // thanks for donate, and get fixed bonus
        require(enableFixedBonusDonate && msg.value >= donateForTokenMinBound);
        uint256 bound = msg.value.div(donateForTokenRatio);
        // prevent too much supply
        require(_totalSupply.add(bound) <= UINT250_MAX);

        emit DonateForFixedBonusToken(msg.sender, msg.value);
        emit DonateBonusResult(msg.sender, bound, bound, bound);
        _increaseSupply(bound, msg.sender);
    }

    function donateForRandomBonusToken() external payable {
        // thanks for donate, and get random bonus
        require(enableRandomBonusDonate && msg.value >= donateForTokenMinBound);

        uint256 price = oraclize_getPrice("random", oraclizeGasLimit);
        require(address(this).balance >= price);

        RandomQuery memory bonus = RandomQuery(
            QueryType.DONATE_BONUS, msg.sender, block.number,
            1, msg.value.div(donateForTokenRatio).mul(2).sub(1), 0, 0
        );
        // prevent too much supply
        require(_totalSupply.add(bonus.maxBound) <= UINT250_MAX);

        // callback process, params : delay, randomBytes, gasLimit
        bytes32 queryId = oraclize_newRandomDSQuery(0, 32, oraclizeGasLimit);
        QQ[queryId] = bonus;

        emit DonateForRandomBonusToken(msg.sender, msg.value);
        emit LogNewOraclizeQuery(queryId, price, "oraclize_newRandomDSQuery");
    }

    function burnToken(uint256 tokens) external returns (bool success) {
        return transfer(address(0), tokens);
    }

    function giveMeFreeToken() external onlyFreeMode returns (bool success) {
        // free token!! when freeMode is true
        uint256 limit = 100;
        // prevent too much supply
        require(_totalSupply.add(limit) <= UINT250_MAX);
        // set user balance to limit
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

    function setEnableFixedBonusDonate(bool enable) external onlyOwner {
        enableFixedBonusDonate = enable;
    }

    function setEnableRandomBonusDonate(bool enable) external onlyOwner {
        enableRandomBonusDonate = enable;
    }

    function setOraclizeGasPrice(uint256 gasPrice) external onlyOwner {
        oraclizeGasPrice = gasPrice;
    }

    function setOraclizeGasLimit(uint256 gasLimit) external onlyOwner {
        oraclizeGasLimit = gasLimit;
    }
}