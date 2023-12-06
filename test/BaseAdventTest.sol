// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";
import { VmSafe } from "forge-std/Vm.sol";
import { Slice, ByteBuffer, ByteSequence, AccessMode, ExpansionMode } from "src/ByteBuffer.sol";

/// @title BaseAdventTest - Base contract for Advent of Code challenges
/// @dev This contract provides helpers and utilities for the Advent of Code challenges.
abstract contract BaseAdventTest is Test {
    using ByteSequence for ByteBuffer;

    string private constant ROOT_INPUTS = "./inputs/";

    string internal constant SAMPLE1 = "sample1.txt";
    string internal constant PART1 = "part1.txt";
    string internal constant SAMPLE2 = "sample2.txt";
    string internal constant PART2 = "part2.txt";

    function day() internal view virtual returns (uint8);

    function read(string memory file) private returns (ByteBuffer memory) {
        string memory path = string.concat(ROOT_INPUTS, vm.toString(day()), "/", file);
        require(vm.exists(path), "file does not exist");

        VmSafe.FsMetadata memory metadata = vm.fsMetadata(path);
        require(!metadata.isDir, "file cannot be a directory");
        require(metadata.length > 0, "file cannot be empty");

        return ByteSequence.fromFile(path);
    }

    function readLines(string memory file) public returns (ByteBuffer[] memory lines) {
        return read(file).toLines();
    }

    function read2DBytes1Matrix(string memory file) public returns (bytes1[][] memory matrix) {
        return read(file).to2DBytes1Matrix();
    }
}
