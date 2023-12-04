// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Source } from "./Source.sol";

struct MatchResult {
    Source slice;
    uint256 startIndex;
    uint256 length;
}

library MatchResults {
    function isValid(MatchResult memory result) internal pure returns (bool) {
        return result.length > 0 && result.length == result.slice.data.length;
    }
}
