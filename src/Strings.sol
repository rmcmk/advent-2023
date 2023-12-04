// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

struct MatchResult {
    uint256 startIndex;
    uint256 length;
}

library Strings {
    function isMatchValid(MatchResult memory result) internal pure returns (bool) {
        return result.length > 0;
    }

    function findLastOf(string memory str, bytes[] memory substrings) internal pure returns (MatchResult memory last) {
        for (uint256 i = 0; i < substrings.length; i++) {
            MatchResult memory result = findLast(str, bytes(substrings[i]));
            if (isMatchValid(result) && result.startIndex >= last.startIndex) {
                last = result;
            }
        }

        require(isMatchValid(last), string.concat("no last matches found for: ", str));
    }

    function findLast(string memory str, bytes memory targetBytes) internal pure returns (MatchResult memory last) {
        bytes memory strBytes = bytes(str);
        uint256 strLength = strBytes.length;
        uint256 targetLength = targetBytes.length;

        // If the string is < target, there is no match
        if (strLength < targetLength) {
            return last;
        }

        for (int256 i = int256(strLength - targetLength); i >= 0; i--) {
            uint256 start = uint256(i);
            bool found = true;
            for (uint256 j = 0; j < targetLength; j++) {
                if (strBytes[start + j] != targetBytes[j]) {
                    found = false;
                    break;
                }
            }

            if (found) {
                return MatchResult(start, targetLength);
            }
        }

        return last;
    }

    function findFirstOf(string memory str, bytes[] memory substrings)
        internal
        pure
        returns (MatchResult memory first)
    {
        for (uint256 i = 0; i < substrings.length; i++) {
            MatchResult memory result = findFirst(str, bytes(substrings[i]));
            if (isMatchValid(result) && (result.startIndex <= first.startIndex || !isMatchValid(first))) {
                first = result;
            }
        }

        require(isMatchValid(first), string.concat("no first matches found for: ", str));
    }

    function findFirst(string memory str, bytes memory targetBytes) internal pure returns (MatchResult memory first) {
        bytes memory strBytes = bytes(str);
        uint256 strLength = strBytes.length;
        uint256 targetLength = targetBytes.length;

        // If the string is shorter than the target, match impossible
        if (strLength < targetLength) {
            return first;
        }

        for (uint256 i = 0; i <= strLength - targetLength; i++) {
            bool found = true;
            for (uint256 j = 0; j < targetLength; j++) {
                if (strBytes[i + j] != targetBytes[j]) {
                    found = false;
                    break;
                }
            }

            if (found) {
                return MatchResult(i, targetLength);
            }
        }
    }
}
