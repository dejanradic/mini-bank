// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../Globals.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILiquidator {
    function liquidate(
        Globals.Pair memory pair,
        uint256 amount,
        address reciever
    ) external returns (uint256);
}
