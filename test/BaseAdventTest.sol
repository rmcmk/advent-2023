// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";
import { VmSafe } from "forge-std/Vm.sol";
import { console2 } from "forge-std/console2.sol";

import { Bytes } from "src/Bytes.sol";

/// @title BaseAdventTest - Base contract for Advent of Code challenges
/// @dev This contract provides helpers and utilities for the Advent of Code challenges.
abstract contract BaseAdventTest is Test {
    string private constant ROOT_INPUTS = "./inputs/";

    string internal constant SAMPLE1 = "sample1.txt";
    string internal constant PART1 = "part1.txt";
    string internal constant SAMPLE2 = "sample2.txt";
    string internal constant PART2 = "part2.txt";

    function day() internal view virtual returns (uint256);

    /// @notice Read lines from a file in the VM's filesystem.
    /// @dev This function reads a file from the VM's filesystem and returns its contents as a string array.
    /// @dev The path should be relative to the project's root directory.
    /// @param file The name of the file input.
    /// @return lines The contents of the file as a string array.
    function readLines(string memory file) public returns (string[] memory lines) {
        string memory path = string.concat(ROOT_INPUTS, vm.toString(day()), "/", file);
        require(vm.exists(path), "file does not exist");

        VmSafe.FsMetadata memory metadata = vm.fsMetadata(path);
        require(!metadata.isDir, "file cannot be a directory");
        require(metadata.length > 0, "file cannot be empty");

        bytes memory data = bytes(vm.readFile(path));
        uint256 n = Bytes.countLines(data);
        lines = new string[](n);
        uint256 bytesRead;
        for (uint256 i = 0; i < n; i++) {
            bytes memory split = Bytes.readUntilNewlineExclusive(data, bytesRead);
            lines[i] = string(split);
            bytesRead += split.length + 1; // +1 as we are delimiting by a single byte and not including it in the result
        }
    }
}
