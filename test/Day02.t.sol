// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { BaseAdventTest } from "./BaseAdventTest.sol";
import { console2 } from "forge-std/console2.sol";
import { ByteSource, ByteSources } from "src/ByteSource.sol";
import { MatchResult, MatchResults } from "src/MatchResult.sol";
import { Strings } from "src/Strings.sol";

struct Game {
    uint8 id;
    Peek[] peeks;
}

struct Peek {
    uint8 r;
    uint8 g;
    uint8 b;
}

contract Day02Test is BaseAdventTest {
    using MatchResults for MatchResult;
    using ByteSources for ByteSource;
    using Strings for string;

    uint8 constant P1_RED = 12;
    uint8 constant P1_GREEN = 13;
    uint8 constant P1_BLUE = 14;

    string constant RED = "red";
    string constant GREEN = "green";
    string constant BLUE = "blue";

    uint256 totalGames = 0;
    mapping(uint8 => Game) games;

    /// Samples:
    /// Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
    /// Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue
    /// Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red
    /// Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red
    /// Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green
    function parseGames(ByteSource[] memory lines) private {
        totalGames = lines.length;
        for (uint256 i = 0; i < lines.length; i++) {
            ByteSource memory line = lines[i];
            line.cursor += bytes("Game ").length; // Skip `Game `, useless data, we don't need it

            // Read all the bytes until `:` and convert it to a uint8
            uint8 id = uint8(vm.parseUint(line.readUntil(":").toString()));
            line.cursor += 2; // Skip the `: `

            // Read until the next ; or the remaining bytes if `;` cannot be found
            ByteSource memory peeksSource = line.readUntil(";");

            // Initialize a game for this line
            Game storage game = games[id];
            game.id = id;

            Peek memory peek = Peek(0, 0, 0);

            while (true) {
                ByteSource memory _count = peeksSource.readUntil(" ");
                uint8 count = uint8(vm.parseUint(_count.toString()));
                peeksSource.cursor++; // Skip the " " after "{count}"

                ByteSource memory _color = peeksSource.readUntil(",");
                peeksSource.cursor += 2; // Skip the ", " after "{color}"

                string memory color = _color.toString();
                if (color.equals(RED)) {
                    peek.r = count;
                } else if (color.equals(GREEN)) {
                    peek.g = count;
                } else if (color.equals(BLUE)) {
                    peek.b = count;
                }

                // If there are no more bytes to read in this peek source, we may need to revisit the line and read the next set of peeks.
                // If the line has no more readable bytes, we're done with this line.
                if (!peeksSource.isReadable()) {
                    // We have finished reading this peek, push it to the game and reset the peek
                    game.peeks.push(peek);
                    peek = Peek(0, 0, 0);

                    // Skip the "; " after the last peek (this should always be present)
                    line.cursor += 2;

                    // If we have a next peek, read until the next `;`, otherwise read the rest of the line
                    int256 nextPeek = line.indexOf(bytes1(";"));
                    if (nextPeek >= 0) {
                        peeksSource = line.readUntil(";");
                    } else {
                        if (line.isReadable()) {
                            peeksSource = line;
                        } else {
                            break;
                        }
                    }
                }
            }
        }
    }

    function calculatePower(Peek[] memory peeks) private pure returns (uint256) {
        uint8 minR = 0;
        uint8 minG = 0;
        uint8 minB = 0;

        for (uint256 i = 0; i < peeks.length; i++) {
            Peek memory peek = peeks[i];
            if (peek.r > minR) {
                minR = peek.r;
            }
            if (peek.g > minG) {
                minG = peek.g;
            }
            if (peek.b > minB) {
                minB = peek.b;
            }
        }

        return uint256(minR) * uint256(minG) * uint256(minB);
    }

    function findValidGames() private view returns (uint256 count) {
        for (uint8 i = 1; i <= totalGames; i++) {
            Game storage game = games[i];

            bool valid = true;
            for (uint256 j = 0; j < game.peeks.length; j++) {
                Peek memory peek = game.peeks[j];
                if (peek.r > P1_RED || peek.g > P1_GREEN || peek.b > P1_BLUE) {
                    valid = false;
                    break;
                }
            }

            if (valid) {
                count += game.id;
            }
        }
    }

    function findPower() private view returns (uint256 power) {
        for (uint8 i = 1; i <= totalGames; i++) {
            Game storage game = games[i];
            power += calculatePower(game.peeks);
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
