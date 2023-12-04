// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";
import { VmSafe } from "forge-std/Vm.sol";
import { console2 } from "forge-std/console2.sol";
import { Sources, Source } from "src/Source.sol";

/// @title BaseAdventTest - Base contract for Advent of Code challenges
/// @dev This contract provides helpers and utilities for the Advent of Code challenges.
abstract contract BaseAdventTest is Test {
    using Sources for Source;

    string private constant ROOT_INPUTS = "./inputs/";

    string internal constant SAMPLE1 = "sample1.txt";
    string internal constant PART1 = "part1.txt";
    string internal constant SAMPLE2 = "sample2.txt";
    string internal constant PART2 = "part2.txt";

    function day() internal view virtual returns (uint8);

    /// @notice Read lines from a file in the filesystem.
    /// @dev This function reads a file from the filesystem and returns its contents as a string array.
    /// @dev The path should be relative to the project's root directory.
    /// @param file The name of the file input.
    /// @return lines The contents of the file as a string array.
    function readLines(string memory file) public returns (Source[] memory lines) {
        string memory path = string.concat(ROOT_INPUTS, vm.toString(day()), "/", file);
        require(vm.exists(path), "file does not exist");

        VmSafe.FsMetadata memory metadata = vm.fsMetadata(path);
        require(!metadata.isDir, "file cannot be a directory");
        require(metadata.length > 0, "file cannot be empty");

        Source memory source = Sources.fromString(vm.readFile(path));
        lines = source.readLines();
    }
}
