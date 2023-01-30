// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./Utils.sol";
import "./RoleAccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Bank is RoleAccessControl {
    using SafeERC20 for IERC20;

    event TokenChanged(bytes32 key, Globals.Change operation);
    event Deposited(address token, address from, uint amount);
    event Withdrew(address token, address to, uint amount);
    event Transfered(address token, address from, address to, uint amount);

    struct TokenDescription {
        bytes32 key;
        address addr;
        string symbol;
        string name;
    }

    modifier onlyExistingTokens(IERC20Metadata meta) {
        checkTokenAddress(address(meta));
        _;
    }

    mapping(bytes32 => address) public tokens;
    mapping(address => mapping(bytes32 => uint256)) public balances;

    bytes32[] _tokensIndex;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        grantRole(ADMIN_ROLE, msg.sender);
        grantRole(OWNER_ROLE, msg.sender);
    }

    /**
     * @dev Returns balanceOf `addr` for token `meta`.
     */
    function getBalance(IERC20Metadata meta, address addr)
        public
        view
        returns (uint256)
    {
        return balances[addr][Utils.getKey(meta.symbol())];
    }

    /**
     * @dev Deposits `amount` of `meta` token.
     * Emits `Deposited` event.
     */
    function deposit(IERC20Metadata meta, uint256 amount)
        public
        onlyExistingTokens(meta)
    {
        bytes32 key = Utils.getKey(meta.symbol());
        require(
            meta.allowance(msg.sender, address(this)) >= amount,
            "Bank:Insufficient allowance"
        );
        IERC20(address(meta)).safeTransferFrom(msg.sender, address(this), amount);
        balances[msg.sender][key] += amount;
        emit Deposited(address(meta), msg.sender, amount);
    }

    /**
     * @dev Witdraws `amount` of `meta` token.
     * Emits `Withdrew` event.
     */
    function withdraw(IERC20Metadata meta, uint256 amount)
        public
        onlyExistingTokens(meta)
    {
        bytes32 key = Utils.getKey(meta.symbol());
        require(
            balances[msg.sender][key] >= amount,
            "Bank:Insufficient balance"
        );
        IERC20(address(meta)).safeTransfer(msg.sender, amount);
        balances[msg.sender][key] -= amount;
        emit Withdrew(address(meta), msg.sender, amount);
    }


    /**
     * @dev Transfers `amount` of token `meta` from msg.sender to `to` address.
     */
    function transfer(
        IERC20Metadata meta,
        address to,
        uint256 amount
    ) public {
        require(
            getBalance(meta, msg.sender) >= amount,
            "Bank:Insufficient balance"
        );
        _transfer(meta, msg.sender, to, amount);
    }

    /**
     * @dev Transfers `amount` of token `meta` from one account to other.
     */
    function transferBackOffice(
        IERC20Metadata meta,
        address from,
        address to,
        uint256 amount
    ) public onlyOperator {
        _transfer(meta, from, to, amount);
    }

    /**
     * @dev Transfers `amount` of token `meta` from one account to other.
     */
    function _transfer(
        IERC20Metadata meta,
        address from,
        address to,
        uint256 amount
    ) internal onlyExistingTokens(meta) {
        bytes32 key = Utils.getKey(meta.symbol());
        if (from != address(this)) {
            require(
                balances[from][key] >= amount,
                "Bank:Insufficient bank balance"
            );
            balances[from][key] -= amount;
        }
        balances[to][key] += amount;
        emit Transfered(address(meta), from, to, amount);
    }

    /**
     * @dev Adds support for  token `meta`.
     * Emits `TokenChanged` event.
     */
    function addToken(IERC20Metadata meta) public onlyAdmin {
        bytes32 key = Utils.getKey(meta.symbol());
        tokens[key] = address(meta);
        if (!Utils.doesArrayContainValueBytes32(_tokensIndex, key)) {
            _tokensIndex.push(key);
        }
        emit TokenChanged(key, Globals.Change.ADD);
    }

    /**
     * @dev Removes support for  token `meta`.
     * Emits `TokenChanged` event.
     */
    function removeToken(IERC20Metadata meta)
        public
        onlyAdmin
        onlyExistingTokens(meta)
    {
        bytes32 key = Utils.getKey(meta.symbol());
        tokens[key] = address(0);
        Utils.removeFirstFromArrayByValueBytes32Storage(_tokensIndex, key);
        emit TokenChanged(key, Globals.Change.REMOVE);
    }


    /**
     * @dev Check if token `meta` is supported. 
     */
    function checkTokenAddress(address token)
        public
        view
        returns (bool exists)
    {
        exists = tokens[Utils.getKey(IERC20Metadata(token).symbol())] != address(0);
        require(exists, "Bank:Invalid token");
    }

    /**
     * @dev Returns all supported tokens.
     */
    function getSupportedTokens()
        public
        view
        returns (TokenDescription[] memory descriptions)
    {
        descriptions = new TokenDescription[](_tokensIndex.length);
        for (uint256 i = 0; i < descriptions.length; i++) {
            IERC20Metadata meta = IERC20Metadata(tokens[_tokensIndex[i]]);
            descriptions[i] = TokenDescription(
                _tokensIndex[i],
                tokens[_tokensIndex[i]],
                meta.symbol(),
                meta.name()
            );
        }
    }
}
