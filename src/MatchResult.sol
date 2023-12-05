// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { ByteSource } from "./ByteSource.sol";

struct MatchResult {
    ByteSource slice;
    uint256 startIndex;
    uint256 length;
}

library MatchResults {
    function isValid(MatchResult memory result) internal pure returns (bool) {
        return result.length > 0 && result.length == result.slice.data.length;
    }
}
