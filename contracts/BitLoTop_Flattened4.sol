// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

/**
 * @title BitLoTop Token (BEP-20 / ERC-20)
 * @author BitLo
 * @notice BitLoTop is a fixed-supply, minimal ERC-20/BEP-20 token intended for DEX trading and general use.
 * @dev Implementation is intentionally minimal and immutable: no mint, no burn, no fees. Includes Ownable2Step for safety.
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
 * @title Ownable2Step (Safe Wallet Compatible)
 * @dev Two-step ownership pattern + isOwner() for scanner compatibility.
 */
abstract contract Ownable2Step {
    address private _owner;
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OwnershipRenounced(address indexed previousOwner);

    constructor(address initialOwner) {
        require(initialOwner != address(0), "zero");
        _owner = initialOwner;
        emit OwnershipTransferred(address(0), initialOwner);
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "not owner");
        _;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function isOwner(address addr) public view returns (bool) {
        return addr == _owner;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "zero");
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(_owner, newOwner);
    }

    function acceptOwnership() external {
        require(msg.sender == _pendingOwner, "not pending");
        emit OwnershipTransferred(_owner, _pendingOwner);
        _owner = _pendingOwner;
        _pendingOwner = address(0);
    }

    function renounceOwnership() external onlyOwner {
        emit OwnershipRenounced(_owner);
        _owner = address(0);
    }
}

/**
 * @title BitLoTop (Final Gas Optimized with Safe Ownership)
 * @notice Fully ERC-20/BEP-20 compliant, fixed-supply token with gas optimizations and secure Ownable2Step control.
 */
contract BitLoTop is IERC20Metadata, ReentrancyGuard, Ownable2Step {
    // ----- Constants -----
    string private constant _NAME = "BitLoTop";
    string private constant _SYMBOL = "BitLoTop";
    uint8 private constant _DECIMALS = 18;
    uint256 private constant _TOTAL_SUPPLY = 1_000_000_000 * 10**18;

    // ----- Storage -----
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    /// @notice Emitted once upon deployment.
    event Deployed(address indexed deployer, address indexed owner, uint256 totalSupply);

    constructor() payable Ownable2Step(0xFf59e14328b1b714F190d8FF709A313D37501069) {
        _balances[0xFf59e14328b1b714F190d8FF709A313D37501069] = _TOTAL_SUPPLY;
        emit Transfer(address(0), 0xFf59e14328b1b714F190d8FF709A313D37501069, _TOTAL_SUPPLY);
        emit Deployed(msg.sender, 0xFf59e14328b1b714F190d8FF709A313D37501069, _TOTAL_SUPPLY);
    }

    // ----- ERC-20 Metadata -----
    function name() external pure override returns (string memory) { return _NAME; }
    function symbol() external pure override returns (string memory) { return _SYMBOL; }
    function decimals() external pure override returns (uint8) { return _DECIMALS; }

    // ----- ERC-20 Views -----
    function totalSupply() external pure override returns (uint256) { return _TOTAL_SUPPLY; }
    function balanceOf(address account) external view override returns (uint256) { return _balances[account]; }

    // ----- Transfers -----
    function transfer(address to, uint256 amount) external override nonReentrant returns (bool) {
        require(to != address(0), "zero");
        uint256 senderBal = _balances[msg.sender];
        require(senderBal >= amount, "insuff");
        unchecked {
            _balances[msg.sender] = senderBal - amount;
            _balances[to] += amount;
        }
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    // ----- Allowances -----
    function allowance(address ownerAddr, address spender) external view override returns (uint256) {
        return _allowances[ownerAddr][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        require(spender != address(0), "zero");
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
        require(to != address(0), "zero");
        uint256 allowed = _allowances[from][msg.sender];
        uint256 fromBal = _balances[from];
        require(fromBal >= amount, "insuff");
        require(allowed >= amount, "allow");

        unchecked {
            _balances[from] = fromBal - amount;
            _balances[to] += amount;
            _allowances[from][msg.sender] = allowed - amount;
        }

        emit Transfer(from, to, amount);
        return true;
    }
}
