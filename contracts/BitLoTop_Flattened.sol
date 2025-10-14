// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

/**
 * @title BitLoTop Token (BEP-20 / ERC-20)
 * @author BitLo
 * @notice BitLoTop is a fixed-supply, minimal ERC-20/BEP-20 token intended for DEX trading and general use.
 * @dev Implementation is intentionally minimal and immutable: no owner/admin, no mint, no burn, no fees.
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

/**
 * @title ReentrancyGuard (Minimal)
 * @author BitLo
 * @dev Lightweight reentrancy protection modifier for external functions.
 */
abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status == _NOT_ENTERED, "reentrant");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

/**
 * @title BitLoTop (Final Gas Optimized)
 * @author BitLo
 * @notice Fully ERC-20/BEP-20 compliant, fixed-supply token with all safe gas optimizations.
 * @dev No ownership, mint, or burn. Deployer receives the full initial supply at deployment.
 */
contract BitLoTop is IERC20Metadata, ReentrancyGuard {
    // ----- Constants -----
    bytes32 private constant _NAME_BYTES = bytes32("BitLoTop");
    bytes32 private constant _SYMBOL_BYTES = bytes32("BitLoTop");
    uint8 private constant _DECIMALS = 18;
    uint256 private constant _TOTAL_SUPPLY = 1_000_000_000 * 10**18;

    // ----- Storage -----
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    /// @notice Emitted once upon deployment.
    event Deployed(address indexed deployer, uint256 totalSupply);

    /**
     * @notice Mints total supply to deployer and emits deployment event.
     */
    constructor() payable {
        _balances[msg.sender] = _TOTAL_SUPPLY;
        emit Transfer(address(0), msg.sender, _TOTAL_SUPPLY);
        emit Deployed(msg.sender, _TOTAL_SUPPLY);
    }

    // ----- ERC-20 Metadata -----
    function name() external pure override returns (string memory) {
        return string(bytes.concat(_NAME_BYTES));
    }

    function symbol() external pure override returns (string memory) {
        return string(bytes.concat(_SYMBOL_BYTES));
    }

    function decimals() external pure override returns (uint8) {
        return _DECIMALS;
    }

    // ----- ERC-20 Views -----
    function totalSupply() external pure override returns (uint256) {
        return _TOTAL_SUPPLY;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    // ----- Transfers -----
    function transfer(address to, uint256 amount) external override nonReentrant returns (bool) {
        require(to != address(0), "zero");

        uint256 senderBal = _balances[msg.sender];
        require(senderBal > amount - 1, "insuff"); // cheaper strict inequality

        unchecked {
            _balances[msg.sender] = senderBal - amount;
            _balances[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);
        return true;
    }

    // ----- Allowances -----
    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        require(spender != address(0), "zero");

        uint256 current = _allowances[msg.sender][spender];
        if (current != amount) _allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount)
        external
        override
        nonReentrant
        returns (bool)
    {
        require(to != address(0), "zero");

        uint256 allowed = _allowances[from][msg.sender];
        uint256 fromBal = _balances[from];

        require(fromBal > amount - 1, "insuff");
        require(allowed > amount - 1, "allow");

        unchecked {
            _balances[from] = fromBal - amount;
            _balances[to] += amount;
            _allowances[from][msg.sender] = allowed - amount;
        }

        emit Transfer(from, to, amount);
        return true;
    }
}
