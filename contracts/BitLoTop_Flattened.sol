// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

/**
 * @title BitLoTop Token (BEP-20 / ERC-20)
 * @author BitLo
 * @notice BitLoTop is a fixed-supply, minimal ERC-20/BEP-20 token intended for DEX trading and general use.
 * @dev Implementation is intentionally minimal and immutable: no owner/admin, no mint, no burn, no fees.
 *
 * Token details:
 *  - Name: BitLoTop
 *  - Symbol: BitLoTop
 *  - Decimals: 18
 *  - Total supply: 1,000,000,000 * 1e18
 */

/* ------------------------------------------------------------------
   IERC20
   Standard ERC-20 interface
   ------------------------------------------------------------------ */
/**
 * @title IERC20
 * @author BitLo
 * @dev Standard ERC-20 interface declarations.
 */
interface IERC20 {
    /// @notice Returns the amount of tokens in existence.
    function totalSupply() external view returns (uint256);

    /// @notice Returns the token balance of `account`.
    function balanceOf(address account) external view returns (uint256);

    /// @notice Moves `amount` tokens from the caller's account to `to`.
    function transfer(address to, uint256 amount) external returns (bool);

    /// @notice Returns remaining number of tokens spender is allowed to spend on behalf of owner.
    function allowance(address owner, address spender) external view returns (uint256);

    /// @notice Sets `amount` as the allowance of `spender` over the caller's tokens.
    function approve(address spender, uint256 amount) external returns (bool);

    /// @notice Moves `amount` tokens from `from` to `to` using allowance mechanism.
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    /// @notice Emitted when `value` tokens are moved from one account (`from`) to another (`to`).
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @notice Emitted when the allowance of a `spender` for an `owner` is set by a call to `approve`.
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/* ------------------------------------------------------------------
   IERC20Metadata
   Optional metadata functions from EIP-20
   ------------------------------------------------------------------ */
/**
 * @title IERC20Metadata
 * @author BitLo
 * @dev ERC-20 metadata extension.
 */
interface IERC20Metadata is IERC20 {
    /// @notice Returns the name of the token.
    function name() external view returns (string memory);

    /// @notice Returns the symbol of the token.
    function symbol() external view returns (string memory);

    /// @notice Returns the decimals places of the token.
    function decimals() external view returns (uint8);
}

/* ------------------------------------------------------------------
   ReentrancyGuard (lightweight, documented)
   ------------------------------------------------------------------ */
/**
 * @title ReentrancyGuard
 * @author BitLo
 * @dev Simple reentrancy guard — use `nonReentrant` on external functions
 *      that modify state and can be called in complex flows.
 */
abstract contract ReentrancyGuard {
    /// @dev Not entered state
    uint256 private constant _NOT_ENTERED = 1;
    /// @dev Entered state
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    /// @notice Initializes the guard to non-entered.
    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @notice Prevent a function from being reentrant.
     * @dev Reverts with "reentrant" on reentrancy attempt.
     */
    modifier nonReentrant() {
        require(_status == _NOT_ENTERED, "reentrant");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

/* ------------------------------------------------------------------
   BitLoTop (vAll-In Final)
   ------------------------------------------------------------------ */
/**
 * @title BitLoTop
 * @author BitLo
 * @notice Minimal, immutable ERC-20 / BEP-20 token for trading and general use.
 * @dev No owner or privileged roles. All supply minted to deployer at construction.
 */
contract BitLoTop is IERC20Metadata, ReentrancyGuard {
    // ----- Token constants -----
    /// @dev token name stored as bytes32 to optimize gas (fits within 32 bytes).
    bytes32 private constant _NAME_B32 = "BitLoTop";
    /// @dev token symbol stored as bytes32.
    bytes32 private constant _SYMBOL_B32 = "BitLoTop";
    /// @dev decimals (18)
    uint8 private constant _DECIMALS = 18;
    /// @dev total supply: 1,000,000,000 * 1e18 (uses scientific notation for clarity)
    uint256 private constant _TOTAL_SUPPLY = 1_000_000_000 * 1e18;

    // ----- Storage (named mapping parameters for clarity) -----
    mapping(address account => uint256) private _balances;
    mapping(address owner => mapping(address spender => uint256)) private _allowances;

    /// @notice Emitted once when the contract is deployed.
    event Deployed(address indexed deployer, uint256 totalSupply);

    /**
     * @notice Deploy the token and mint full supply to the deployer (msg.sender).
     * @dev Emits Transfer(address(0), deployer, totalSupply) and Deployed event.
     */
    constructor() {
        _balances[msg.sender] = _TOTAL_SUPPLY;
        emit Transfer(address(0), msg.sender, _TOTAL_SUPPLY);
        emit Deployed(msg.sender, _TOTAL_SUPPLY);
    }

    // -------------------------
    // Metadata functions
    // -------------------------

    /// @inheritdoc IERC20Metadata
    function name() external pure override returns (string memory) {
        // convert bytes32 constant to string via abi.encodePacked (gas acceptable for view)
        return string(abi.encodePacked(_NAME_B32));
    }

    /// @inheritdoc IERC20Metadata
    function symbol() external pure override returns (string memory) {
        return string(abi.encodePacked(_SYMBOL_B32));
    }

    /// @inheritdoc IERC20Metadata
    function decimals() external pure override returns (uint8) {
        return _DECIMALS;
    }

    // -------------------------
    // View functions
    // -------------------------

    /// @inheritdoc IERC20
    function totalSupply() external pure override returns (uint256) {
        return _TOTAL_SUPPLY;
    }

    /// @inheritdoc IERC20
    /// @param account Address to query balance of.
    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    // -------------------------
    // Transfer functions
    // -------------------------

    /**
     * @notice Transfer tokens from caller to `to`.
     * @dev Prevents sending to zero address and uses cached balance to save gas.
     * @param to Recipient address (non-zero).
     * @param amount Amount to transfer.
     * @return success True on success.
     */
    function transfer(address to, uint256 amount) external override nonReentrant returns (bool) {
        require(to != address(0), "zero"); // short message to save gas
        uint256 senderBal = _balances[msg.sender];
        // use strict cheaper check equivalent to >=
        require(senderBal > amount - 1, "insuff");
        unchecked {
            _balances[msg.sender] = senderBal - amount;
            _balances[to] += amount;
        }
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    /**
     * @inheritdoc IERC20
     * @param owner Owner address in allowance lookup.
     * @param spender Spender address in allowance lookup.
     */
    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @notice Approve `spender` to spend `amount` on caller's behalf.
     * @dev Avoid redundant SSTORE when the value is unchanged to save gas.
     * @param spender Spender address (non-zero).
     * @param amount Amount to approve.
     * @return success True on success.
     */
    function approve(address spender, uint256 amount) external override returns (bool) {
        require(spender != address(0), "zero");
        // only write if the value changes (avoids costly SSTORE when unchanged)
        if (_allowances[msg.sender][spender] != amount) {
            _allowances[msg.sender][spender] = amount;
        }
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /**
     * @notice Transfer `amount` tokens from `from` to `to` using allowance.
     * @dev Checks allowance and balances; updates storage minimally.
     * @param from Source address (must have balance).
     * @param to Recipient address (non-zero).
     * @param amount Amount to transfer.
     * @return success True on success.
     */
    function transferFrom(address from, address to, uint256 amount)
        external
        override
        nonReentrant
        returns (bool)
    {
        require(to != address(0), "zero");

        // cache reads
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
