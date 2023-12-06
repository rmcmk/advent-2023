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

    function fromBytes(bytes memory data, AccessMode accessMode) internal pure returns (ByteBuffer memory) {
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
        return hasWriteMode(buffer) ? buffer.writeIndex : buffer.data.length;
    }

    function getCapacity(ByteBuffer memory buffer) internal pure returns (uint256) {
        return buffer.data.length;
    }

    function isEmpty(ByteBuffer memory buffer) internal pure returns (bool) {
        return getLength(buffer) == 0;
    }

    function isNotEmpty(ByteBuffer memory buffer) internal pure returns (bool) {
        return !isEmpty(buffer);
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
            return buffer.data[getLength(buffer) - 1];
        }
    }

    function peekSlice(ByteBuffer memory buffer, uint256 start) internal pure returns (ByteBuffer memory) {
        return peekSlice(buffer, start, getLength(buffer));
    }

    function unsafeSlice(ByteBuffer memory buffer, uint256 start, uint256 end)
        private
        pure
        returns (ByteBuffer memory)
    {
        unchecked {
            bytes memory data = new bytes(end - start);
            for (uint256 i = start; i < end; i++) {
                data[i - start] = buffer.data[i];
            }
            return fromBytes(data, buffer.accessMode, buffer.expansionMode);
        }
    }

    function peekSlice(ByteBuffer memory buffer, uint256 start, uint256 end)
        internal
        pure
        returns (ByteBuffer memory)
    {
        assertRangeReadable(buffer, start, end);
        return unsafeSlice(buffer, start, end);
    }

    // === Default reader functions ===

    function readableBytes(ByteBuffer memory buffer) internal pure returns (uint256) {
        unchecked {
            return hasReadMode(buffer) ? getLength(buffer) - buffer.readIndex : 0;
        }
    }

    function isReadable(ByteBuffer memory buffer) internal pure returns (bool) {
        return isReadable(buffer, 1);
    }

    function isReadable(ByteBuffer memory buffer, uint256 amount) internal pure returns (bool) {
        unchecked {
            return hasReadMode(buffer) && buffer.readIndex + amount <= getLength(buffer);
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
        uint256 start = buffer.readIndex;
        unchecked {
            uint256 end = start + readableBytes(buffer);
            buffer.readIndex = end;
            return unsafeSlice(buffer, start, end);
        }
    }

    function readBytes(ByteBuffer memory buffer, uint256 amount) internal pure returns (ByteBuffer memory) {
        uint256 start = buffer.readIndex;
        unchecked {
            uint256 end = start + amount;
            uint256 length = end - start;
            assertRangeReadable(buffer, start, end);

            // Since we have checked the range above, we can set the read index directly, bypassing the `skipReader` checks
            // Also this is safe to increment here as we are using `unsafeSlice`, the slice can be safely returned later without allocating an extra slot for the buffer
            buffer.readIndex += length;
            return unsafeSlice(buffer, start, end);
        }
    }

    function sliceFrom(ByteBuffer memory buffer, uint256 start) internal pure returns (ByteBuffer memory) {
        return sliceOf(buffer, start, getLength(buffer));
    }

    function sliceTo(ByteBuffer memory buffer, uint256 end) internal pure returns (ByteBuffer memory) {
        return sliceOf(buffer, buffer.readIndex, end);
    }

    function sliceOf(ByteBuffer memory buffer, uint256 start, uint256 end) internal pure returns (ByteBuffer memory) {
        assertRangeReadable(buffer, start, end);
        return unsafeSlice(buffer, start, end);
    }

    // === Default writer functions ===

    /// @notice Returns the number of bytes that can be written to the buffer.
    /// @dev This function does not take into account the access mode of the buffer.
    ///         It is used to determine whether the buffer needs to be reallocated.
    function unsafeWritableBytes(ByteBuffer memory buffer) private pure returns (uint256) {
        return getCapacity(buffer) - buffer.writeIndex;
    }

    function writableBytes(ByteBuffer memory buffer) internal pure returns (uint256) {
        unchecked {
            return hasWriteMode(buffer) ? unsafeWritableBytes(buffer) : 0;
        }
    }

    function isWritable(ByteBuffer memory buffer) internal pure returns (bool) {
        return isWritable(buffer, 1);
    }

    function isWritable(ByteBuffer memory buffer, uint256 amount) internal pure returns (bool) {
        unchecked {
            return hasWriteMode(buffer) && buffer.writeIndex + amount <= getCapacity(buffer);
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
        writeBytes(self, takeBytes(buffer));
    }

    // === Checks ===

    function assertIndexWithinBounds(ByteBuffer memory buffer, uint256 index) private pure {
        require(index < getCapacity(buffer), "Index out of bounds");
    }

    function assertIndexesWithinBounds(ByteBuffer memory buffer, uint256 start, uint256 end) private pure {
        require(start < end, "Start index must be less than end index");

        uint256 capacity = getCapacity(buffer);
        require(start < capacity, "Start index exceeds buffer capacity");
        require(end <= capacity, "End index exceeds buffer capacity");

        uint256 length = end - start;
        require(length <= capacity, "Length exceeds buffer capacity");
    }

    function assertReadableBytes(ByteBuffer memory buffer, uint256 amount) private pure {
        require(isReadable(buffer, amount), "Not enough readable bytes");
    }

    function assertRangeReadable(ByteBuffer memory buffer, uint256 start, uint256 end) private pure {
        assertIndexesWithinBounds(buffer, start, end);
        unchecked {
            assertReadableBytes(buffer, end - start);
        }
    }

    function assertWritableBytes(ByteBuffer memory buffer, uint256 amount) private pure {
        tryRealloc(buffer, amount); // tryRealloc takes care of the overflow check
    }

    function assertRangeWritable(ByteBuffer memory buffer, uint256 start, uint256 end) private pure {
        assertIndexesWithinBounds(buffer, start, end);
        unchecked {
            assertWritableBytes(buffer, end - start);
        }
    }

    /// @notice Tries to reallocate the buffer to accommodate a minimum number of additional bytes.
    /// @dev All state this function goes through:
    ///     - If the buffer is already writable for the required minimum number of bytes, this function does nothing.
    ///     - If the buffer is not in write mode, this function will revert.
    ///     - If the buffer would overflow but the expansion mode is set to `None`, this function will revert.
    ///     - If the buffer would overflow but the expansion mode is set to `Default`, the buffer will be reallocated to twice its current capacity.
    ///     - If the buffer would overflow but the expansion mode is set to `Minimum`, the buffer will only allocate an additional number of bytes equal to the required minimum.
    ///     - This function is used internally by the write functions to ensure that the buffer has enough capacity to accommodate the data being written.
    /// @param buffer The ByteBuffer to be reallocated.
    /// @param minimumBytes The minimum number of additional bytes the buffer should be able to accommodate.
    function tryRealloc(ByteBuffer memory buffer, uint256 minimumBytes) private pure {
        require(hasWriteMode(buffer), "Buffer is not in write mode");

        // Check if the buffer is already writable for the required minimum number of bytes
        // We use `unsafeWritableBytes` here as `isWritable()` does more checks that are already
        //  performed by the `require` statement above
        if (unsafeWritableBytes(buffer) >= minimumBytes) {
            return;
        }

        // Ensure that the buffer is in a writable state and has not overflowed
        require(
            buffer.expansionMode != ExpansionMode.None,
            "Buffer is in write mode but has overflown. Expansion mode set to 'None'"
        );

        // Calculate the new length for the buffer based on the expansion mode
        unchecked {
            uint256 newLength = buffer.expansionMode == ExpansionMode.Default ? getCapacity(buffer) * 2 : minimumBytes;

            // Perform the reallocation by encoding packed bytes to the buffer data
            buffer.data = abi.encodePacked(buffer.data, new bytes(newLength));
        }
    }

    function explodeBytes(ByteBuffer memory buffer) internal pure returns (bytes[] memory result) {
        uint256 length = getLength(buffer);
        result = new bytes[](length);
        for (uint256 i = 0; i < length; i++) {
            result[i] = abi.encodePacked(unsafePeekAt(buffer, i));
        }
    }

    // === Helpers for dealing with sequences of bytes ===
    function countOccurrences(ByteBuffer memory buffer, bytes1 target) internal pure returns (uint256) {
        uint256 n = 0;
        for (uint256 i = buffer.readIndex; i < getLength(buffer); i++) {
            if (unsafePeekAt(buffer, i) == target) {
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
    function lastIndexOf(ByteBuffer memory buffer, bytes1 target) internal pure returns (int256) {
        bytes memory data = buffer.data;
        for (int256 i = int256(buffer.writeIndex - 1); i >= 0; i--) {
            if (data[uint256(i)] == target) {
                return i;
            }
        }
        return -1;
    }

    /// @notice Looks for the first occurrence of the specified `target` from the current reader index and returns its index, or -1 if not found.
    function indexOf(ByteBuffer memory buffer, bytes1 target) internal pure returns (int256) {
        for (uint256 i = buffer.readIndex; i < getLength(buffer); i++) {
            if (unsafePeekAt(buffer, i) == target) {
                return int256(i);
            }
        }
        return -1;
    }

    /// @notice Looks for the first occurrence of the specified `target` from the current reader index and returns its index, or reverts if not found.
    function safeIndexOf(ByteBuffer memory buffer, bytes1 target) internal pure returns (uint256) {
        int256 index = indexOf(buffer, target);
        require(index >= 0, "Target not found");
        return uint256(index);
    }

    function contains(ByteBuffer memory buffer, bytes1 target) internal pure returns (bool) {
        return indexOf(buffer, target) >= 0;
    }

    function findLast(ByteBuffer memory buffer, bytes memory targetBytes) internal pure returns (Slice memory slice) {
        uint256 srcLength = getLength(buffer);
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
        uint256 srcLength = getLength(buffer);
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

        uint256 length = rawSplits.length;
        uint256 splitsCount = 0;
        splits = new ByteBuffer[](length);

        for (uint256 i = 0; i < length; i++) {
            ByteBuffer memory trimmed = trim(rawSplits[i]);
            if (isNotEmpty(trimmed)) {
                splits[splitsCount++] = trimmed;
            }
        }

        // In the event that the split operation results in empty elements, we need to clamp the size of the array to the number of non-empty elements.
        // These empty elements can arise particularly after the trimming operation.
        if (splitsCount != length) {
            assembly {
                mstore(splits, splitsCount)
            }
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
        uint256 end = getLength(buffer);

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
        uint256 end = getLength(buffer);
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

    function toLines(ByteBuffer memory buffer) internal pure returns (ByteBuffer[] memory) {
        return split(buffer, NEWLINE);
    }

    /// @dev The "take" functions extract slices from the given ByteBuffer, starting from the current read index
    ///         up to the end of the write index if the buffer is in write mode, otherwise up to the end of the buffer.
    ///
    /// ==============================================================================================================
    ///     These functions do not modify the state of the buffer; instead, they create new types from the extracted bytes.
    /// ==============================================================================================================
    ///
    ///     Note: These functions do not guarantee the correctness of the underlying data or the extracted types.
    ///         They are a convenient way to extract bytes from a ByteBuffer and convert them to other types.

    function unsafeTakeBytes(ByteBuffer memory buffer, uint256 start, uint256 end)
        private
        pure
        returns (bytes memory)
    {
        unchecked {
            bytes memory data = new bytes(end - start);
            for (uint256 i = start; i < end; i++) {
                data[i - start] = buffer.data[i];
            }
            return data;
        }
    }

    function takeBytes(ByteBuffer memory buffer) internal pure returns (bytes memory) {
        return unsafeTakeBytes(buffer, buffer.readIndex, getLength(buffer));
    }

    function takeBytes(ByteBuffer memory buffer, uint256 start, uint256 end) internal pure returns (bytes memory) {
        assertIndexesWithinBounds(buffer, start, end);
        return unsafeTakeBytes(buffer, start, end);
    }

    function takeString(ByteBuffer memory buffer) internal pure returns (string memory) {
        return string(takeBytes(buffer));
    }

    function takeUint256(ByteBuffer memory buffer) internal pure returns (uint256) {
        return vm.parseUint(takeString(buffer));
    }

    function takeUint8(ByteBuffer memory buffer) internal pure returns (uint8) {
        return uint8(takeUint256(buffer));
    }
}
