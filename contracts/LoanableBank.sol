// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Bank.sol";
import "./Globals.sol";
import "./interfaces/IOracle.sol";
import "./interfaces/ILiquidator.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LoanableBank is Bank {


    event PairChanged(bytes32 configKey, Globals.Change operation);
    event ConfigChanged(bytes32 configKey, Globals.Change operation);
    event LoanCreated(address holder, bytes32 configKey, uint ownedAmount, uint deadline);
    event LoanPaid(address holder, uint paidAmount, bool fullPayment);
    event LoanLiquidated(address holder);


    mapping(bytes32 => bool) _enabledPairs;
    mapping(bytes32 => Globals.Pair) _pairs;
    bytes32[] _pairsIndex;
    mapping(bytes32 => uint256) _ltvs;
    uint256 _ltvUpdateTimestamp;
    uint256 _enabledPairsCount;

    mapping(bytes32 => Globals.LoanConfig) public loanConfigs;
    bytes32[] _loanConfigsIndex;

    mapping(address => Globals.Loan) _loans;
    address[] _loanHolders;

    IOracle public oracle;
    ILiquidator public liquidator;

    /**
     * @dev The contract constructor needs an addresses for `oracle_` used to determine borrow and collateral asset ratio,
     * and `liquidator_` used for liquidation of collateral asset.
     *
     */
    constructor(IOracle oracle_, ILiquidator liquidator_) Bank() {
        oracle = oracle_;
        liquidator = liquidator_;
    }

    /**
     * @dev Adds new collateral to borrow asset `pair`
     * Emits `PairChanged` event.
     */

    function addPair(Globals.Pair memory pair) public onlyAdmin {
        require(
            checkTokenAddress(pair.collateralToken) &&
                checkTokenAddress(pair.borrowToken)
        );
        bytes32 key = getPairKey(pair);
        _enabledPairs[key] = true;
        if (!Utils.doesArrayContainValueBytes32(_pairsIndex, key)) {
            _pairs[key] = pair;
            _pairsIndex.push(key);
            _enabledPairsCount += 1;
        }
    }

    
    /**
     * @dev Removes existing collateral to borrow asset `pair`
     * Emits `PairChanged` event.
     */
    function removePair(Globals.Pair memory pair) public onlyAdmin {
        bytes32 key = getPairKey(pair);
        _enabledPairs[key] = false;
        _enabledPairsCount -= 1;
        delete _pairs[key];
        Utils.removeFirstFromArrayByValueBytes32Storage(_pairsIndex, key);
    }

    
    /**
     * @dev Temporaly disables existing collateral to borrow asset `pair`
     * Emits `PairChanged` event.
     */
    function disablePair(Globals.Pair memory pair) public onlyAdmin {
        bytes32 key = getPairKey(pair);
        _enabledPairs[key] = false;
        _enabledPairsCount -= 1;
    }


    /**
     * @dev Adds new loan configuration `config`
     * Emits `ConfigChanged` event.
     */
    function addLoanConfig(Globals.LoanConfig memory config) public onlyAdmin {
        require(
            checkTokenAddress(config.tokenPair.collateralToken) &&
                checkTokenAddress(config.tokenPair.borrowToken)
        );
        bytes32 key = getLoanConfigKey(config);
        loanConfigs[key] = config;
        if (!Utils.doesArrayContainValueBytes32(_loanConfigsIndex, key)) {
            _loanConfigsIndex.push(key);
        }
    }
    
    /**
     * @dev Removes existing load configuration `config`
     * Emits `ConfigChanged` event.
     */
    function removeLoanConfig(Globals.LoanConfig memory config)
        public
        onlyAdmin
    {
        bytes32 key = getLoanConfigKey(config);
        delete loanConfigs[key];
        Utils.removeFirstFromArrayByValueBytes32Storage(_loanConfigsIndex, key);
    }
    
    /**
     * @dev Disables existing load configuration `config`
     */
    function disableLoanConfig(Globals.LoanConfig memory config)
        public
        onlyAdmin
    {
        bytes32 key = getLoanConfigKey(config);
        loanConfigs[key].enabled = false;
    }
    
    /**
     * @dev Creates `Globals.Loan`. User locks `amount` of  collateral token  
     * in exchange for borrow token. Loan can be liquidated after `duration
     * period of time, or if LTV (Loan To Value) ration surpasses `liquidationLTV` from `config`.
     * Emits `LoanCreated` event.  
     */
    function requestLoan(
        Globals.Pair memory tokenPair,
        uint256 interest,
        uint256 duration,
        uint256 amount
    ) public {
        require(
            !Utils.doesArrayContainValueAddress(_loanHolders, msg.sender),
            "LoananbleBank: You have unpaid loan"
        );
        (
            Globals.Loan memory loan,
            Globals.LoanConfig memory config
        ) = getLoanPreview(tokenPair, interest, duration, amount);
        require(config.enabled, "LoanableBank: Invalid loan configuration");
        uint256 initLTV = oracle.getPairRatio(tokenPair);
        require(initLTV < config.liquidationLTV, "LoanableBank: LTV");
        _ltvs[getPairKey(tokenPair)] = initLTV;
        transfer(
            IERC20Metadata(tokenPair.collateralToken),
            address(this),
            amount
        );
        _transfer(
            IERC20Metadata(tokenPair.borrowToken),
            address(this),
            msg.sender,
            amount
        );
        _loans[msg.sender] = loan;
        _loanHolders.push(msg.sender);
        emit LoanCreated(msg.sender,loan.configId,loan.ownedAmount,loan.deadline);
    }

    /**
     * @dev View function that can be used to get preview of `Globals.Loan` before requesting it.
     */
    function getLoanPreview(
        Globals.Pair memory tokenPair,
        uint256 interest,
        uint256 duration,
        uint256 amount
    )
        public
        view
        returns (Globals.Loan memory loan, Globals.LoanConfig memory config)
    {
        bytes32 key = getLoanConfigId(tokenPair, interest, duration);
        config = loanConfigs[key];
        require(config.enabled, "LoanableBank: Invalid loan configuration");
        uint256 ratio = oracle.getPairRatio(tokenPair);
        uint256 borrowAmount = _getBorrowAmount(amount, ratio);
        loan = Globals.Loan(
            tokenPair,
            amount,
            borrowAmount,
            _addInterest(borrowAmount, config.interest, config.duration),
            block.timestamp,
            Utils.addDuration(block.timestamp, config.duration),
            key,
            false
        );
    }

    /**
     * @dev View function that returns all active loans
     */
    function getAllLoans()
        public
        view
        returns (Globals.Loan[] memory, address[] memory)
    {
        Globals.Loan[] memory loans = new Globals.Loan[](_loanHolders.length);
        for (uint256 i = 0; i < _loanHolders.length; i++) {
            loans[i] = _loans[_loanHolders[i]];
        }
        return (loans, _loanHolders);
    }

    /**
     * @dev Enables user to pay partial or full `amount` of `Globals.Loan`.
     * If loan is paid in full, collateral is transfered to the `holder`.
     * Emits `LoanPaid` event. 
     */
    function payLoan(address holder, uint256 amount)
        public
        returns (Globals.Loan memory)
    {
        require(
            Utils.doesArrayContainValueAddress(_loanHolders, holder),
            "LoananbleBanke: Can't find loan"
        );
        Globals.Loan memory loan = _loans[holder];
        if (_checkLiquidationConditions(loan)) {
            return _liquidateLoan(loan, holder);
        }
        bool paid = loan.ownedAmount <= amount;
        uint256 transferAmount = paid ? loan.ownedAmount : amount;
        transfer(
            IERC20Metadata(loan.tokenPair.borrowToken),
            address(this),
            transferAmount
        );
        loan.ownedAmount = paid ? 0 : loan.ownedAmount - amount;
        loan.paid = paid;
        if (paid) {
            transfer(
                IERC20Metadata(loan.tokenPair.collateralToken),
                holder,
                loan.collateralAmount
            );
            _removeLoan(holder);
        } else {
            _loans[holder] = loan;
        }
        emit LoanPaid(holder,amount,paid);
        return loan;
    }

    /**
     * @dev Internal uitility function using to remove `holder` and its loan.
     */
    function _removeLoan(address holder) internal {
        Utils.removeFirstFromArrayByValueAddressStorage(_loanHolders, holder);
        delete _loans[holder];
    }

    /**
     * @dev View function that returns LTV ratios for `pairs`.
     */
    function getLTVs(Globals.Pair[] memory pairs)
        public
        view
        returns (uint256[] memory ltvs)
    {
        ltvs = new uint256[](pairs.length);
        for (uint256 i = 0; i < ltvs.length; i++) {
            ltvs[i] = oracle.getPairRatio(pairs[i]);
        }
        return ltvs;
    }

    /**
     * @dev Starts process of loan liquidation.
     */
    function liquidateLoan(address holder) public onlyOperator {
        Globals.Loan memory loan = _loans[holder];
        _liquidateLoan(loan, holder);
    }

    /**
     * @dev If liquidation conditions are met, it liquidates `loan`. 
     * Collateral tokens are exchanged for borrow tokens. 
     * Emits `LoanLiquidated` event. 
     */
    function _liquidateLoan(Globals.Loan memory loan, address holder)
        internal
        returns (Globals.Loan memory)
    {
        require(
            _checkLiquidationConditions(loan),
            "LoanableBank: Can't liquidate"
        );
        IERC20(loan.tokenPair.collateralToken).approve(
            address(liquidator),
            loan.collateralAmount
        );
        liquidator.liquidate(
            loan.tokenPair,
            loan.collateralAmount,
            address(this)
        );
        _removeLoan(holder);
        emit LoanLiquidated(holder);
        return loan;
    }

    /**
     * @dev Checks liquidation conditions for `loan`
     */
    function _checkLiquidationConditions(Globals.Loan memory loan)
        internal
        view
        returns (bool)
    {
        uint256 ltv = oracle.getPairRatio(loan.tokenPair);
        if (loanConfigs[loan.configId].liquidationLTV <= ltv) {
            return true;
        }
        if (block.timestamp > loan.deadline) {
            return true;
        }

        return false;
    }

    /**
     * @dev Updates LTV ratios for, all loans. Precedes to liquidation if conditions are met.
     */
    function updateLoans() public onlyOperator {
        (Globals.Pair[] memory pairs, bytes32[] memory keys) = getAllPairs(
            true
        );
        uint256[] memory ltvs = getLTVs(pairs);
        for (uint256 i = 0; i < keys.length; i++) {
            if (_ltvs[keys[i]] != ltvs[i]) {
                _ltvs[keys[i]] = ltvs[i];
                //TODO LTV event
            }
        }
        _ltvUpdateTimestamp = block.timestamp;
        for (uint256 i = 0; i < _loanHolders.length; i++) {
            Globals.Loan memory loan = _loans[_loanHolders[i]];
            if (_checkLiquidationConditions(loan)) {
                _liquidateLoan(loan, _loanHolders[i]);
            }
        }
    }

    /**
     * @dev Returns all pairs or all enabled pairs, depending on `onlyEnabled` value.
     */
    function getAllPairs(bool onlyEnabled)
        public
        view
        returns (Globals.Pair[] memory, bytes32[] memory)
    {
        uint256 count = onlyEnabled ? _enabledPairsCount : _pairsIndex.length;
        Globals.Pair[] memory pairs = new Globals.Pair[](count);
        bytes32[] memory keys = onlyEnabled
            ? new bytes32[](count)
            : new bytes32[](0);
        uint256 j = 0;
        for (uint256 i = 0; i < _pairsIndex.length; i++) {
            if (onlyEnabled) {
                if (_enabledPairs[_pairsIndex[i]]) {
                    pairs[j] = _pairs[_pairsIndex[i]];
                    keys[j] = _pairsIndex[i];
                    j++;
                }
            } else {
                pairs[i] = _pairs[_pairsIndex[i]];
            }
        }
        if (onlyEnabled) {
            return (pairs, keys);
        } else {
            return (pairs, _pairsIndex);
        }
    }

    /**
     * @dev Returns unique key for `pair`.
     */
    function getPairKey(Globals.Pair memory pair)
        public
        pure
        virtual
        returns (bytes32)
    {
        return
            keccak256(abi.encodePacked(pair.borrowToken, pair.collateralToken));
    }

    /**
     * @dev Returns unique key for `config`.
     */
    function getLoanConfigKey(Globals.LoanConfig memory config)
        public
        pure
        virtual
        returns (bytes32)
    {
        return
            getLoanConfigId(config.tokenPair, config.interest, config.duration);
    }

    /**
     * @dev Returns unique key for config.
     */
    function getLoanConfigId(
        Globals.Pair memory pair,
        uint256 interest,
        uint256 duration
    ) public pure virtual returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    pair.borrowToken,
                    pair.collateralToken,
                    interest,
                    duration
                )
            );
    }

    /**
     * @dev Calculates amount of borrow tokens.
     */
    function _getBorrowAmount(uint256 amount, uint256 ltv)
        internal
        pure
        returns (uint256)
    {
        //TODO:fix
        return (((amount * 1000) / ltv) * 1000) / 1000;
    }

    /**
     * @dev Adds interest.
     */
    function _addInterest(
        uint256 amount,
        uint256 interest,
        uint256 duration
    ) internal pure returns (uint256) {
        return
            (amount * (100000 + (1000 * interest * duration) / 36525)) / 100000;
    }

}
