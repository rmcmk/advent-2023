// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { BaseAdventTest } from "./BaseAdventTest.sol";
import { Bytes } from "src/Bytes.sol";
import { console2 } from "forge-std/console2.sol";
import { Math } from "src/Math.sol";
import { Slice, ByteBuffer, ByteSequence, AccessMode, ExpansionMode } from "src/ByteBuffer.sol";

struct Card {
    uint256 id;
    uint256 matches;
    uint256 value;
    uint8[] winning;
    uint8[] picks;
}

contract Day04Test is BaseAdventTest {
    using ByteSequence for ByteBuffer;
    using Bytes for bytes1;

    Card[] cards;

    function parseInput(ByteBuffer[] memory lines) private {
        for (uint256 i = 0; i < lines.length; i++) {
            ByteBuffer memory buffer = lines[i];

            // skips card header information e.g "Card   1: "
            // we don't need to parse this we can compute the id from the index
            buffer = buffer.sliceFrom(buffer.safeIndexOf(":") + 2);

            uint256 gameId = i + 1;
            (uint8[] memory winning, uint8[] memory picks) = parseCards(buffer);
            (uint256 matches, uint256 value) = calculateValue(winning, picks);

            cards.push(Card(gameId, matches, value, winning, picks));
        }
    }

    function parseCards(ByteBuffer memory buffer) private pure returns (uint8[] memory winning, uint8[] memory picks) {
        ByteBuffer[] memory sets = buffer.splitAndTrim("|");
        winning = parseSet(sets[0]);
        picks = parseSet(sets[1]);
    }

    function parseSet(ByteBuffer memory buffer) private pure returns (uint8[] memory set) {
        ByteBuffer[] memory numbersBuffer = buffer.splitAndTrim(" ");
        set = new uint8[](numbersBuffer.length);
        for (uint256 i = 0; i < numbersBuffer.length; i++) {
            set[i] = numbersBuffer[i].takeUint8();
        }
    }

    function calculateValue(uint8[] memory winning, uint8[] memory picks)
        private
        pure
        returns (uint256 matches, uint256 value)
    {
        for (uint256 i = 0; i < winning.length; i++) {
            for (uint256 j = 0; j < picks.length; j++) {
                if (winning[i] == picks[j]) {
                    matches++;
                }
            }
        }
        if (matches > 0) {
            value = 1 << (matches - 1);
        }
    }

    function sumCardValues() private view returns (uint256 sum) {
        for (uint256 i = 0; i < cards.length; i++) {
            sum += cards[i].value;
        }
    }

    function sumCopies() private view returns (uint256 sum) {
        uint256[] memory copyCount = new uint256[](cards.length);
        for (uint256 i = 0; i < copyCount.length; i++) {
            copyCount[i] = 1;
        }

        for (uint256 i = 0; i < cards.length; i++) {
            Card memory card = cards[i];
            for (uint256 j = 0; j < card.matches; j++) {
                copyCount[i + j + 1] += copyCount[i];
            }
        }

        for (uint256 i = 0; i < copyCount.length; i++) {
            sum += copyCount[i];
        }
    }

    function test_s1() public {
        parseInput(readLines(SAMPLE1));

        assertEq(cards.length, 6);
        assertEq(cards[0].id, 1);

        assertEq(cards[0].value, 8, "Card 1 has four winning numbers (48, 83, 17, and 86), so it is worth 8 points.");
        assertEq(cards[1].value, 2, "Card 2 has two winning numbers (32 and 61), so it is worth 2 points.");
        assertEq(cards[2].value, 2, "Card 3 has two winning numbers (1 and 21), so it is worth 2 points.");
        assertEq(cards[3].value, 1, "Card 4 has one winning number (84), so it is worth 1 point.");
        assertEq(cards[4].value, 0, "Card 5 has no winning numbers, so it is worth no points.");
        assertEq(cards[5].value, 0, "Card 6 has no winning numbers, so it is worth no points.");

        assertEq(cards[0].matches, 4, "Card 1 has four winning numbers (48, 83, 17, and 86).");
        assertEq(cards[1].matches, 2, "Card 2 has two winning numbers (32 and 61).");
        assertEq(cards[2].matches, 2, "Card 3 has two winning numbers (1 and 21).");
        assertEq(cards[3].matches, 1, "Card 4 has one winning number (84).");
        assertEq(cards[4].matches, 0, "Card 5 has no winning numbers.");
        assertEq(cards[5].matches, 0, "Card 6 has no winning numbers.");

        assertEq(sumCardValues(), 13, "In total, these cards are worth 13 points.");
    }

    function test_p1() public {
        parseInput(readLines(PART1));
        assertEq(sumCardValues(), 21_558);
    }

    function test_s2() public {
        parseInput(readLines(SAMPLE2));
        assertEq(sumCopies(), 30);
    }

    function test_p2() public {
        parseInput(readLines(PART2));
        assertEq(sumCopies(), 10_425_665);
    }

    function day() internal pure override returns (uint8) {
        return 4;
    }
}
