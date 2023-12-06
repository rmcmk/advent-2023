// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library Math {
    /// @notice Efficiently calculates the number of figures in a number.
    /// @dev e.g 10000 -> 5, 1000 -> 4, 100 -> 3, 10 -> 2, 1 -> 1
    function figures(uint256 value) public pure returns (uint256 count) {
        assembly {
            switch lt(value, 10)
            case 1 { count := 1 }
            // Handle easy case, 0-9 is 1 figure
            default {
                for { } gt(value, 0) { } {
                    value := div(value, 10)
                    count := add(count, 1)
                }
            }
        }
        return count;
    }

    function max(uint256 a, uint256 b) public pure returns (uint256) {
        return a > b ? a : b;
    }
}
