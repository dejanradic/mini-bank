// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./Globals.sol";

contract RoleAccessControl is AccessControl, Ownable, Pausable {
    event AdminGranted(address addr);
    event AdminRevoked(address addr);
        event BankerGranted(address addr);
    event BankerRevoked(address addr);
        event OperatorGranted(address addr);
    event OperatorRevoked(address addr);

    bytes32 public constant OWNER_ROLE = bytes32(uint256(0x01));
    bytes32 public constant ADMIN_ROLE = bytes32(uint256(0x02));
    bytes32 public constant OPERATOR_ROLE = bytes32(uint256(0x03));

    modifier onlyAdmin() {
        require(
            hasRole(ADMIN_ROLE, msg.sender),
            "RoleAccessControl:Only Admin"
        );
        _;
    }

    modifier onlyOperator() {
        require(
            hasRole(OPERATOR_ROLE, msg.sender),
            "RoleAccessControl:Only Operator"
        );
        _;
    }

    function addAdmin(address addr) public onlyOwner {
        _grantRole(ADMIN_ROLE, addr);
        emit AdminGranted(addr);
    }

    function removeAdmin(address addr) public onlyOwner {
        _revokeRole(ADMIN_ROLE, addr);
        emit AdminRevoked(addr);
    }

    function addOperator(address addr) public onlyAdmin {
        _grantRole(OPERATOR_ROLE, addr);
        emit OperatorGranted(addr);
    }

    function removeOperator(address addr) public onlyAdmin {
        _revokeRole(OPERATOR_ROLE, addr);
        emit OperatorRevoked(addr);
    }
}
