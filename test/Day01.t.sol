// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { BaseAdventTest } from "./BaseAdventTest.sol";
import { console2 } from "forge-std/console2.sol";
import { ByteSource, ByteSources } from "src/ByteSource.sol";
import { MatchResult } from "src/MatchResult.sol";

contract Day01Test is BaseAdventTest {
    using ByteSources for ByteSource;

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

    function translate(ByteSource memory source) private view returns (bytes1 translation) {
        bytes memory data = source.data;
        if (data.length == 1) {
            return data[0];
        }

        translation = LINGUISTIC_TRANSLATION_TABLE[data];
        require(translation.length > 0, "No translation found");
    }

    function parseCalibrationValue(ByteSource memory source, bytes[] memory digits) private view returns (uint256) {
        MatchResult memory firstDigit = source.findFirstOf(digits);
        MatchResult memory lastDigit = source.findLastOf(digits);
        ByteSource memory translated = ByteSources.empty();
        translated.writeByte(translate(firstDigit.slice));
        translated.writeByte(translate(lastDigit.slice));

        // TODO: We don't have read/write cursors yet, so we need to reset the cursor to 0 before reading
        translated.cursor = 0;
        return translated.parseUint();
    }

    function sumCalibrationValues(string memory file, bytes[] memory digits) private returns (uint256 sum) {
        ByteSource[] memory lines = readLines(file);
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
