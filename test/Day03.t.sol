// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { BaseAdventTest } from "./BaseAdventTest.sol";
import { ByteSource, ByteSources } from "src/ByteSource.sol";
import { Bytes } from "src/Bytes.sol";
import { console2 } from "forge-std/console2.sol";
import { Vm } from "forge-std/Vm.sol";

struct Symbol {
    uint256 x;
    uint256 y;
    bytes1 value;
}

struct Number {
    uint256 x;
    uint256 y;
    uint256 offsetX;
    uint256 partNumber;
}

contract Day03Test is BaseAdventTest {
    using ByteSources for ByteSource;
    using Bytes for bytes1;

    uint256 constant MAXIMUM_ADJACENT_PART_NUMBERS = 2;

    bytes1 constant DEFAULT_VALUE = bytes1(0);
    bytes1 constant GEAR_SYMBOL = bytes1("*");
    ByteSource VALID_SYMBOLS = ByteSources.fromString("*#&@$+-%/=");

    bytes1[][] matrix;
    Number[] numbers;
    Symbol[] symbols;

    function init(bytes1[][] memory _matrix) private {
        matrix = _matrix;

        for (uint256 y = 0; y < matrix.length; y++) {
            bytes1[] memory row = matrix[y];
            for (uint256 x = 0; x < row.length; x++) {
                uint256 offsetX = parsePoint(x, y, row[x]);
                if (offsetX > 0) {
                    x += offsetX - 1; // We need to skip ahead by the amount of digits we parsed, minus one since we'll increment `x` in the loop
                }
            }
        }
    }

    function getOrDefault(uint256 x, uint256 y) private view returns (bytes1) {
        if (y >= matrix.length) {
            return DEFAULT_VALUE;
        }
        bytes1[] memory row = matrix[y];
        if (x >= row.length) {
            return DEFAULT_VALUE;
        }
        return row[x];
    }

    function isAdjacentTo(uint256 x1, uint256 y1, uint256 x2, uint256 y2) private pure returns (bool) {
        unchecked {
            int256 deltaX = int256(x2 - x1);
            int256 deltaY = int256(y2 - y1);
            return (deltaX >= -1 && deltaX <= 1) && (deltaY >= -1 && deltaY <= 1);
        }
    }

    function isAdjacentTo(uint256 x1, uint256 y1, uint256 x2, uint256 y2, uint256 offsetX)
        private
        pure
        returns (bool)
    {
        return isAdjacentTo(x1, y1, x2, y2) || isAdjacentTo(x1, y1, x2 + offsetX - 1, y2);
    }

    function isAdjacentToAnySymbol(Number memory number) private view returns (bool) {
        for (uint256 i = 0; i < symbols.length; i++) {
            Symbol memory symbol = symbols[i];
            if (isAdjacentTo(symbol.x, symbol.y, number.x, number.y, number.offsetX)) {
                return true; // Return right away if we find a match, do not waste further gas
            }
        }
        return false;
    }

    function findGearRatio(Symbol memory symbol) private view returns (uint256 gearRatio) {
        uint8 adjacentCount = 0;
        uint256[MAXIMUM_ADJACENT_PART_NUMBERS] memory partNumbers;

        for (uint256 i = 0; i < numbers.length && adjacentCount < MAXIMUM_ADJACENT_PART_NUMBERS; i++) {
            Number memory number = numbers[i];
            if (isAdjacentTo(symbol.x, symbol.y, number.x, number.y, number.offsetX)) {
                partNumbers[adjacentCount++] = number.partNumber;

                if (adjacentCount == MAXIMUM_ADJACENT_PART_NUMBERS) {
                    gearRatio = partNumbers[0] * partNumbers[1];
                    return gearRatio;
                }
            }
        }
    }

    function parsePoint(uint256 x, uint256 y, bytes1 value) private returns (uint256 offsetX) {
        // If this value is a valid symbol, we'll add it to the list of symbols
        if (VALID_SYMBOLS.contains(value)) {
            symbols.push(Symbol(x, y, value));
        }

        // If this value is a digit, we need to figure out how many digits it is and parse it
        if (value.isDigit()) {
            ByteSource memory digits = ByteSources.empty();

            while (value.isDigit()) {
                digits.writeByte(value);

                // Use the byte length of `digits` as our x offset so we can continue parsing the number if it's more than one digit
                offsetX = digits.getLength();
                value = getOrDefault(x + offsetX, y);
            }

            // TODO: We don't have read/write cursors yet, so we need to reset the cursor to 0 before reading
            digits.cursor = 0;

            // Parse the amount of positions we stepped and our number
            uint256 number = digits.parseUint();
            numbers.push(Number(x, y, offsetX, number));
        }
    }

    function sumPartNumbers() private view returns (uint256 sum) {
        for (uint256 i = 0; i < numbers.length; i++) {
            if (isAdjacentToAnySymbol(numbers[i])) {
                sum += numbers[i].partNumber;
            }
        }
    }

    function sumGearRatios() private view returns (uint256 sum) {
        for (uint256 i = 0; i < symbols.length; i++) {
            Symbol memory symbol = symbols[i];
            if (symbol.value != GEAR_SYMBOL) {
                continue;
            }
            sum += findGearRatio(symbol);
        }
    }

    function test_s1() public {
        init(readBytes1Matrix(SAMPLE1));
        assertEq(4361, sumPartNumbers());
    }

    function test_p1() public {
        init(readBytes1Matrix(PART1));
        assertEq(528_819, sumPartNumbers());
    }

    function test_s2() public {
        init(readBytes1Matrix(SAMPLE2));
        assertEq(467_835, sumGearRatios());
    }

    function test_p2() public {
        init(readBytes1Matrix(PART2));
        assertEq(80_403_602, sumGearRatios());
    }

    function day() internal pure override returns (uint8) {
        return 3;
    }
}
