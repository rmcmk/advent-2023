// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Vm } from "forge-std/Vm.sol";
import { Bytes } from "src/Bytes.sol";

struct Slice {
    ByteBuffer content;
    uint256 relativeStartIndex;
    uint256 length;
}

enum ExpansionMode {
    None,
    Default,
    Minimum
}

enum AccessMode {
    R,
    W,
    RW
}

struct ByteBuffer {
    bytes data;
    AccessMode accessMode;
    ExpansionMode expansionMode;
    uint256 readIndex;
    uint256 writeIndex;
    uint256 markedReadIndex;
    uint256 markedWriteIndex;
}

library ByteSequence {
    Vm private constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    bytes1 constant NEWLINE = bytes1("\n");
    bytes constant EMPTY = new bytes(0);

    /// @notice Creates a new empty slice with the specified `relativeStartIndex` and 0 `length`.
    /// @dev The `relativeStartIndex` is configurable in this case as it is used to determine the best match when using `findFirstOf` and `findLastOf`.
    function emptySlice(uint256 relativeStartIndex) internal pure returns (Slice memory) {
        return Slice(emptyBuffer(), relativeStartIndex, 0);
    }

    // === Empty ===

    function emptyBuffer() internal pure returns (ByteBuffer memory) {
        return emptyBuffer(AccessMode.R);
    }

    function emptyBuffer(ExpansionMode expansionMode) internal pure returns (ByteBuffer memory) {
        return emptyBuffer(AccessMode.R, expansionMode);
    }

    function emptyBuffer(AccessMode accessMode) internal pure returns (ByteBuffer memory) {
        return emptyBuffer(accessMode, ExpansionMode.Default);
    }

    function emptyBuffer(AccessMode accessMode, ExpansionMode expansionMode)
        internal
        pure
        returns (ByteBuffer memory)
    {
        return fromBytes(EMPTY, accessMode, expansionMode);
    }

    // === Alloc ===

    function alloc(uint256 length) internal pure returns (ByteBuffer memory) {
        return alloc(length, AccessMode.R);
    }

    function alloc(uint256 length, ExpansionMode expansionMode) internal pure returns (ByteBuffer memory) {
        return alloc(length, AccessMode.R, expansionMode);
    }

    function alloc(uint256 length, AccessMode accessMode) internal pure returns (ByteBuffer memory) {
        return alloc(length, accessMode, ExpansionMode.Default);
    }

    function alloc(uint256 length, AccessMode accessMode, ExpansionMode expansionMode)
        internal
        pure
        returns (ByteBuffer memory)
    {
        return fromBytes(new bytes(length), accessMode, expansionMode);
    }

    // === string ===

    function fromString(string memory data) internal pure returns (ByteBuffer memory) {
        return fromString(data, AccessMode.R);
    }

    function fromString(string memory data, ExpansionMode expansionMode) internal pure returns (ByteBuffer memory) {
        return fromString(data, AccessMode.R, expansionMode);
    }

    function fromString(string memory data, AccessMode accessMode) internal pure returns (ByteBuffer memory) {
        return fromString(data, accessMode, ExpansionMode.Default);
    }

    function fromString(string memory data, AccessMode accessMode, ExpansionMode expansionMode)
        internal
        pure
        returns (ByteBuffer memory)
    {
        return fromBytes(bytes(data), accessMode, expansionMode);
    }

    // === Bytes1 ===

    function fromBytes1(bytes1 data) internal pure returns (ByteBuffer memory) {
        return fromBytes1(data, AccessMode.R);
    }

    function fromBytes1(bytes1 data, ExpansionMode expansionMode) internal pure returns (ByteBuffer memory) {
        return fromBytes1(data, AccessMode.R, expansionMode);
    }

    function fromBytes1(bytes1 data, AccessMode accessMode) internal pure returns (ByteBuffer memory) {
        return fromBytes1(data, accessMode, ExpansionMode.Default);
    }

    function fromBytes1(bytes1 data, AccessMode accessMode, ExpansionMode expansionMode)
        internal
        pure
        returns (ByteBuffer memory)
    {
        return fromBytes(abi.encodePacked(data), accessMode, expansionMode);
    }

    // === File ===

    function fromFile(string memory path) internal view returns (ByteBuffer memory) {
        return fromFile(path, AccessMode.R);
    }

    function fromFile(string memory path, ExpansionMode expansionMode) internal view returns (ByteBuffer memory) {
        return fromFile(path, AccessMode.R, expansionMode);
    }

    function fromFile(string memory path, AccessMode accessMode) internal view returns (ByteBuffer memory) {
        return fromFile(path, accessMode, ExpansionMode.Default);
    }

    function fromFile(string memory path, AccessMode accessMode, ExpansionMode expansionMode)
        internal
        view
        returns (ByteBuffer memory)
    {
        return fromBytes(vm.readFileBinary(path), accessMode, expansionMode);
    }

    // === Bytes ===

    function fromBytes(bytes memory data) internal pure returns (ByteBuffer memory) {
        return fromBytes(data, AccessMode.R);
    }

    function fromBytes(bytes memory data, ExpansionMode expansionMode) internal pure returns (ByteBuffer memory) {
        return fromBytes(data, AccessMode.R, expansionMode);
    }

    function fromBytes(bytes memory data, AccessMode accessMode) private pure returns (ByteBuffer memory) {
        return fromBytes(data, accessMode, ExpansionMode.Default);
    }

    function fromBytes(bytes memory data, AccessMode accessMode, ExpansionMode expansionMode)
        internal
        pure
        returns (ByteBuffer memory)
    {
        return ByteBuffer(data, accessMode, expansionMode, 0, 0, 0, 0);
    }

    // === Universal functions ===

    function getLength(ByteBuffer memory buffer) internal pure returns (uint256) {
        return buffer.data.length;
    }

    function isEmpty(ByteBuffer memory buffer) internal pure returns (bool) {
        return buffer.data.length == 0;
    }

    function isNotEmpty(ByteBuffer memory buffer) internal pure returns (bool) {
        return buffer.data.length > 0;
    }

    // === Peek functions (does not modify state) ===

    function unsafePeekAt(ByteBuffer memory buffer, uint256 index) private pure returns (bytes1) {
        return buffer.data[index];
    }

    function peekAt(ByteBuffer memory buffer, uint256 index) internal pure returns (bytes1) {
        assertIndexWithinBounds(buffer, index);
        return buffer.data[index];
    }

    function peekFirst(ByteBuffer memory buffer) internal pure returns (bytes1) {
        return buffer.data[0];
    }

    function peekLast(ByteBuffer memory buffer) internal pure returns (bytes1) {
        unchecked {
            return buffer.data[buffer.data.length - 1];
        }
    }

    function peekSlice(ByteBuffer memory buffer, uint256 startIndex) internal pure returns (ByteBuffer memory) {
        return peekSlice(buffer, startIndex, buffer.data.length);
    }

    function unsafeSlice(ByteBuffer memory buffer, uint256 startIndex, uint256 endIndex)
        private
        pure
        returns (ByteBuffer memory)
    {
        unchecked {
            bytes memory data = new bytes(endIndex - startIndex);
            for (uint256 i = startIndex; i < endIndex; i++) {
                data[i - startIndex] = buffer.data[i];
            }
            return fromBytes(data, buffer.accessMode, buffer.expansionMode);
        }
    }

    function peekSlice(ByteBuffer memory buffer, uint256 startIndex, uint256 endIndex)
        internal
        pure
        returns (ByteBuffer memory)
    {
        assertRangeReadable(buffer, startIndex, endIndex);
        return unsafeSlice(buffer, startIndex, endIndex);
    }

    // === Default reader functions ===

    function readableBytes(ByteBuffer memory buffer) internal pure returns (uint256) {
        unchecked {
            return hasReadMode(buffer) ? buffer.data.length - buffer.readIndex : 0;
        }
    }

    function isReadable(ByteBuffer memory buffer) internal pure returns (bool) {
        return isReadable(buffer, 1);
    }

    function isReadable(ByteBuffer memory buffer, uint256 amount) internal pure returns (bool) {
        unchecked {
            return hasReadMode(buffer) && buffer.readIndex + amount <= buffer.data.length;
        }
    }

    function seekReader(ByteBuffer memory buffer, uint256 index) internal pure {
        assertIndexWithinBounds(buffer, index);
        buffer.readIndex = index;
    }

    function skipReader(ByteBuffer memory buffer, uint256 amount) internal pure {
        assertReadableBytes(buffer, amount);
        unchecked {
            buffer.readIndex += amount;
        }
    }

    function markReaderIndex(ByteBuffer memory buffer) internal pure {
        buffer.markedReadIndex = buffer.readIndex;
    }

    function resetReadIndex(ByteBuffer memory buffer) internal pure {
        buffer.readIndex = buffer.markedReadIndex;
        buffer.markedReadIndex = 0;
    }

    function hasReadMode(ByteBuffer memory buffer) internal pure returns (bool) {
        return buffer.accessMode == AccessMode.R || buffer.accessMode == AccessMode.RW;
    }

    // === Read functions ===

    function readBytes1(ByteBuffer memory buffer) internal pure returns (bytes1) {
        assertReadableBytes(buffer, 1);
        unchecked {
            return buffer.data[buffer.readIndex++];
        }
    }

    function readByte(ByteBuffer memory buffer) internal pure returns (ByteBuffer memory) {
        assertReadableBytes(buffer, 1);
        unchecked {
            return fromBytes1(buffer.data[buffer.readIndex++]);
        }
    }

    function readBytes(ByteBuffer memory buffer) internal pure returns (ByteBuffer memory) {
        return readBytes(buffer, buffer.readIndex, buffer.data.length);
    }

    function readBytes(ByteBuffer memory buffer, uint256 amount) internal pure returns (ByteBuffer memory) {
        return readBytes(buffer, buffer.readIndex, buffer.readIndex + amount);
    }

    function readBytes(ByteBuffer memory buffer, uint256 startIndex, uint256 endIndex)
        internal
        pure
        returns (ByteBuffer memory to)
    {
        assertRangeReadable(buffer, startIndex, endIndex);
        to = unsafeSlice(buffer, startIndex, endIndex);
        unchecked {
            skipReader(buffer, endIndex - startIndex);
        }
    }

    // === Default writer functions ===

    function writableBytes(ByteBuffer memory buffer) internal pure returns (uint256) {
        unchecked {
            return hasWriteMode(buffer) ? buffer.data.length - buffer.writeIndex : 0;
        }
    }

    function isWritable(ByteBuffer memory buffer) internal pure returns (bool) {
        return isWritable(buffer, 1);
    }

    function isWritable(ByteBuffer memory buffer, uint256 amount) internal pure returns (bool) {
        unchecked {
            return hasWriteMode(buffer) && buffer.writeIndex + amount <= buffer.data.length;
        }
    }

    function seekWriter(ByteBuffer memory buffer, uint256 index) internal pure {
        assertIndexWithinBounds(buffer, index);
        buffer.writeIndex = index;
    }

    function skipWriter(ByteBuffer memory buffer, uint256 amount) internal pure {
        assertWritableBytes(buffer, amount);
        unchecked {
            buffer.writeIndex += amount;
        }
    }

    function markWriterIndex(ByteBuffer memory buffer) internal pure {
        buffer.markedWriteIndex = buffer.writeIndex;
    }

    function resetWriterIndex(ByteBuffer memory buffer) internal pure {
        buffer.writeIndex = buffer.markedWriteIndex;
        buffer.markedWriteIndex = 0;
    }

    function hasWriteMode(ByteBuffer memory buffer) internal pure returns (bool) {
        return buffer.accessMode == AccessMode.W || buffer.accessMode == AccessMode.RW;
    }

    function tryRealloc(ByteBuffer memory buffer, uint256 minimumBytes) internal pure {
        unchecked {
            if (minimumBytes + buffer.writeIndex >= buffer.data.length || buffer.expansionMode == ExpansionMode.None) {
                return;
            }

            uint256 newLength = buffer.expansionMode == ExpansionMode.Default ? buffer.data.length * 2 : minimumBytes;
            buffer.data = abi.encodePacked(buffer.data, new bytes(newLength));
        }
    }

    // === Write functions ===

    function writeByte(ByteBuffer memory self, bytes1 value) internal pure {
        assertWritableBytes(self, 1);
        unchecked {
            self.data[self.writeIndex++] = value;
        }
    }

    function writeBytes(ByteBuffer memory self, bytes memory data) internal pure {
        assertWritableBytes(self, data.length);
        for (uint256 i = 0; i < data.length; i++) {
            unchecked {
                self.data[self.writeIndex++] = data[i];
            }
        }
    }

    function writeBytes(ByteBuffer memory self, ByteBuffer memory buffer) internal pure {
        writeBytes(self, take(buffer));
    }

    // === Checks ===

    function assertIndexWithinBounds(ByteBuffer memory buffer, uint256 index) private pure {
        require(index < buffer.data.length, "Index out of bounds");
    }

    function assertIndexesWithinBounds(ByteBuffer memory buffer, uint256 startIndex, uint256 endIndex) private pure {
        require(startIndex < endIndex, "Start index must be less than end index");
        require(startIndex < buffer.data.length, "Start index out of bounds");
        require(endIndex <= buffer.data.length, "End index out of bounds");
    }

    function assertReadableBytes(ByteBuffer memory buffer, uint256 amount) private pure {
        require(isReadable(buffer, amount), "Not enough readable bytes");
    }

    function assertRangeReadable(ByteBuffer memory buffer, uint256 startIndex, uint256 endIndex) private pure {
        assertStartReadIndex(buffer, startIndex);
        assertIndexesWithinBounds(buffer, startIndex, endIndex);
        unchecked {
            assertReadableBytes(buffer, endIndex - startIndex);
        }
    }

    function assertStartReadIndex(ByteBuffer memory buffer, uint256 index) private pure {
        require(index <= buffer.readIndex, "Index must be less than or equal to read index");
    }

    function assertStartWriteIndex(ByteBuffer memory buffer, uint256 index) private pure {
        require(index <= buffer.writeIndex, "Index must be less than or equal to write index");
    }

    function assertWritableBytes(ByteBuffer memory buffer, uint256 amount) private pure {
        tryRealloc(buffer, amount);
        require(isWritable(buffer, amount), "Not enough writable bytes");
    }

    function assertRangeWritable(ByteBuffer memory buffer, uint256 startIndex, uint256 endIndex) private pure {
        assertStartWriteIndex(buffer, startIndex);
        assertIndexesWithinBounds(buffer, startIndex, endIndex);
        unchecked {
            assertWritableBytes(buffer, endIndex - startIndex);
        }
    }

    // === Transformations ===
    function take(ByteBuffer memory buffer) private pure returns (bytes memory slice) {
        uint256 start = buffer.readIndex;
        uint256 writeIndex = buffer.writeIndex;
        uint256 end = writeIndex == 0 ? buffer.data.length : writeIndex;

        unchecked {
            slice = new bytes(end - start);
            for (uint256 i = start; i < end; i++) {
                slice[i - start] = buffer.data[i];
            }
        }
    }

    function toBytes(ByteBuffer memory buffer) internal pure returns (bytes memory) {
        return take(buffer);
    }

    function toBytes1(ByteBuffer memory buffer) internal pure returns (bytes1) {
        return peekFirst(buffer);
    }

    function explodeBytes(ByteBuffer memory buffer) internal pure returns (bytes[] memory result) {
        bytes memory data = buffer.data;
        result = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            result[i] = abi.encodePacked(data[i]);
        }
    }

    // === Helpers for dealing with sequences of bytes ===
    function countOccurrences(ByteBuffer memory buffer, bytes1 target) internal pure returns (uint256) {
        uint256 n = 0;
        bytes memory data = buffer.data;
        for (uint256 i = buffer.readIndex; i < data.length; i++) {
            if (data[i] == target) {
                unchecked {
                    n++;
                }
            }
        }
        return n;
    }

    function distanceTo(ByteBuffer memory buffer, bytes1 target) internal pure returns (uint256) {
        int256 index = indexOf(buffer, target);
        require(index >= 0, "Target not found");
        unchecked {
            return uint256(index) - buffer.readIndex;
        }
    }

    /// @notice Looks for the first occurrence of the specified `target` from `cursor` and returns its index, or -1 if not found.
    function indexOf(ByteBuffer memory buffer, bytes1 target) internal pure returns (int256) {
        bytes memory data = buffer.data;
        for (uint256 i = buffer.readIndex; i < data.length; i++) {
            if (data[i] == target) {
                return int256(i);
            }
        }
        return -1;
    }

    /// @notice Looks for the first occurrence of the specified `target` from `cursor` and returns the start index, or -1 if not found.
    function indexOf(ByteBuffer memory buffer, bytes memory target) internal pure returns (int256) {
        Slice memory slice = findFirst(buffer, target);
        if (slice.length > 0) {
            return int256(slice.relativeStartIndex);
        }
        return -1;
    }

    function contains(ByteBuffer memory buffer, bytes memory target) internal pure returns (bool) {
        return indexOf(buffer, target) >= 0;
    }

    function contains(ByteBuffer memory buffer, bytes1 target) internal pure returns (bool) {
        return indexOf(buffer, target) >= 0;
    }

    function findLast(ByteBuffer memory buffer, bytes memory targetBytes) internal pure returns (Slice memory slice) {
        uint256 srcLength = buffer.data.length;
        uint256 targetLength = targetBytes.length;
        int256 readIndex = int256(buffer.readIndex);

        // If the target is longer than the source, it can't possibly be contained within it
        if (targetLength > srcLength) {
            return slice;
        }

        unchecked {
            for (int256 i = int256(srcLength - targetLength); i >= readIndex; i--) {
                uint256 start = uint256(i);
                bool found = true;
                for (uint256 j = 0; j < targetLength; j++) {
                    if (buffer.data[start + j] != targetBytes[j]) {
                        found = false;
                        break;
                    }
                }

                if (found) {
                    return Slice(unsafeSlice(buffer, start, start + targetLength), start, targetLength);
                }
            }
        }

        return slice;
    }

    function findFirst(ByteBuffer memory buffer, bytes memory targetBytes) internal pure returns (Slice memory slice) {
        uint256 srcLength = buffer.data.length;
        uint256 targetLength = targetBytes.length;

        // If the target is longer than the source, it can't possibly be contained within it
        if (targetLength > srcLength) {
            return slice;
        }

        unchecked {
            for (uint256 i = buffer.readIndex; i <= srcLength - targetLength; i++) {
                bool found = true;
                for (uint256 j = 0; j < targetLength; j++) {
                    if (buffer.data[i + j] != targetBytes[j]) {
                        found = false;
                        break;
                    }
                }

                if (found) {
                    return Slice(unsafeSlice(buffer, i, i + targetLength), i, targetLength);
                }
            }
        }

        return slice;
    }

    function findLastOf(ByteBuffer memory buffer, bytes[] memory substrings) internal pure returns (Slice memory) {
        Slice memory bestSlice = emptySlice(0);
        for (uint256 i = 0; i < substrings.length; i++) {
            Slice memory slice = findLast(buffer, substrings[i]);
            if (slice.length > 0 && slice.relativeStartIndex >= bestSlice.relativeStartIndex) {
                bestSlice = slice;
            }
        }
        return bestSlice;
    }

    function findFirstOf(ByteBuffer memory buffer, bytes[] memory substrings) internal pure returns (Slice memory) {
        Slice memory bestSlice = emptySlice(type(uint256).max);
        for (uint256 i = 0; i < substrings.length; i++) {
            Slice memory slice = findFirst(buffer, substrings[i]);
            if (slice.length > 0 && slice.relativeStartIndex <= bestSlice.relativeStartIndex) {
                bestSlice = slice;
            }
        }
        return bestSlice;
    }

    function splitAndTrim(ByteBuffer memory buffer, bytes1 delimiter)
        internal
        pure
        returns (ByteBuffer[] memory splits)
    {
        ByteBuffer[] memory rawSplits = split(buffer, delimiter);
        splits = new ByteBuffer[](rawSplits.length);
        for (uint256 i = 0; i < rawSplits.length; i++) {
            splits[i] = trim(rawSplits[i]);
        }
    }

    function split(ByteBuffer memory buffer, bytes1 delimiter) internal pure returns (ByteBuffer[] memory splits) {
        uint256 splitCount = countOccurrences(buffer, delimiter) + 1;
        splits = new ByteBuffer[](splitCount);

        // If there are no delimiters, return the original buffer so we are not erroneously allocating a new buffer
        if (splitCount == 1) {
            splits[0] = buffer;
            return splits;
        }

        uint256 index = 0;
        uint256 start = buffer.readIndex;
        uint256 end = buffer.data.length;

        for (uint256 i = buffer.readIndex; i < end; i++) {
            if (buffer.data[i] == delimiter) {
                unchecked {
                    splits[index++] = unsafeSlice(buffer, start, i);
                    start = i + 1;
                }
            }
        }

        // Capture any leftovers after the last delimiter
        if (start < end) {
            unchecked {
                splits[index++] = unsafeSlice(buffer, start, end);
            }
        }
    }

    function trim(ByteBuffer memory buffer) internal pure returns (ByteBuffer memory) {
        uint256 start = buffer.readIndex;
        uint256 end = buffer.data.length;
        unchecked {
            while (start < end && Bytes.isWhitespace(buffer.data[start])) {
                start++;
            }
            if (start == end) {
                return emptyBuffer();
            }
            while (end > start && Bytes.isWhitespace(buffer.data[end - 1])) {
                end--;
            }
        }
        return unsafeSlice(buffer, start, end);
    }

    // === Type transformers ===

    function to2DBytes1Matrix(ByteBuffer memory buffer) internal pure returns (bytes1[][] memory matrix) {
        ByteBuffer[] memory lines = toLines(buffer);
        uint256 width = getLength(lines[0]);
        uint256 height = lines.length;

        matrix = new bytes1[][](height * width);
        for (uint256 y = 0; y < height; y++) {
            matrix[y] = new bytes1[](width);
            for (uint256 x = 0; x < width; x++) {
                matrix[y][x] = unsafePeekAt(lines[y], x);
            }
        }
    }

    function toString(ByteBuffer memory buffer) internal pure returns (string memory) {
        return string(toBytes(buffer));
    }

    function toLines(ByteBuffer memory buffer) internal pure returns (ByteBuffer[] memory) {
        return split(buffer, NEWLINE);
    }

    function toUint256(ByteBuffer memory buffer) internal pure returns (uint256) {
        return vm.parseUint(toString(buffer));
    }

    function toUint8(ByteBuffer memory buffer) internal pure returns (uint8) {
        return uint8(toUint256(buffer));
    }
}
