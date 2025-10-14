// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

/**
 * @title BitLoTop Token (BEP-20 / ERC-20)
 * @author BitLo
 * @notice Fixed-supply BEP-20 token intended for DEX trading and general use.
 * @dev No owner, no mint, no burn, no fees. Supply minted once at deployment.
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
/**
 * @dev Simple reentrancy guard. Use `nonReentrant` on functions that modify state
 *      and might be used in complex external flows.
 */
abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    /// @dev Initialize guard to not entered.
    constructor() {
        _status = _NOT_ENTERED;
    }

    /// @notice Prevents reentrant calls to a function.
    modifier nonReentrant() {
        require(_status == _NOT_ENTERED, "reentrant");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

// --------------------------------------------------
// BitLoTop Token Implementation (vFinal-Plus)
// --------------------------------------------------
/**
 * @title BitLoTop
 * @author BitLo
 * @notice BitLoTop is a simple, fixed-supply ERC-20 / BEP-20 token.
 * @dev Implementation is intentionally minimal and immutable: no owner/admin, no mint/burn.
 */
contract BitLoTop is IERC20Metadata, ReentrancyGuard {
    // ----- Token constants -----
    string private constant _NAME = "BitLoTop";
    string private constant _SYMBOL = "BitLoTop";
    uint8 private constant _DECIMALS = 18;
    uint256 private constant _TOTAL_SUPPLY = 1_000_000_000 * 10**18;

    // ----- Storage -----
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    /// @notice Emitted when the contract is deployed.
    event Deployed(address indexed deployer, uint256 totalSupply);

    /**
     * @notice Construct the token and mint the full supply to deployer.
     * @dev Emits Transfer(address(0), deployer, totalSupply) and Deployed event.
     */
    constructor() {
        _balances[msg.sender] = _TOTAL_SUPPLY;
        emit Transfer(address(0), msg.sender, _TOTAL_SUPPLY);
        emit Deployed(msg.sender, _TOTAL_SUPPLY);
    }

    // ----- ERC-20 Metadata -----
    /// @notice Token name.
    function name() external pure override returns (string memory) { return _NAME; }

    /// @notice Token symbol.
    function symbol() external pure override returns (string memory) { return _SYMBOL; }

    /// @notice Token decimals.
    function decimals() external pure override returns (uint8) { return _DECIMALS; }

    // ----- ERC-20 Views -----
    /// @notice Total token supply.
    /// @return total supply in smallest units.
    function totalSupply() external pure override returns (uint256) { return _TOTAL_SUPPLY; }

    /// @notice Get balance of `account`.
    /// @param account Address to query.
    /// @return token balance.
    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    // ----- ERC-20 Transfers -----
    /**
     * @notice Transfer `amount` tokens to `to`.
     * @dev Sender must have at least `amount`. Prevents sending to zero address.
     * @param to Recipient address.
     * @param amount Amount to transfer.
     * @return success True if transfer succeeded.
     */
    function transfer(address to, uint256 amount) external override nonReentrant returns (bool) {
        require(to != address(0), "zero addr");
        uint256 senderBal = _balances[msg.sender];
        require(senderBal >= amount, "insufficient");
        unchecked {
            _balances[msg.sender] = senderBal - amount;
            _balances[to] += amount;
        }
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    // ----- Allowance / Approve -----
    /// @notice Returns remaining allowance `spender` has from `owner`.
    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @notice Approve `spender` to spend `amount` on caller's behalf.
     * @dev Avoids re-writing storage if value is unchanged to save gas.
     * @param spender Spender address.
     * @param amount Amount approved.
     * @return success True if approval succeeded.
     */
    function approve(address spender, uint256 amount) external override returns (bool) {
        require(spender != address(0), "zero addr");
        // Avoid redundant SSTORE when value unchanged
        if (_allowances[msg.sender][spender] != amount) {
            _allowances[msg.sender][spender] = amount;
        }
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /**
     * @notice Transfer `amount` tokens from `from` to `to` using allowance.
     * @dev `from` must have approved caller for at least `amount`.
     * @param from Source address.
     * @param to Recipient address.
     * @param amount Amount to transfer.
     * @return success True if transfer succeeded.
     */
    function transferFrom(address from, address to, uint256 amount)
        external
        override
        nonReentrant
        returns (bool)
    {
        require(to != address(0), "zero addr");

        uint256 allowed = _allowances[from][msg.sender];
        uint256 fromBal = _balances[from];

        require(fromBal >= amount, "insufficient");
        require(allowed >= amount, "allowance");

        unchecked {
            _balances[from] = fromBal - amount;
            _balances[to] += amount;
            _allowances[from][msg.sender] = allowed - amount;
        }

        emit Transfer(from, to, amount);
        return true;
    }
}
