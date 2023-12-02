// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library Bytes {
    function countOccurrences(bytes memory data, bytes1 target) internal pure returns (uint256 n) {
        for (uint256 i = 0; i < data.length; i++) {
            if (data[i] == target) {
                n++;
            }
        }
    }

    function countLines(bytes memory data) internal pure returns (uint256 n) {
        return countOccurrences(data, bytes1("\n")) + 1; // Add one for the last line, which does not end with a newline
    }

    function extractBytes(bytes memory data, uint256 start, uint256 end) internal pure returns (bytes memory result) {
        require(start < data.length, "Start index out of bounds");
        require(end <= data.length, "End index out of bounds");
        require(start <= end, "Start index must be less than or equal to end index");

        result = new bytes(end - start);
        for (uint256 i = start; i < end; i++) {
            result[i - start] = data[i];
        }
    }

    function readUntilExclusive(bytes memory data, uint256 start, bytes1 target)
        internal
        pure
        returns (bytes memory result)
    {
        uint256 end = start;
        while (end < data.length && data[end] != target) {
            end++;
        }
        result = extractBytes(data, start, end);
    }

    function readUntilNewlineExclusive(bytes memory data, uint256 start) internal pure returns (bytes memory result) {
        return readUntilExclusive(data, start, bytes1("\n"));
    }
}
