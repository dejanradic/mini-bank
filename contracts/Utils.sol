// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

library Utils {
    function getKey(string memory s) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(s));
    }

    function getFirstIndexByValueBytes32(bytes32[] memory array, bytes32 value)
        public
        pure
        returns (uint256)
    {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == value) {
                return i;
            }
        }
        return array.length;
    }

    function removeFirstFromArrayByValueBytes32(
        bytes32[] memory array,
        bytes32 value
    ) public pure returns (bytes32[] memory) {
        uint256 index = getFirstIndexByValueBytes32(array, value);
        bytes32 tmp = array[array.length - 1];
        array[array.length - 1] = array[index];
        array[index] = tmp;
        bytes32[] memory newArray = new bytes32[](array.length - 1);
        for (uint256 i = 0; i < newArray.length; i++) {
            newArray[i] = array[i];
        }
        return newArray;
    }

    function removeFirstFromArrayByValueBytes32Storage(
        bytes32[] storage array,
        bytes32 value
    ) public returns (bytes32[] storage) {
        uint256 index = getFirstIndexByValueBytes32(array, value);
        array[index] = array[array.length - 1];
        array.pop();
        return array;
    }

    function doesArrayContainValueBytes32(
        bytes32[] calldata array,
        bytes32 value
    ) public pure returns (bool) {
        return getFirstIndexByValueBytes32(array, value) != array.length;
    }

    function getFirstIndexByValueAddress(address[] memory array, address value)
        public
        pure
        returns (uint256)
    {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == value) {
                return i;
            }
        }
        return array.length;
    }

    function removeFirstFromArrayByValueAddressStorage(
        address[] storage array,
        address value
    ) public returns (address[] storage) {
        uint256 index = getFirstIndexByValueAddress(array, value);
        array[index] = array[array.length - 1];
        array.pop();
        return array;
    }

    function doesArrayContainValueAddress(
        address[] calldata array,
        address value
    ) public pure returns (bool) {
        return getFirstIndexByValueAddress(array, value) != array.length;
    }

    function addDuration(uint256 timestamp, uint256 duration)
        public
        pure
        returns (uint256)
    {
        return timestamp + duration * 1 days;
    }
}
