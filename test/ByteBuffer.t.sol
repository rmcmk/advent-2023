// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";
import { VmSafe } from "forge-std/Vm.sol";
import { console2 } from "forge-std/console2.sol";

import { Slice, ByteSequence, ByteBuffer, AccessMode, ExpansionMode } from "src/ByteBuffer.sol";

/// @title ByteBufferTest - Super simple test to ensure that the library works as expected before we use it in the puzzle
contract ByteBufferTest is Test {
    using ByteSequence for ByteBuffer;

    bytes[] private ALL_DIGITS;

    bytes[] private NUMERIC_DIGITS =
        [bytes("1"), bytes("2"), bytes("3"), bytes("4"), bytes("5"), bytes("6"), bytes("7"), bytes("8"), bytes("9")];

    bytes[] private LINGUISTIC_DIGITS = [
        bytes("one"),
        bytes("two"),
        bytes("three"),
        bytes("four"),
        bytes("five"),
        bytes("six"),
        bytes("seven"),
        bytes("eight"),
        bytes("nine")
    ];

    function setUp() public {
        for (uint256 i = 0; i < NUMERIC_DIGITS.length; i++) {
            ALL_DIGITS.push(NUMERIC_DIGITS[i]);
            ALL_DIGITS.push(LINGUISTIC_DIGITS[i]);
        }
    }

    function assertSlice(Slice memory slice, uint256 relativeStartIndex, uint256 length) private {
        assertEq(slice.relativeStartIndex, relativeStartIndex, "relativeStartIndex");
        assertEq(slice.length, length, "length");
    }

    function test_fromString() public {
        ByteBuffer memory buffer = ByteSequence.fromString("Hello World");
        assertEq(uint8(buffer.accessMode), uint8(AccessMode.R), "access mode");
        assertEq(uint8(buffer.expansionMode), uint8(ExpansionMode.Default), "expansion mode");
        assertEq(buffer.data.length, 11, "data.length");
        assertEq(buffer.readIndex, 0, "readIndex");
        assertEq(buffer.writeIndex, 0, "writeIndex");
        assertEq(buffer.getLength(), 11, "getLength");
        assertEq(buffer.readableBytes(), 11, "readableBytes");
        assertEq(buffer.takeString(), "Hello World", "toString");
        assertTrue(buffer.hasReadMode(), "hasReadMode");
        assertFalse(buffer.hasWriteMode(), "hasWriteMode");
        assertTrue(buffer.isReadable(), "isReadable");
        assertFalse(buffer.isWritable(), "isWritable");
        assertEq(0, buffer.writableBytes(), "writableBytes");
    }

    function test_read_1() public {
        ByteBuffer memory buffer = ByteSequence.fromString("123456789");
        assertBytes1Eq(buffer.readBytes1(), bytes1("1"));
        assertBytes1Eq(buffer.readBytes1(), bytes1("2"));
        assertBytes1Eq(buffer.readBytes1(), bytes1("3"));
        assertBytes1Eq(buffer.readBytes1(), bytes1("4"));
        assertBytes1Eq(buffer.readBytes1(), bytes1("5"));
        assertBytes1Eq(buffer.readBytes1(), bytes1("6"));
        assertBytes1Eq(buffer.readBytes1(), bytes1("7"));
        assertBytes1Eq(buffer.readBytes1(), bytes1("8"));
        assertBytes1Eq(buffer.readBytes1(), bytes1("9"));

        vm.expectRevert("Not enough readable bytes");
        buffer.readBytes1();
    }

    function test_read_2() public {
        string memory path = "./inputs/1/sample1.txt";
        assertTrue(vm.exists(path));

        VmSafe.FsMetadata memory metadata = vm.fsMetadata(path);
        assertTrue(!metadata.isDir);
        assertTrue(metadata.length > 0);

        ByteBuffer memory buffer = ByteSequence.fromString(vm.readFile(path));
        ByteBuffer[] memory lines = buffer.toLines();

        assertEq(lines.length, 4);
        assertEq(lines[0].data, "1abc2");
        assertEq(lines[1].data, "pqr3stu8vwx");
        assertEq(lines[2].data, "a1b2c3d4e5f");
        assertEq(lines[3].data, "treb7uchet");
    }

    function test_split_1() public {
        ByteBuffer memory buffer = ByteSequence.fromString("1 abc 2");
        ByteBuffer[] memory splits = buffer.split(" ");
        assertEq(splits.length, 3);
        assertEq(splits[0].data, "1");
        assertEq(splits[1].data, "abc");
        assertEq(splits[2].data, "2");
    }

    function test_split_2() public {
        ByteBuffer memory buffer = ByteSequence.fromString("1;abc;2");
        ByteBuffer[] memory splits = buffer.split(";");
        assertEq(splits.length, 3);
        assertEq(splits[0].data, "1");
        assertEq(splits[1].data, "abc");
        assertEq(splits[2].data, "2");
    }

    function test_split_3() public {
        ByteBuffer memory buffer = ByteSequence.fromString("Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green");

        buffer.skipReader(5); // Skip `Game `
        assertEq(buffer.takeString(), "1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green");

        uint8 id = buffer.readByte().takeUint8();
        assertEq(id, 1);

        buffer.skipReader(2); // Skip `: `
        assertEq(buffer.takeString(), "3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green");

        ByteBuffer[] memory splits = buffer.split(";");
        assertEq(splits.length, 3);
        assertEq(splits[0].takeString(), "3 blue, 4 red");
        assertEq(splits[1].takeString(), " 1 red, 2 green, 6 blue");
        assertEq(splits[2].takeString(), " 2 green");

        ByteBuffer[] memory peeks = splits[0].split(",");
        assertEq(peeks.length, 2);
        assertEq(peeks[0].takeString(), "3 blue");
        assertEq(peeks[1].takeString(), " 4 red");

        peeks = splits[1].split(",");
        assertEq(peeks.length, 3);
        assertEq(peeks[0].takeString(), " 1 red");
        assertEq(peeks[1].takeString(), " 2 green");
        assertEq(peeks[2].takeString(), " 6 blue");

        peeks = splits[2].split(",");
        assertEq(peeks.length, 1);
        assertEq(peeks[0].takeString(), " 2 green");
    }

    function test_split_4() public {
        ByteBuffer memory buffer = ByteSequence.fromString("Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green");

        buffer.skipReader(5); // Skip `Game `
        assertEq(buffer.takeString(), "1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green");

        uint8 id = buffer.readByte().takeUint8();
        assertEq(id, 1);

        buffer.skipReader(2); // Skip `: `
        assertEq(buffer.takeString(), "3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green");

        ByteBuffer[] memory splits = buffer.splitAndTrim(";");
        assertEq(splits.length, 3);
        assertEq(splits[0].takeString(), "3 blue, 4 red");
        assertEq(splits[1].takeString(), "1 red, 2 green, 6 blue");
        assertEq(splits[2].takeString(), "2 green");

        ByteBuffer[] memory peeks = splits[0].splitAndTrim(",");
        assertEq(peeks.length, 2);
        assertEq(peeks[0].takeString(), "3 blue");
        assertEq(peeks[1].takeString(), "4 red");

        peeks = splits[1].splitAndTrim(",");
        assertEq(peeks.length, 3);
        assertEq(peeks[0].takeString(), "1 red");
        assertEq(peeks[1].takeString(), "2 green");
        assertEq(peeks[2].takeString(), "6 blue");

        peeks = splits[2].splitAndTrim(",");
        assertEq(peeks.length, 1);
        assertEq(peeks[0].takeString(), "2 green");
    }

    function test_trim_1() public {
        // Test with only whitespace characters
        assertEq(ByteSequence.fromString(" \t\n\r").trim().takeString(), "");

        // Test with empty string
        assertEq(ByteSequence.fromString("").trim().takeString(), "");

        // Test with a string that contains only one character
        assertEq(ByteSequence.fromString("a").trim().takeString(), "a");

        // Test with multiple spaces at the beginning and end
        assertEq(ByteSequence.fromString("  1 abc 2  ").trim().takeString(), "1 abc 2");

        // Test with multiple tabs at the beginning and end
        assertEq(ByteSequence.fromString("\t\t1 abc 2\t\t").trim().takeString(), "1 abc 2");

        // Test with multiple line feeds at the beginning and end
        assertEq(ByteSequence.fromString("\n\n1 abc 2\n\n").trim().takeString(), "1 abc 2");

        // Test with multiple carriage returns at the beginning and end
        assertEq(ByteSequence.fromString("\r\r1 abc 2\r\r").trim().takeString(), "1 abc 2");

        // Test with a mix of whitespace characters at the beginning and end
        assertEq(ByteSequence.fromString(" \t\n\r1 abc 2\r\n\t ").trim().takeString(), "1 abc 2");

        // Test with a single space at the beginning and end
        assertEq(ByteSequence.fromString(" 1 abc 2 ").trim().takeString(), "1 abc 2");

        // Test with a single space at the beginning
        assertEq(ByteSequence.fromString(" 1 abc 2").trim().takeString(), "1 abc 2");

        // Test with a single space at the end
        assertEq(ByteSequence.fromString("1 abc 2 ").trim().takeString(), "1 abc 2");

        // Test with an already trimmed string
        assertEq(ByteSequence.fromString("1 abc 2").trim().takeString(), "1 abc 2");

        // Test with excessive whitespace characters all around
        assertEq(ByteSequence.fromString("    1     a    b    c 2    ").trim().takeString(), "1     a    b    c 2");
    }

    function test_trim_2() public {
        assertEq(ByteSequence.fromString("\r\n1 abc 2\r\n").trim().takeString(), "1 abc 2");
        assertEq(ByteSequence.fromString("\r\n1 abc 2").trim().takeString(), "1 abc 2");
        assertEq(ByteSequence.fromString("1 abc 2\r\n").trim().takeString(), "1 abc 2");

        assertEq(ByteSequence.fromString("\n\r1 abc 2\n\r").trim().takeString(), "1 abc 2");
        assertEq(ByteSequence.fromString("\n\r1 abc 2").trim().takeString(), "1 abc 2");
        assertEq(ByteSequence.fromString("1 abc 2\n\r").trim().takeString(), "1 abc 2");

        assertEq(ByteSequence.fromString("1 abc\t\t\t\t\t\t 2 ").trim().takeString(), "1 abc\t\t\t\t\t\t 2");

        assertEq(
            ByteSequence.fromString("\t\n\r    1     a    \n\nb    c 2    \n\n\t\r  \n\r\t").trim().takeString(),
            "1     a    \n\nb    c 2"
        );

        assertEq(ByteSequence.fromString("\n\n\n\n\n\n1 abc 2 ").trim().takeString(), "1 abc 2");
        assertEq(ByteSequence.fromString("\t\t\t\t\t\t1 abc 2").trim().takeString(), "1 abc 2");
        assertEq(ByteSequence.fromString("\n\n\n\n\n\n1 abc 2\t\t\t\t\t\t").trim().takeString(), "1 abc 2");
        assertEq(ByteSequence.fromString("\t\t\t\t\t\t1 abc 2\n\n\n\n\n\n").trim().takeString(), "1 abc 2");
        assertEq(ByteSequence.fromString("\n\n\n\n\n\n1 abc 2\n\n\n\n\n\n").trim().takeString(), "1 abc 2");
        assertEq(ByteSequence.fromString("\t\t\t\t\t\t1 abc 2\t\t\t\t\t\t").trim().takeString(), "1 abc 2");
    }

    function assertBytes1Eq(bytes1 a, bytes1 b) private {
        assertEq(uint8(a), uint8(b));
    }

    function test_findFirstOf_1() public {
        ByteBuffer memory buffer = ByteSequence.fromString("123456789");
        Slice memory slice = buffer.findFirstOf(buffer.explodeBytes());
        assertSlice(slice, 0, 1);

        slice = buffer.findFirstOf(NUMERIC_DIGITS);
        assertSlice(slice, 0, 1);

        slice = buffer.findFirstOf(LINGUISTIC_DIGITS);
        assertSlice(slice, type(uint256).max, 0); // type(uint256).max,0 because we don't have any linguistic digits in the buffer

        slice = buffer.findFirstOf(ALL_DIGITS);
        assertSlice(slice, 0, 1);
    }

    function test_findFirstOf_2() public {
        ByteBuffer memory buffer = ByteSequence.fromString("onetwothreefourfivesixseveneightnine");
        Slice memory slice = buffer.findFirstOf(buffer.explodeBytes());
        assertSlice(slice, 0, 1);

        slice = buffer.findFirstOf(ALL_DIGITS);
        assertSlice(slice, 0, 3);

        slice = buffer.findFirstOf(LINGUISTIC_DIGITS);
        assertSlice(slice, 0, 3);

        slice = buffer.findFirstOf(NUMERIC_DIGITS);
        assertSlice(slice, type(uint256).max, 0); // 0,0 because we don't have any numeric digits in the buffer
    }

    function test_findFirstOf_3() public {
        ByteBuffer memory buffer = ByteSequence.fromString("3nmronemlqzfxgonepkh");
        Slice memory slice = buffer.findFirstOf(buffer.explodeBytes());
        assertSlice(slice, 0, 1);

        slice = buffer.findFirstOf(NUMERIC_DIGITS);
        assertSlice(slice, 0, 1);

        slice = buffer.findFirstOf(LINGUISTIC_DIGITS);
        assertSlice(slice, 4, 3);

        slice = buffer.findFirstOf(ALL_DIGITS);
        assertSlice(slice, 0, 1);
    }

    function test_findFirstOf_4() public {
        ByteBuffer memory buffer = ByteSequence.fromString("gsjgklneight6zqfz");
        Slice memory slice = buffer.findFirstOf(buffer.explodeBytes());
        assertSlice(slice, 0, 1);

        slice = buffer.findFirstOf(NUMERIC_DIGITS);
        assertSlice(slice, 12, 1);

        slice = buffer.findFirstOf(LINGUISTIC_DIGITS);
        assertSlice(slice, 7, 5);

        slice = buffer.findFirstOf(ALL_DIGITS);
        assertSlice(slice, 7, 5);
    }

    function test_findFirstOf_5() public {
        ByteBuffer memory buffer = ByteSequence.fromString("pqr3stu8vwx");
        Slice memory slice = buffer.findFirstOf(buffer.explodeBytes());
        assertSlice(slice, 0, 1);

        slice = buffer.findFirstOf(NUMERIC_DIGITS);
        assertSlice(slice, 3, 1);

        slice = buffer.findFirstOf(LINGUISTIC_DIGITS);
        assertSlice(slice, type(uint256).max, 0); // type(uint256).max,0 because we don't have any linguistic digits in the buffer

        slice = buffer.findFirstOf(ALL_DIGITS);
        assertSlice(slice, 3, 1);
    }

    function test_findFirstOf_6() public {
        ByteBuffer memory buffer = ByteSequence.fromString("abcone2threexyz");
        Slice memory slice = buffer.findFirstOf(buffer.explodeBytes());
        assertSlice(slice, 0, 1);

        slice = buffer.findFirstOf(NUMERIC_DIGITS);
        assertSlice(slice, 6, 1);

        slice = buffer.findFirstOf(LINGUISTIC_DIGITS);
        assertSlice(slice, 3, 3);

        slice = buffer.findFirstOf(ALL_DIGITS);
        assertSlice(slice, 3, 3);
    }

    function test_findLastOf_1() public {
        ByteBuffer memory buffer = ByteSequence.fromString("123456789");
        Slice memory slice = buffer.findLastOf(buffer.explodeBytes());
        assertSlice(slice, 8, 1);

        slice = buffer.findLastOf(NUMERIC_DIGITS);
        assertSlice(slice, 8, 1);

        slice = buffer.findLastOf(LINGUISTIC_DIGITS);
        assertSlice(slice, 0, 0); // 0,0 because we don't have any linguistic digits in the buffer

        slice = buffer.findLastOf(ALL_DIGITS);
        assertSlice(slice, 8, 1);
    }

    function test_findLastOf_2() public {
        ByteBuffer memory buffer = ByteSequence.fromString("onetwothreefourfivesixseveneightnine");
        Slice memory slice = buffer.findLastOf(buffer.explodeBytes());
        assertSlice(slice, 35, 1);

        slice = buffer.findLastOf(ALL_DIGITS);
        assertSlice(slice, 32, 4);

        slice = buffer.findLastOf(LINGUISTIC_DIGITS);
        assertSlice(slice, 32, 4);

        slice = buffer.findLastOf(NUMERIC_DIGITS);
        assertSlice(slice, 0, 0); // 0,0 because we don't have any numeric digits in the buffer
    }

    function test_findLastOf_3() public {
        ByteBuffer memory buffer = ByteSequence.fromString("3nmronemlqzfxgonepkh");
        Slice memory slice = buffer.findLastOf(buffer.explodeBytes());
        assertSlice(slice, 19, 1);

        slice = buffer.findLastOf(NUMERIC_DIGITS);
        assertSlice(slice, 0, 1);

        slice = buffer.findLastOf(LINGUISTIC_DIGITS);
        assertSlice(slice, 14, 3);

        slice = buffer.findLastOf(ALL_DIGITS);
        assertSlice(slice, 14, 3);
    }

    function test_findLastOf_4() public {
        ByteBuffer memory buffer = ByteSequence.fromString("gsjgklneight6zqfz");
        Slice memory slice = buffer.findLastOf(buffer.explodeBytes());
        assertSlice(slice, 16, 1);

        slice = buffer.findLastOf(NUMERIC_DIGITS);
        assertSlice(slice, 12, 1);

        slice = buffer.findLastOf(LINGUISTIC_DIGITS);
        assertSlice(slice, 7, 5);

        slice = buffer.findLastOf(ALL_DIGITS);
        assertSlice(slice, 12, 1);
    }

    function test_findLastOf_5() public {
        ByteBuffer memory buffer = ByteSequence.fromString("pqr3stu8vwx");
        Slice memory slice = buffer.findLastOf(buffer.explodeBytes());
        assertSlice(slice, 10, 1);

        slice = buffer.findLastOf(NUMERIC_DIGITS);
        assertSlice(slice, 7, 1);

        slice = buffer.findLastOf(LINGUISTIC_DIGITS);
        assertSlice(slice, 0, 0); // 0,0 because we don't have any linguistic digits in the buffer

        slice = buffer.findLastOf(ALL_DIGITS);
        assertSlice(slice, 7, 1);
    }

    function test_findLastOf_6() public {
        ByteBuffer memory buffer = ByteSequence.fromString("abcone2threexyz");
        Slice memory slice = buffer.findLastOf(buffer.explodeBytes());
        assertSlice(slice, 14, 1);

        slice = buffer.findLastOf(NUMERIC_DIGITS);
        assertSlice(slice, 6, 1);

        slice = buffer.findLastOf(LINGUISTIC_DIGITS);
        assertSlice(slice, 7, 5);

        slice = buffer.findLastOf(ALL_DIGITS);
        assertSlice(slice, 7, 5);
    }
}
