// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { BaseAdventTest } from "./BaseAdventTest.sol";
import { console2 } from "forge-std/console2.sol";
import { Slice, ByteBuffer, ByteSequence, AccessMode, ExpansionMode } from "src/ByteBuffer.sol";

contract Day01Test is BaseAdventTest {
    using ByteSequence for ByteBuffer;

    bytes[] private LINGUISTIC_DIGITS;
    bytes[] private NUMERIC_DIGITS;
    bytes[] private ALL_DIGITS;
    mapping(bytes => bytes1) private LINGUISTIC_TRANSLATION_TABLE;

    function pushTranslation(string memory key, string memory digit) private {
        bytes memory keyBytes = bytes(key);
        bytes memory digitBytes = bytes(digit);
        require(digitBytes.length == 1, "Digit must be a single byte");

        LINGUISTIC_TRANSLATION_TABLE[keyBytes] = digitBytes[0];
        LINGUISTIC_DIGITS.push(keyBytes);
        NUMERIC_DIGITS.push(digitBytes);
        ALL_DIGITS.push(keyBytes);
        ALL_DIGITS.push(digitBytes);
    }

    function translate(ByteBuffer memory buffer) private view returns (bytes1 translation) {
        if (buffer.getLength() == 1) {
            return buffer.peekFirst();
        }

        translation = LINGUISTIC_TRANSLATION_TABLE[buffer.takeBytes()];
        require(translation.length > 0, "No translation found");
    }

    function parseCalibrationValue(ByteBuffer memory buffer, bytes[] memory digits) private view returns (uint256) {
        Slice memory firstDigit = buffer.findFirstOf(digits);
        Slice memory lastDigit = buffer.findLastOf(digits);

        return ByteSequence.fromBytes(abi.encodePacked(translate(firstDigit.content), translate(lastDigit.content)))
            .takeUint256();
    }

    function sumCalibrationValues(string memory file, bytes[] memory digits) private returns (uint256 sum) {
        ByteBuffer[] memory lines = readLines(file);
        for (uint256 i = 0; i < lines.length; i++) {
            sum += parseCalibrationValue(lines[i], digits);
        }
    }

    function setUp() public {
        pushTranslation("one", "1");
        pushTranslation("two", "2");
        pushTranslation("three", "3");
        pushTranslation("four", "4");
        pushTranslation("five", "5");
        pushTranslation("six", "6");
        pushTranslation("seven", "7");
        pushTranslation("eight", "8");
        pushTranslation("nine", "9");
    }

    function test_s1() public {
        assertEq(142, sumCalibrationValues(SAMPLE1, NUMERIC_DIGITS));
    }

    function test_p1() public {
        assertEq(55_108, sumCalibrationValues(PART1, NUMERIC_DIGITS));
    }

    function test_s2() public {
        assertEq(281, sumCalibrationValues(SAMPLE2, ALL_DIGITS));
    }

    function test_p2() public {
        assertEq(56_324, sumCalibrationValues(PART2, ALL_DIGITS));
    }

    function day() internal pure override returns (uint8) {
        return 1;
    }
}
