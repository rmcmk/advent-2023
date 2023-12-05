// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { MatchResults, MatchResult } from "./MatchResult.sol";

struct Source {
    bytes data;
    uint256 cursor;
}

library Sources {
    using MatchResults for MatchResult;
    using Sources for Source;

    bytes1 constant NEWLINE = bytes1("\n");
    bytes1 constant BYTES1_EMPTY = bytes1("");
    bytes constant EMPTY = bytes("");

    function from(bytes memory data) internal pure returns (Source memory) {
        return from(data, 0);
    }

    function from(bytes memory data, uint256 cursor) internal pure returns (Source memory) {
        require(cursor < data.length, "Cursor out of bounds");
        return Source({ data: data, cursor: cursor });
    }

    function fromString(string memory str) internal pure returns (Source memory) {
        return fromString(str, 0);
    }

    function fromString(string memory str, uint256 cursor) internal pure returns (Source memory) {
        return from(bytes(str), cursor);
    }

    function slice(Source memory source, uint256 start, uint256 end) internal pure returns (Source memory) {
        require(start < end, "Invalid slice bounds");
        require(end <= source.data.length, "Invalid slice bounds");
        bytes memory data = new bytes(end - start);
        for (uint256 i = start; i < end; i++) {
            data[i - start] = source.data[i];
        }
        return from(data);
    }

    function readByte(Source memory source) internal pure returns (bytes1) {
        return readBytes(source, 1)[0];
    }

    /// @notice Reads the `amount` of bytes from the specified `source` and advances the cursor.
    function readBytes(Source memory source, uint256 amount) internal pure returns (bytes memory result) {
        result = peekBytes(source, amount);
        source.cursor += amount;
    }

    function peekBytes(Source memory source, uint256 amount) internal pure returns (bytes memory result) {
        require(source.readableBytes() >= amount, "Not enough bytes to read");
        result = new bytes(amount);
        for (uint256 i = 0; i < amount; i++) {
            result[i] = source.data[source.cursor + i];
        }
    }

    function readLines(Source memory source) internal pure returns (Source[] memory lines) {
        uint256 n = source.countLines();
        lines = new Source[](n);
        for (uint256 i = 0; i < n; i++) {
            lines[i] = readUntil(source, NEWLINE);
            source.cursor += 1; // Advance the cursor by 1 to skip the newline
        }
    }

    function readUntil(Source memory source, bytes1 target) internal pure returns (Source memory line) {
        // Calculate the chunk size, which is either the remaining bytes or the bytes until the next `target` offset from the cursor
        uint256 chunkSize = source.readableBytes();
        int256 nextNewline = source.indexOf(target);
        if (nextNewline >= 0) {
            chunkSize = uint256(nextNewline) - source.cursor;
        }
        return from(source.readBytes(chunkSize));
    }

    function toString(Source memory source) internal pure returns (string memory) {
        return string(source.peekBytes(source.readableBytes()));
    }

    function isReadable(Source memory source) internal pure returns (bool) {
        return source.cursor < source.data.length;
    }

    function isReadable(Source memory source, uint256 amount) internal pure returns (bool) {
        return source.cursor + amount <= source.data.length;
    }

    function isEmpty(Source memory source) internal pure returns (bool) {
        return source.data.length == 0;
    }

    function isNotEmpty(Source memory source) internal pure returns (bool) {
        return !isEmpty(source);
    }

    function readableBytes(Source memory source) internal pure returns (uint256) {
        return source.data.length - source.cursor;
    }

    function getLength(Source memory source) internal pure returns (uint256) {
        return source.data.length;
    }

    /// === Read ===

    function countOccurrences(Source memory source, bytes1 target) internal pure returns (uint256 n) {
        for (uint256 i = source.cursor; i < source.data.length; i++) {
            if (source.data[i] == target) {
                n++;
            }
        }
    }

    function countLines(Source memory source) internal pure returns (uint256 n) {
        return countOccurrences(source, NEWLINE) + 1; // Add one for the last line, which does not end with a newline
    }

    /// @notice Looks for the first occurrence of the specified `target` from `cursor` and returns its index, or -1 if not found.
    function indexOf(Source memory source, bytes1 target) internal pure returns (int256) {
        bytes memory data = source.data;
        uint256 length = data.length;
        for (uint256 i = source.cursor; i < length; i++) {
            if (data[i] == target) {
                return int256(i);
            }
        }
        return -1;
    }

    function findLast(Source memory source, bytes memory targetBytes) internal pure returns (MatchResult memory last) {
        bytes memory data = source.data;
        uint256 srcLength = data.length;
        uint256 targetLength = targetBytes.length;
        int256 cursor = int256(source.cursor);

        // If the string is shorter than the target, match impossible
        if (srcLength < targetLength) {
            return last;
        }

        for (int256 i = int256(srcLength - targetLength); i >= cursor; i--) {
            uint256 start = uint256(i);
            bool found = true;
            for (uint256 j = 0; j < targetLength; j++) {
                if (data[start + j] != targetBytes[j]) {
                    found = false;
                    break;
                }
            }

            if (found) {
                return MatchResult(slice(source, start, start + targetLength), start, targetLength);
            }
        }

        return last;
    }

    function findFirst(Source memory source, bytes memory targetBytes)
        internal
        pure
        returns (MatchResult memory first)
    {
        bytes memory data = source.data;
        uint256 srcLength = data.length;
        uint256 targetLength = targetBytes.length;

        // If the string is shorter than the target, match impossible
        if (srcLength < targetLength) {
            return first;
        }

        for (uint256 i = source.cursor; i <= srcLength - targetLength; i++) {
            bool found = true;
            for (uint256 j = 0; j < targetLength; j++) {
                if (data[i + j] != targetBytes[j]) {
                    found = false;
                    break;
                }
            }

            if (found) {
                return MatchResult(slice(source, i, i + targetLength), i, targetLength);
            }
        }
    }

    function findLastOf(Source memory source, bytes[] memory substrings)
        internal
        pure
        returns (MatchResult memory last)
    {
        for (uint256 i = 0; i < substrings.length; i++) {
            MatchResult memory result = source.findLast(substrings[i]);
            if (result.isValid() && result.startIndex >= last.startIndex) {
                last = result;
            }
        }

        require(last.isValid(), string.concat("no last matches found for: ", source.toString()));
    }

    function findFirstOf(Source memory source, bytes[] memory substrings)
        internal
        pure
        returns (MatchResult memory first)
    {
        for (uint256 i = 0; i < substrings.length; i++) {
            MatchResult memory result = source.findFirst(substrings[i]);
            if (result.isValid() && (result.startIndex <= first.startIndex || !first.isValid())) {
                first = result;
            }
        }

        require(first.isValid(), string.concat("no first matches found for: ", source.toString()));
    }
}
