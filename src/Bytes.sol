// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library Bytes {
    bytes1 constant ZERO_BYTE = bytes1("0");
    bytes1 constant NINE_BYTE = bytes1("9");

    bytes1 constant SPACE = bytes1(" ");
    bytes1 constant TAB = bytes1("\t");
    bytes1 constant LF = bytes1("\n");
    bytes1 constant FF = 0x0A; // bytes1("\f") complier complaining invalid escape?
    bytes1 constant CR = bytes1("\r");

    /// @notice Checks if the specified `b` is a whitespace character.
    /// @dev Whitespace characters are defined as: space (0x20), horizontal tab (0x09), line feed (0x0A), form feed (0x0C), and carriage return (0x0D).
    /// @param b The byte to check.
    /// @return `true` iff the byte is a whitespace character, false otherwise.
    function isWhitespace(bytes1 b) internal pure returns (bool) {
        return b == SPACE || b == TAB || b == LF || b == FF || b == CR;
    }

    function isDigit(bytes1 b) internal pure returns (bool) {
        return b >= ZERO_BYTE && b <= NINE_BYTE;
    }
}
