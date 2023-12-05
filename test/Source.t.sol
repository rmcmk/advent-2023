// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";
import { ByteSource, ByteSources } from "src/ByteSource.sol";
import { MatchResult, MatchResults } from "src/MatchResult.sol";
import { VmSafe } from "forge-std/Vm.sol";
import { console2 } from "forge-std/console2.sol";

/// @title SourceTest - Super simple test to ensure that the library works as expected before we use it in the puzzle
contract SourceTest is Test {
    using ByteSources for ByteSource;

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

    function destruct(ByteSource memory source) private pure returns (bytes[] memory) {
        bytes memory data = source.data;
        bytes[] memory substrings = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            substrings[i] = abi.encodePacked(data[i]);
        }

        return substrings;
    }

    function assertResult(MatchResult memory result, uint256 expectedStartIndex, uint256 expectedLength) private {
        assertEq(result.startIndex, expectedStartIndex);
        assertEq(result.length, expectedLength);
    }

    function test_read_1() public {
        ByteSource memory str = ByteSources.fromString("123456789");
        assertBytes1Eq(str.readByte(), bytes1("1"));
        assertBytes1Eq(str.readByte(), bytes1("2"));
        assertBytes1Eq(str.readByte(), bytes1("3"));
        assertBytes1Eq(str.readByte(), bytes1("4"));
        assertBytes1Eq(str.readByte(), bytes1("5"));
        assertBytes1Eq(str.readByte(), bytes1("6"));
        assertBytes1Eq(str.readByte(), bytes1("7"));
        assertBytes1Eq(str.readByte(), bytes1("8"));
        assertBytes1Eq(str.readByte(), bytes1("9"));
        vm.expectRevert("Not enough bytes to read");
        str.readByte();
    }

    function test_read_2() public {
        string memory path = "./inputs/1/sample1.txt";
        assertTrue(vm.exists(path));

        VmSafe.FsMetadata memory metadata = vm.fsMetadata(path);
        assertTrue(!metadata.isDir);
        assertTrue(metadata.length > 0);

        ByteSource memory source = ByteSources.fromString(vm.readFile(path));
        ByteSource[] memory lines = source.toLines();

        assertEq(lines.length, 4);
        assertEq(lines[0].data, "1abc2");
        assertEq(lines[1].data, "pqr3stu8vwx");
        assertEq(lines[2].data, "a1b2c3d4e5f");
        assertEq(lines[3].data, "treb7uchet");
    }

    function assertBytes1Eq(bytes1 a, bytes1 b) private {
        assertEq(uint8(a), uint8(b));
    }

    function test_findFirstOf_1() public {
        ByteSource memory str = ByteSources.fromString("123456789");
        bytes[] memory substrings = destruct(str);
        MatchResult memory result = ByteSources.findFirstOf(str, substrings);
        assertResult(result, 0, 1);

        result = ByteSources.findFirstOf(str, NUMERIC_DIGITS);
        assertResult(result, 0, 1);

        vm.expectRevert("no first matches found for: 123456789");
        result = ByteSources.findFirstOf(str, LINGUISTIC_DIGITS);

        result = ByteSources.findFirstOf(str, ALL_DIGITS);
        assertResult(result, 0, 1);
    }

    function test_findFirstOf_2() public {
        ByteSource memory str = ByteSources.fromString("onetwothreefourfivesixseveneightnine");
        bytes[] memory substrings = destruct(str);
        MatchResult memory result = ByteSources.findFirstOf(str, substrings);
        assertResult(result, 0, 1);

        result = ByteSources.findFirstOf(str, ALL_DIGITS);
        assertResult(result, 0, 3);

        result = ByteSources.findFirstOf(str, LINGUISTIC_DIGITS);
        assertResult(result, 0, 3);

        vm.expectRevert("no first matches found for: onetwothreefourfivesixseveneightnine");
        result = ByteSources.findFirstOf(str, NUMERIC_DIGITS);
    }

    function test_findFirstOf_3() public {
        ByteSource memory str = ByteSources.fromString("3nmronemlqzfxgonepkh");
        bytes[] memory substrings = destruct(str);
        MatchResult memory result = ByteSources.findFirstOf(str, substrings);
        assertResult(result, 0, 1);

        result = ByteSources.findFirstOf(str, NUMERIC_DIGITS);
        assertResult(result, 0, 1);

        result = ByteSources.findFirstOf(str, LINGUISTIC_DIGITS);
        assertResult(result, 4, 3);

        result = ByteSources.findFirstOf(str, ALL_DIGITS);
        assertResult(result, 0, 1);
    }

    function test_findFirstOf_4() public {
        ByteSource memory str = ByteSources.fromString("gsjgklneight6zqfz");
        bytes[] memory substrings = destruct(str);
        MatchResult memory result = ByteSources.findFirstOf(str, substrings);
        assertResult(result, 0, 1);

        result = ByteSources.findFirstOf(str, NUMERIC_DIGITS);
        assertResult(result, 12, 1);

        result = ByteSources.findFirstOf(str, LINGUISTIC_DIGITS);
        assertResult(result, 7, 5);

        result = ByteSources.findFirstOf(str, ALL_DIGITS);
        assertResult(result, 7, 5);
    }

    function test_findFirstOf_5() public {
        ByteSource memory str = ByteSources.fromString("pqr3stu8vwx");
        bytes[] memory substrings = destruct(str);
        MatchResult memory result = ByteSources.findFirstOf(str, substrings);
        assertResult(result, 0, 1);

        result = ByteSources.findFirstOf(str, NUMERIC_DIGITS);
        assertResult(result, 3, 1);

        vm.expectRevert("no first matches found for: pqr3stu8vwx");
        result = ByteSources.findFirstOf(str, LINGUISTIC_DIGITS);

        result = ByteSources.findFirstOf(str, ALL_DIGITS);
        assertResult(result, 3, 1);
    }

    function test_findFirstOf_6() public {
        ByteSource memory str = ByteSources.fromString("abcone2threexyz");
        bytes[] memory substrings = destruct(str);
        MatchResult memory result = ByteSources.findFirstOf(str, substrings);
        assertResult(result, 0, 1);

        result = ByteSources.findFirstOf(str, NUMERIC_DIGITS);
        assertResult(result, 6, 1);

        result = ByteSources.findFirstOf(str, LINGUISTIC_DIGITS);
        assertResult(result, 3, 3);

        result = ByteSources.findFirstOf(str, ALL_DIGITS);
        assertResult(result, 3, 3);
    }

    function test_findLastOf_1() public {
        ByteSource memory str = ByteSources.fromString("123456789");
        bytes[] memory substrings = destruct(str);
        MatchResult memory result = ByteSources.findLastOf(str, substrings);
        assertResult(result, 8, 1);

        result = ByteSources.findLastOf(str, NUMERIC_DIGITS);
        assertResult(result, 8, 1);

        vm.expectRevert("no last matches found for: 123456789");
        result = ByteSources.findLastOf(str, LINGUISTIC_DIGITS);

        result = ByteSources.findLastOf(str, ALL_DIGITS);
        assertResult(result, 8, 1);
    }

    function test_findLastOf_2() public {
        ByteSource memory str = ByteSources.fromString("onetwothreefourfivesixseveneightnine");
        bytes[] memory substrings = destruct(str);
        MatchResult memory result = ByteSources.findLastOf(str, substrings);
        assertResult(result, 35, 1);

        result = ByteSources.findLastOf(str, ALL_DIGITS);
        assertResult(result, 32, 4);

        result = ByteSources.findLastOf(str, LINGUISTIC_DIGITS);
        assertResult(result, 32, 4);

        vm.expectRevert("no last matches found for: onetwothreefourfivesixseveneightnine");
        result = ByteSources.findLastOf(str, NUMERIC_DIGITS);
    }

    function test_findLastOf_3() public {
        ByteSource memory str = ByteSources.fromString("3nmronemlqzfxgonepkh");
        bytes[] memory substrings = destruct(str);
        MatchResult memory result = ByteSources.findLastOf(str, substrings);
        assertResult(result, 19, 1);

        result = ByteSources.findLastOf(str, NUMERIC_DIGITS);
        assertResult(result, 0, 1);

        result = ByteSources.findLastOf(str, LINGUISTIC_DIGITS);
        assertResult(result, 14, 3);

        result = ByteSources.findLastOf(str, ALL_DIGITS);
        assertResult(result, 14, 3);
    }

    function test_findLastOf_4() public {
        ByteSource memory str = ByteSources.fromString("gsjgklneight6zqfz");
        bytes[] memory substrings = destruct(str);
        MatchResult memory result = ByteSources.findLastOf(str, substrings);
        assertResult(result, 16, 1);

        result = ByteSources.findLastOf(str, NUMERIC_DIGITS);
        assertResult(result, 12, 1);

        result = ByteSources.findLastOf(str, LINGUISTIC_DIGITS);
        assertResult(result, 7, 5);

        result = ByteSources.findLastOf(str, ALL_DIGITS);
        assertResult(result, 12, 1);
    }

    function test_findLastOf_5() public {
        ByteSource memory str = ByteSources.fromString("pqr3stu8vwx");
        bytes[] memory substrings = destruct(str);
        MatchResult memory result = ByteSources.findLastOf(str, substrings);
        assertResult(result, 10, 1);

        result = ByteSources.findLastOf(str, NUMERIC_DIGITS);
        assertResult(result, 7, 1);

        vm.expectRevert("no last matches found for: pqr3stu8vwx");
        result = ByteSources.findLastOf(str, LINGUISTIC_DIGITS);

        result = ByteSources.findLastOf(str, ALL_DIGITS);
        assertResult(result, 3, 1);
    }

    function test_findLastOf_6() public {
        ByteSource memory str = ByteSources.fromString("abcone2threexyz");
        bytes[] memory substrings = destruct(str);
        MatchResult memory result = ByteSources.findLastOf(str, substrings);
        assertResult(result, 14, 1);

        result = ByteSources.findLastOf(str, NUMERIC_DIGITS);
        assertResult(result, 6, 1);

        result = ByteSources.findLastOf(str, LINGUISTIC_DIGITS);
        assertResult(result, 7, 5);

        result = ByteSources.findLastOf(str, ALL_DIGITS);
        assertResult(result, 7, 5);
    }
}
