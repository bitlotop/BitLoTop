// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

/*
    BitLoTop (EIP-20 / BEP-20)
    - Name: BitLoTop
    - Symbol: BitLoTop
    - Site: bitlo.top
    - Decimals: 18
    - Total supply: 1,000,000,000 * 10^18 (fixed, minted once at deployment)
    - Fully DEX compatible (approve + transferFrom)
    - No owner / no admin / no mint / no burn / no fees
    - Reentrancy guard included (nonReentrant) for improved scanner ratings
    - Compiler version locked to 0.8.19 for reproducible builds
*/

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

abstract contract ReentrancyGuard {
    uint256 private _status;
    constructor() { _status = 1; }
    modifier nonReentrant() {
        require(_status == 1, "ReentrancyGuard: reentrant call");
        _status = 2;
        _;
        _status = 1;
    }
}

contract BitLoTop is IERC20Metadata, ReentrancyGuard {
    string private _name = "BitLoTop";
    string private _symbol = "BitLoTop";
    uint8 private _decimals = 18;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    constructor() {
        uint256 initial = 1_000_000_000 * (10 ** uint256(_decimals));
        _totalSupply = initial;
        _balances[msg.sender] = initial;
        emit Transfer(address(0), msg.sender, initial);
    }

    function name() external view override returns (string memory) { return _name; }
    function symbol() external view override returns (string memory) { return _symbol; }
    function decimals() external view override returns (uint8) { return _decimals; }
    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function balanceOf(address account) external view override returns (uint256) { return _balances[account]; }

    function transfer(address to, uint256 amount) external override nonReentrant returns (bool) {
        require(to != address(0), "BitLoTop: transfer to zero");
        uint256 senderBal = _balances[msg.sender];
        require(senderBal >= amount, "BitLoTop: insufficient balance");
        unchecked {
            _balances[msg.sender] = senderBal - amount;
            _balances[to] += amount;
        }
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        require(spender != address(0), "BitLoTop: approve to zero");
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external override nonReentrant returns (bool) {
        require(from != address(0), "BitLoTop: transfer from zero");
        require(to != address(0), "BitLoTop: transfer to zero");
        uint256 fromBal = _balances[from];
        require(fromBal >= amount, "BitLoTop: insufficient balance");
        uint256 allowed = _allowances[from][msg.sender];
        require(allowed >= amount, "BitLoTop: allowance exceeded");
        unchecked {
            _balances[from] = fromBal - amount;
            _balances[to] += amount;
            _allowances[from][msg.sender] = allowed - amount;
        }
        emit Transfer(from, to, amount);
        return true;
    }
}
