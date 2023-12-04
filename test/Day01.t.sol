// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { BaseAdventTest } from "./BaseAdventTest.sol";
import { console2 } from "forge-std/console2.sol";
import { Source, Sources } from "src/Source.sol";
import { MatchResult } from "src/MatchResult.sol";

contract Day01Test is BaseAdventTest {
    using Sources for Source;

    bytes[] private LINGUISTIC_DIGITS;
    bytes[] private NUMERIC_DIGITS;
    bytes[] private ALL_DIGITS;
    mapping(bytes => bytes) private LINGUISTIC_TRANSLATION_TABLE;

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

    function pushTranslation(string memory key, string memory digit) private {
        bytes memory keyBytes = bytes(key);
        bytes memory digitBytes = bytes(digit);
        LINGUISTIC_TRANSLATION_TABLE[keyBytes] = digitBytes;
        LINGUISTIC_DIGITS.push(keyBytes);
        NUMERIC_DIGITS.push(digitBytes);
        ALL_DIGITS.push(keyBytes);
        ALL_DIGITS.push(digitBytes);
    }

    function translate(Source memory source) private view returns (bytes memory translation) {
        bytes memory data = source.data;
        if (data.length == 1) {
            return data;
        }

        translation = LINGUISTIC_TRANSLATION_TABLE[data];
        require(translation.length > 0, "No translation found");
    }

    function test_s1() public {
        assertEq(142, parseCalibrationValues(SAMPLE1, NUMERIC_DIGITS));
    }

    function test_p1() public {
        assertEq(55_108, parseCalibrationValues(PART1, NUMERIC_DIGITS));
    }

    function test_s2() public {
        assertEq(281, parseCalibrationValues(SAMPLE2, ALL_DIGITS));
    }

    function test_p2() public {
        assertEq(56_324, parseCalibrationValues(PART2, ALL_DIGITS));
    }

    function parseCalibrationValues(string memory file, bytes[] memory digits) internal returns (uint256 sum) {
        Source[] memory lines = readLines(file);
        for (uint256 i = 0; i < lines.length; i++) {
            sum += parseCalibrationValue(lines[i], digits);
        }
        console2.log(string(abi.encodePacked("[", file, "]: Calibration Value: ", vm.toString(sum))));
    }

    function parseCalibrationValue(Source memory source, bytes[] memory digits) private view returns (uint256) {
        MatchResult memory firstMatch = source.findFirstOf(digits);
        MatchResult memory secondMatch = source.findLastOf(digits);
        return vm.parseUint(string(abi.encodePacked(translate(firstMatch.slice), translate(secondMatch.slice))));
    }

    function day() internal pure override returns (uint8) {
        return 1;
    }
}
