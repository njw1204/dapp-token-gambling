pragma solidity ^0.5.0;
import "lib/SafeMath.sol";
import "lib/Ownable.sol";


contract ERC20Interface {
    function totalSupply() public view returns (uint256);
    function balanceOf(address tokenOwner) public view returns (uint256 balance);
    function allowance(address tokenOwner, address spender) public view returns (uint256 remaining);
    function transfer(address to, uint256 tokens) public returns (bool success);
    function approve(address spender, uint256 tokens) public returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}


contract ERC621Interface is ERC20Interface {
    function increaseSupply(uint256 value, address to) public returns (bool success);
    function decreaseSupply(uint256 value, address from) public returns (bool success);
}


contract ERC621BaseToken is ERC621Interface, Ownable {
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 internal _totalSupply;
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    constructor (string memory _name, string memory _symbol, uint8 _decimals, uint256 initTokens) internal {
        require(_decimals <= 18);
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        _totalSupply = initTokens.mul(uint256(10) ** decimals);
        balances[_owner] = _totalSupply;
        emit Transfer(address(0), _owner, _totalSupply);
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address tokenOwner) public view returns (uint256 balance) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public view returns (uint256 remaining) {
        return allowed[tokenOwner][spender];
    }

    function transfer(address to, uint256 tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        if (to == address(0)) _totalSupply = _totalSupply.sub(tokens);
        else balances[to] = balances[to].add(tokens);

        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function approve(address spender, uint256 tokens) public returns (bool success) {
        // allow third party to transfer my balance
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint256 tokens) public returns (bool success) {
        // transfer third party's balance up to approved value
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[from] = balances[from].sub(tokens);
        if (to == address(0)) _totalSupply = _totalSupply.sub(tokens);
        else balances[to] = balances[to].add(tokens);

        emit Transfer(from, to, tokens);
        return true;
    }

    function _increaseSupply(uint256 value, address to) internal returns (bool success) {
        // make new tokens and give someone (SECURITY ALERT)
        require(to != address(0));
        _totalSupply = _totalSupply.add(value);
        balances[to] = balances[to].add(value);

        emit Transfer(address(0), to, value);
        return true;
    }

    function increaseSupply(uint256 value, address to) public onlyOwner returns (bool success) {
        return _increaseSupply(value, to);
    }

    function _decreaseSupply(uint256 value, address from) internal returns (bool success) {
        // burn someone's tokens (SECURITY ALERT)
        require(from != address(0));
        balances[from] = balances[from].sub(value);
        _totalSupply = _totalSupply.sub(value);

        emit Transfer(from, address(0), value);
        return true;
    }

    function decreaseSupply(uint256 value, address from) public onlyOwner returns (bool success) {
        // not using, only for ERC621
        revert();
        return false;
    }
}