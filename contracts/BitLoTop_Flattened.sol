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
    - Compiler version locked to 0.8.29 for reproducible builds
*/

// --------------------------------------------------
// IERC20
// --------------------------------------------------
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

// --------------------------------------------------
// IERC20Metadata
// --------------------------------------------------
interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

// --------------------------------------------------
// ReentrancyGuard (gas-optimized)
// --------------------------------------------------
abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status == _NOT_ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

// --------------------------------------------------
// BitLoTop Token Implementation
// --------------------------------------------------
contract BitLoTop is IERC20Metadata, ReentrancyGuard {
    // ----- Constants -----
    string private constant _NAME = "BitLoTop";
    string private constant _SYMBOL = "BitLoTop";
    uint8 private constant _DECIMALS = 18;
    uint256 private constant _TOTAL_SUPPLY = 1_000_000_000 * 10**18;

    // ----- Storage -----
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    // ----- Constructor -----
    constructor() {
        _balances[msg.sender] = _TOTAL_SUPPLY;
        emit Transfer(address(0), msg.sender, _TOTAL_SUPPLY);
    }

    // ----- ERC20 Metadata -----
    function name() external pure override returns (string memory) { return _NAME; }
    function symbol() external pure override returns (string memory) { return _SYMBOL; }
    function decimals() external pure override returns (uint8) { return _DECIMALS; }

    // ----- ERC20 Logic -----
    function totalSupply() external pure override returns (uint256) { return _TOTAL_SUPPLY; }
    function balanceOf(address account) external view override returns (uint256) { return _balances[account]; }

    function transfer(address to, uint256 amount) external override nonReentrant returns (bool) {
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
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external override nonReentrant returns (bool) {
        uint256 allowed = _allowances[from][msg.sender];
        uint256 fromBal = _balances[from];
        require(fromBal >= amount, "BitLoTop: insufficient balance");
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
