// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library Bytes {
    bytes1 constant ZERO_BYTE = bytes1("0");
    bytes1 constant NINE_BYTE = bytes1("9");

    function isDigit(bytes1 b) internal pure returns (bool) {
        return b >= ZERO_BYTE && b <= NINE_BYTE;
    }
}
