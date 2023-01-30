// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../Globals.sol";

interface IOracle {
    function getPairRatio(Globals.Pair memory) external view returns (uint256);
}
