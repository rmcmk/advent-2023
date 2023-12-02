// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";
import { Strings, MatchResult } from "src/Strings.sol";

/// @title StringsTest - Super simple test to ensure that the library works as expected before we use it in the puzzle
contract StringsTest is Test {
    bytes[] private ALL_DIGITS;

    bytes[] private NUMERIC_DIGITS =
        [bytes("1"), bytes("2"), bytes("3"), bytes("4"), bytes("5"), bytes("6"), bytes("7"), bytes("8"), bytes("9")];

    bytes[] private LINGUISTIC_DIGITS = [
        bytes("one"),
        bytes("two"),
        bytes("three"),
        bytes("four"),
        bytes("five"),
        bytes("six"),
        bytes("seven"),
        bytes("eight"),
        bytes("nine")
    ];

    function setUp() public {
        for (uint256 i = 0; i < NUMERIC_DIGITS.length; i++) {
            ALL_DIGITS.push(NUMERIC_DIGITS[i]);
            ALL_DIGITS.push(LINGUISTIC_DIGITS[i]);
        }
    }

    function destruct(string memory str) private pure returns (bytes[] memory) {
        bytes memory strBytes = bytes(str);
        bytes[] memory substrings = new bytes[](strBytes.length);
        for (uint256 i = 0; i < strBytes.length; i++) {
            substrings[i] = abi.encodePacked(strBytes[i]);
        }

        return substrings;
    }

    function assertResult(MatchResult memory result, uint256 expectedStartIndex, uint256 expectedLength) private {
        assertTrue(result.valid);
        assertEq(result.startIndex, expectedStartIndex);
        assertEq(result.length, expectedLength);
    }

    function test_findFirstOf() public {
        string memory str = "123456789";
        bytes[] memory substrings = destruct(str);
        MatchResult memory result = Strings.findFirstOf(str, substrings);
        assertResult(result, 0, 1);

        result = Strings.findFirstOf(str, NUMERIC_DIGITS);
        assertResult(result, 0, 1);

        vm.expectRevert("no first matches found for: 123456789");
        result = Strings.findFirstOf(str, LINGUISTIC_DIGITS);

        result = Strings.findFirstOf(str, ALL_DIGITS);
        assertResult(result, 0, 1);

        // ----------------------------
        str = "onetwothreefourfivesixseveneightnine";
        result = Strings.findFirstOf(str, LINGUISTIC_DIGITS);
        assertResult(result, 0, 3);

        result = Strings.findFirstOf(str, ALL_DIGITS);
        assertResult(result, 0, 1);

        vm.expectRevert("no first matches found for: onetwothreefourfivesixseveneightnine");
        result = Strings.findFirstOf(str, NUMERIC_DIGITS);

        substrings = destruct(str);
        result = Strings.findFirstOf(str, substrings);
        assertResult(result, 0, 1);

        // ----------------------------
        str = "3nmronemlqzfxgonepkh";
        substrings = destruct(str);
        result = Strings.findFirstOf(str, substrings);
        assertResult(result, 0, 1);

        result = Strings.findFirstOf(str, NUMERIC_DIGITS);
        assertResult(result, 0, 1);

        result = Strings.findFirstOf(str, LINGUISTIC_DIGITS);
        assertResult(result, 1, 3);

        result = Strings.findFirstOf(str, ALL_DIGITS);
        assertResult(result, 0, 1);
    }

    function test_findLastOf() public {
        string memory str = "123456789";
        bytes[] memory substrings = destruct(str);
        MatchResult memory result = Strings.findLastOf(str, substrings);
        assertResult(result, 8, 1);

        result = Strings.findLastOf(str, NUMERIC_DIGITS);
        assertResult(result, 8, 1);

        vm.expectRevert("no last matches found for: 123456789");
        result = Strings.findLastOf(str, LINGUISTIC_DIGITS);

        result = Strings.findLastOf(str, ALL_DIGITS);
        assertResult(result, 8, 1);

        // ----------------------------
        str = "onetwothreefourfivesixseveneightnine";
        result = Strings.findLastOf(str, LINGUISTIC_DIGITS);
        assertResult(result, 32, 4);

        result = Strings.findLastOf(str, ALL_DIGITS);
        assertResult(result, 32, 4);

        vm.expectRevert("no last matches found for: onetwothreefourfivesixseveneightnine");
        result = Strings.findLastOf(str, NUMERIC_DIGITS);

        substrings = destruct(str);
        result = Strings.findLastOf(str, substrings);
        assertResult(result, 35, 1);

        // ----------------------------
        str = "3nmronemlqzfxgonepkh";
        substrings = destruct(str);
        result = Strings.findLastOf(str, substrings);
        assertResult(result, 19, 1);

        result = Strings.findLastOf(str, NUMERIC_DIGITS);
        assertResult(result, 0, 1);
        
        result = Strings.findLastOf(str, LINGUISTIC_DIGITS);
        assertResult(result, 14, 3);

        result = Strings.findLastOf(str, ALL_DIGITS);
        assertResult(result, 0, 1);
    }

}
