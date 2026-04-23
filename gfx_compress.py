#!/usr/bin/env python3
"""Compress raw graphics into ALTTP graphics-pack format.

This intentionally uses only the simpler command types:
0 = literal bytes
1 = repeated byte
2 = alternating 2-byte word
3 = incrementing byte sequence

That is enough to produce valid .gfx files for the paired assets in this repo
while staying inside the existing reserved ROM slots.
"""

from __future__ import annotations

import argparse
from pathlib import Path


MAX_CHUNK_LEN = 32
TERMINATOR = 0xFF


def emit_command(out: bytearray, command: int, length: int, payload: bytes) -> None:
    if not 1 <= length <= MAX_CHUNK_LEN:
        raise ValueError(f"invalid command length {length}")
    out.append((command << 5) | (length - 1))
    out.extend(payload)


def compress(data: bytes) -> bytes:
    out = bytearray()
    literal = bytearray()
    index = 0

    def flush_literal() -> None:
        nonlocal literal
        while literal:
            chunk = bytes(literal[:MAX_CHUNK_LEN])
            del literal[:MAX_CHUNK_LEN]
            emit_command(out, 0, len(chunk), chunk)

    while index < len(data):
        best_kind = None
        best_len = 0

        repeated_len = 1
        while (
            index + repeated_len < len(data)
            and repeated_len < MAX_CHUNK_LEN
            and data[index + repeated_len] == data[index]
        ):
            repeated_len += 1
        if repeated_len >= 2:
            best_kind = "repeat"
            best_len = repeated_len

        if index + 1 < len(data):
            first = data[index]
            second = data[index + 1]
            alternating_len = 0
            while index + alternating_len < len(data) and alternating_len < MAX_CHUNK_LEN:
                expected = first if alternating_len % 2 == 0 else second
                if data[index + alternating_len] != expected:
                    break
                alternating_len += 1
            if alternating_len >= 4 and alternating_len > best_len:
                best_kind = "alternating"
                best_len = alternating_len

        incrementing_len = 1
        start_value = data[index]
        while (
            index + incrementing_len < len(data)
            and incrementing_len < MAX_CHUNK_LEN
            and data[index + incrementing_len] == ((start_value + incrementing_len) & 0xFF)
        ):
            incrementing_len += 1
        if incrementing_len >= 3 and incrementing_len > best_len:
            best_kind = "incrementing"
            best_len = incrementing_len

        if best_kind is None:
            literal.append(data[index])
            index += 1
            if len(literal) == MAX_CHUNK_LEN:
                flush_literal()
            continue

        flush_literal()

        if best_kind == "repeat":
            emit_command(out, 1, best_len, bytes([data[index]]))
        elif best_kind == "alternating":
            emit_command(out, 2, best_len, data[index:index + 2])
        else:
            emit_command(out, 3, best_len, bytes([data[index]]))

        index += best_len

    flush_literal()
    out.append(TERMINATOR)
    return bytes(out)


def decompress(data: bytes) -> bytes:
    out = bytearray()
    index = 0

    while True:
        command_byte = data[index]
        index += 1

        if command_byte == TERMINATOR:
            return bytes(out)

        if (command_byte & 0xE0) == 0xE0:
            command = (command_byte >> 2) & 0x07
            length = (((command_byte & 0x03) << 8) | data[index]) + 1
            index += 1
        else:
            command = (command_byte >> 5) & 0x07
            length = (command_byte & 0x1F) + 1

        if command == 0:
            out.extend(data[index:index + length])
            index += length
            continue

        if command == 1:
            out.extend([data[index]] * length)
            index += 1
            continue

        if command == 2:
            first = data[index]
            second = data[index + 1]
            index += 2
            for offset in range(length):
                out.append(first if offset % 2 == 0 else second)
            continue

        if command == 3:
            value = data[index]
            index += 1
            for _ in range(length):
                out.append(value)
                value = (value + 1) & 0xFF
            continue

        raise ValueError(f"unsupported command {command}; this script only emits 0-3")


def parse_max_size(value: str) -> int:
    return int(value, 0)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input", type=Path, help="raw decompressed graphics file, usually .bin")
    parser.add_argument(
        "output",
        type=Path,
        nargs="?",
        help="output .gfx path; defaults to input path with .gfx suffix",
    )
    parser.add_argument(
        "--max-size",
        type=parse_max_size,
        help="fail if compressed size exceeds this value (accepts hex like 0x800)",
    )
    parser.add_argument(
        "--no-verify",
        action="store_true",
        help="skip decompressing the result to verify round-trip correctness",
    )
    args = parser.parse_args()

    input_path = args.input
    output_path = args.output or input_path.with_suffix(".gfx")

    raw = input_path.read_bytes()
    compressed = compress(raw)

    if not args.no_verify and decompress(compressed) != raw:
        raise RuntimeError("round-trip verification failed")

    if args.max_size is not None and len(compressed) > args.max_size:
        raise RuntimeError(
            f"compressed output is {len(compressed)} bytes, exceeds limit {args.max_size}"
        )

    output_path.write_bytes(compressed)
    print(
        f"{input_path.name}: {len(raw)} -> {len(compressed)} bytes "
        f"({len(raw) - len(compressed)} saved)"
    )
    print(f"wrote {output_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
