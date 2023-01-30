// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../interfaces/IOracle.sol";

contract MockOracle is IOracle {
    mapping(bytes32 => uint256) _ratios;

    function getPairRatio(Globals.Pair memory pair)
        public
        view
        override
        returns (uint256)
    {
        return _ratios[_getPairKey(pair)];
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
