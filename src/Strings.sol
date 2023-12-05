// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library Strings {
    function equals(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}
