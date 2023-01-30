// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockToken is ERC20 {
    constructor(string memory name_, string memory symbol_)
        ERC20(name_, symbol_)
    {}

    function setBalance(address to, uint256 value) public {
        uint256 current = balanceOf(to);
        _burn(to, current);
        _mint(to, value);
    }
}
