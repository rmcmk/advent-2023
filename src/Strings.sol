// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

struct MatchResult {
    uint256 startIndex;
    uint256 length;
    bool valid;
}

// this is all horribly inefficient but i dont care, im exhausted, stupid puzzle kicked my ass lmfao
library Strings {
    function findLastOf(string memory str, bytes[] memory substrings) internal pure returns (MatchResult memory last) {
        for (uint256 i = substrings.length; i > 0; i--) {
            bytes memory substringBytes = bytes(substrings[i - 1]);
            MatchResult memory result = findLast(str, substringBytes);
            if (result.valid && (result.startIndex >= last.startIndex || !last.valid)) {
                last = result;
            }
        }

        require(last.valid, string.concat("no last matches found for: ", str));
    }

    function findLast(string memory str, bytes memory targetBytes) internal pure returns (MatchResult memory last) {
        bytes memory strBytes = bytes(str);

        // If the string is < target, there is no match
        if (strBytes.length < targetBytes.length) {
            return last;
        }

        for (uint256 i = 0; i <= strBytes.length - targetBytes.length; i++) {
            bool isMatch = true;
            for (uint256 j = 0; j < targetBytes.length; j++) {
                if (strBytes[i + j] != targetBytes[j]) {
                    isMatch = false;
                    break;
                }
            }

            // If we have a match and the current index is >= the first match index OR we don't have a valid match yet, update the first match
            if (isMatch && (i >= last.startIndex || !last.valid)) {
                last = MatchResult(i, targetBytes.length, true);
            }
        }
    }

    function findFirstOf(string memory str, bytes[] memory substrings)
        internal
        pure
        returns (MatchResult memory first)
    {
        for (uint256 i = 0; i < substrings.length; i++) {
            bytes memory substringBytes = bytes(substrings[i]);
            MatchResult memory result = findFirst(str, substringBytes);
            if (result.valid && (result.startIndex <= first.startIndex || !first.valid)) {
                first = result;
            }
        }

        require(first.valid, string.concat("no first matches found for: ", str));
    }

    function findFirst(string memory str, bytes memory targetBytes) internal pure returns (MatchResult memory first) {
        bytes memory strBytes = bytes(str);

        // If the string is < target, there is no match
        if (strBytes.length < targetBytes.length) {
            return first;
        }

        for (uint256 i = 0; i <= strBytes.length - targetBytes.length; i++) {
            bool isMatch = true;
            for (uint256 j = 0; j < targetBytes.length; j++) {
                if (strBytes[i + j] != targetBytes[j]) {
                    isMatch = false;
                    break;
                }
            }

            // If we have a match and the current index is <= the first match index OR we don't have a valid match yet, update the first match
            if (isMatch && (i <= first.startIndex || !first.valid)) {
                first = MatchResult(i, targetBytes.length, true);
            }
        }
    }
}
