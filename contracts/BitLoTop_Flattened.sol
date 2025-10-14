// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

/**
 * @title BitLoTop Token (BEP-20 / ERC-20)
 * @notice Simple, fixed-supply token for DEX trading and general use.
 * @dev No owner, no minting, no burning, no fees. Supply minted once at deployment.
 * - Name: BitLoTop
 * - Symbol: BitLoTop
 * - Decimals: 18
 * - Total Supply: 1,000,000,000 * 10^18
 * - Compatible with PancakeSwap and all EVM DEXs.
 */

/// @dev Standard ERC-20 interface
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

/// @dev Metadata interface (name, symbol, decimals)
interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

/// @dev Reentrancy protection
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

/// @title BitLoTop Token Contract
contract BitLoTop is IERC20Metadata, ReentrancyGuard {

    // ----- Token Details -----
    string private constant _NAME = "BitLoTop";
    string private constant _SYMBOL = "BitLoTop";
    uint8 private constant _DECIMALS = 18;
    uint256 private constant _TOTAL_SUPPLY = 1_000_000_000 * 10**18;

    // ----- State -----
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    /// @notice Emitted when the contract is deployed.
    event Deployed(address indexed deployer, uint256 totalSupply);

    /// @notice Deploy token and mint full supply to deployer
    constructor() {
        _balances[msg.sender] = _TOTAL_SUPPLY;
        emit Transfer(address(0), msg.sender, _TOTAL_SUPPLY);
        emit Deployed(msg.sender, _TOTAL_SUPPLY);
    }

    // ----- ERC20 Metadata -----
    function name() external pure override returns (string memory) { return _NAME; }
    function symbol() external pure override returns (string memory) { return _SYMBOL; }
    function decimals() external pure override returns (uint8) { return _DECIMALS; }

    // ----- ERC20 Logic -----
    function totalSupply() external pure override returns (uint256) { return _TOTAL_SUPPLY; }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) external override nonReentrant returns (bool) {
        require(to != address(0), "BitLoTop: transfer to zero address");
        uint256 senderBalance = _balances[msg.sender];
        require(senderBalance >= amount, "BitLoTop: insufficient balance");
        unchecked {
            _balances[msg.sender] = senderBalance - amount;
            _balances[to] += amount;
        }
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        require(spender != address(0), "BitLoTop: approve to zero address");
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount)
        external
        override
        nonReentrant
        returns (bool)
    {
        require(to != address(0), "BitLoTop: transfer to zero address");
        uint256 allowed = _allowances[from][msg.sender];
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "BitLoTop: insufficient balance");
        require(allowed >= amount, "BitLoTop: allowance exceeded");
        unchecked {
            _balances[from] = fromBalance - amount;
            _balances[to] += amount;
            _allowances[from][msg.sender] = allowed - amount;
        }
        emit Transfer(from, to, amount);
        return true;
    }
}
