// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Globals {
    struct Pair {
        address collateralToken;
        address borrowToken;**
    }

    struct LoanConfig {
        Pair tokenPair;
        uint256 interest; //in percentage, two decimals 1.23% => 123, 12.34% => 1234, 123.45% => 12345
        uint256 duration; // in days
        uint256 liquidationLTV; // in percentage, two decimals 1.23% => 123, 12.34% => 1234, 123.45% => 12345
        bool enabled;
    }

    struct Loan {
        Pair tokenPair;
        uint256 collateralAmount;
        uint256 borrowAmount;
        uint256 ownedAmount;
        uint256 created;
        uint256 deadline;
        bytes32 configId;
        bool paid;
    }

    enum Change {
        REMOVE,
        DISABLE,
        ADD
    }
}
