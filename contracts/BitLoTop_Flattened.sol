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
 *  - Total supply: 1,000,000,000 * 10^18
 */

/* ------------------------------------------------------------------
   IERC20
   Standard ERC-20 interface
   ------------------------------------------------------------------ */
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
   BitLoTop (vAll-In) flattened contract
   ------------------------------------------------------------------ */
/**
 * @title BitLoTop
 * @author BitLo
 * @notice Minimal, immutable ERC-20 / BEP-20 token for trading and general use.
 * @dev No owner or privileged roles. All supply minted to deployer at construction.
 */
contract BitLoTop is IERC20Metadata, ReentrancyGuard {
    // ----- Token constants -----
    string private constant _NAME = "BitLoTop";
    string private constant _SYMBOL = "BitLoTop";
    uint8 private constant _DECIMALS = 18;
    // Using explicit constant for total supply for clarity
    uint256 private constant _TOTAL_SUPPLY = 1_000_000_000 * 10**18;

    // ----- Storage -----
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

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

    // ----- ERC-20 Metadata -----
    /// @inheritdoc IERC20Metadata
    function name() external pure override returns (string memory) { return _NAME; }

    /// @inheritdoc IERC20Metadata
    function symbol() external pure override returns (string memory) { return _SYMBOL; }

    /// @inheritdoc IERC20Metadata
    function decimals() external pure override returns (uint8) { return _DECIMALS; }

    // ----- ERC-20 Views -----
    /// @inheritdoc IERC20
    function totalSupply() external pure override returns (uint256) { return _TOTAL_SUPPLY; }

    /// @inheritdoc IERC20
    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    // ----- ERC-20 Transfer -----
    /**
     * @notice Transfer tokens from caller to `to`.
     * @dev Prevents sending to zero address and uses cached balance to save gas.
     * @param to Recipient address (non-zero).
     * @param amount Amount to transfer.
     * @return True on success.
     */
    function transfer(address to, uint256 amount) external override nonReentrant returns (bool) {
        require(to != address(0), "zero");
        uint256 senderBal = _balances[msg.sender];
        require(senderBal > amount - 1, "insuff"); // cheaper strict check equivalent to >=
        unchecked {
            _balances[msg.sender] = senderBal - amount;
            _balances[to] += amount;
        }
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    // ----- Allowance / Approve -----
    /// @inheritdoc IERC20
    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @notice Approve `spender` to spend `amount` on caller's behalf.
     * @dev Avoid redundant SSTORE when the value is unchanged to save gas.
     * @param spender Spender address (non-zero).
     * @param amount Amount to approve.
     * @return True on success.
     */
    function approve(address spender, uint256 amount) external override returns (bool) {
        require(spender != address(0), "zero");
        // only write if the value changes (avoids Gsreset if same)
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
     * @return True on success.
     */
    function transferFrom(address from, address to, uint256 amount)
        external
        override
        nonReentrant
        returns (bool)
    {
        require(to != address(0), "zero");

        uint256 allowed = _allowances[from][msg.sender];
        uint256 fromBal = _balances[from];

        require(fromBal > amount - 1, "insuff"); // same efficient >= replacement
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
