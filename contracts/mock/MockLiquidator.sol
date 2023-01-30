// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../interfaces/ILiquidator.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockLiquidator is ILiquidator {
    mapping(bytes32 => uint256) _ratios;

    function liquidate(
        Globals.Pair memory pair,
        uint256 amount,
        address reciever
    ) public returns (uint256) {
        IERC20(pair.collateralToken).transferFrom(
            msg.sender,
            address(this),
            amount
        );
        IERC20(pair.borrowToken).transfer(reciever, _ratios[_getPairKey(pair)]);
    }

    function setPairRatio(Globals.Pair memory pair, uint256 ratio) public {
        _ratios[_getPairKey(pair)] = ratio;
    }

    function _getPairKey(Globals.Pair memory pair)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(abi.encodePacked(pair.borrowToken, pair.collateralToken));
    }
}
