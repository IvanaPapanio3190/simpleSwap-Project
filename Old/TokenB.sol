// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Basic ERC20 token implementation for TokenB
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20 is IERC20 {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 private _totalSupply;

    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        require(_allowances[sender][msg.sender] >= amount, "ERC20: insufficient allowance");
        _allowances[sender][msg.sender] -= amount;
        _transfer(sender, recipient, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(_balances[from] >= amount, "ERC20: insufficient balance");
        _balances[from] -= amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal {
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }
}

contract TokenB is ERC20 {
    constructor(uint256 initialSupply) ERC20("TokenB", "TKB") {
        _mint(msg.sender, initialSupply);
    }
}
