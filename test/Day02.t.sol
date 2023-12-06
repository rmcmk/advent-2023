// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { BaseAdventTest } from "./BaseAdventTest.sol";
import { Strings } from "src/Strings.sol";
import { Slice, ByteBuffer, ByteSequence, AccessMode, ExpansionMode } from "src/ByteBuffer.sol";

struct Game {
    uint256 id;
    Peek[] peeks;
}

struct Peek {
    string color;
    uint8 value;
}

contract Day02Test is BaseAdventTest {
    using ByteSequence for ByteBuffer;
    using Strings for string;

    string constant RED = "red";
    string constant GREEN = "green";
    string constant BLUE = "blue";

    uint256 totalGames;
    mapping(uint256 => Game) games;
    mapping(string => uint8) private minimums;

    constructor() {
        minimums[RED] = 12;
        minimums[GREEN] = 13;
        minimums[BLUE] = 14;
    }

    function parseGames(ByteBuffer[] memory lines) private {
        totalGames = lines.length;
        for (uint256 i = 0; i < lines.length; i++) {
            ByteBuffer memory buffer = lines[i];

            // skips game header information e.g "Game 1: "
            // we don't need to parse this we can compute the id from the index
            buffer = buffer.sliceFrom(buffer.safeIndexOf(":") + 2);

            uint256 id = i + 1;
            Game storage game = games[id];
            game.id = id;

            parsePeekGroups(buffer, game);
        }
    }

    function parsePeekGroups(ByteBuffer memory line, Game storage game) private {
        ByteBuffer[] memory peekGroups = line.splitAndTrim(";");
        for (uint256 j = 0; j < peekGroups.length; j++) {
            parsePeeks(peekGroups[j], game);
        }
    }

    function parsePeeks(ByteBuffer memory peekGroup, Game storage game) private {
        ByteBuffer[] memory peeks = peekGroup.splitAndTrim(",");
        for (uint256 k = 0; k < peeks.length; k++) {
            parsePeek(peeks[k], game);
        }
    }

    function parsePeek(ByteBuffer memory peek, Game storage game) private {
        ByteBuffer[] memory parts = peek.splitAndTrim(" ");
        uint8 value = parts[0].takeUint8();
        string memory color = parts[1].takeString();
        game.peeks.push(Peek(color, value));
    }

    function calculatePower(Peek[] memory peeks) private pure returns (uint256) {
        uint256 minR;
        uint256 minG;
        uint256 minB;

        for (uint256 i = 0; i < peeks.length; i++) {
            Peek memory peek = peeks[i];
            string memory color = peek.color;

            if (peek.value > minR && color.equals(RED)) {
                minR = peek.value;
            } else if (peek.value > minG && color.equals(GREEN)) {
                minG = peek.value;
            } else if (peek.value > minB && color.equals(BLUE)) {
                minB = peek.value;
            }
        }

        return minR * minG * minB;
    }

    function findValidGames() private view returns (uint256 count) {
        for (uint8 i = 1; i <= totalGames; i++) {
            Game storage game = games[i];
            if (isValidGame(game)) {
                count += game.id;
            }
        }
    }

    function isValidGame(Game storage game) private view returns (bool) {
        for (uint256 j = 0; j < game.peeks.length; j++) {
            if (!isValidPeek(game.peeks[j])) {
                return false;
            }
        }
        return true;
    }

    function isValidPeek(Peek memory peek) private view returns (bool) {
        return peek.value <= minimums[peek.color];
    }

    function findPower() private view returns (uint256 power) {
        for (uint8 i = 1; i <= totalGames; i++) {
            power += calculatePower(games[i].peeks);
        }
    }

    function test_s1() public {
        parseGames(readLines(SAMPLE1));
        assertEq(8, findValidGames());
    }

    function test_p1() public {
        parseGames(readLines(PART1));
        assertEq(2716, findValidGames());
    }

    function test_s2() public {
        parseGames(readLines(SAMPLE2));

        assertEq(48, calculatePower(games[1].peeks));
        assertEq(12, calculatePower(games[2].peeks));
        assertEq(1560, calculatePower(games[3].peeks));
        assertEq(630, calculatePower(games[4].peeks));
        assertEq(36, calculatePower(games[5].peeks));
        assertEq(2286, findPower());
    }

    function test_p2() public {
        parseGames(readLines(PART2));
        assertEq(72_227, findPower());
    }

    function day() internal pure override returns (uint8) {
        return 2;
    }
}
