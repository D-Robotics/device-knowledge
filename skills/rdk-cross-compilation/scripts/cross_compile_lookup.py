#!/usr/bin/env python3
"""Map an RDK board to its cross-compilation parameters.

Answers the recurring question "which build script / TROS distro / toolchain
do I use for cross-compiling to board X?" deterministically, so Claude doesn't
have to recite the table from memory (and risk drifting on, e.g., S600=Jazzy
vs Humble, or S600 using s100_build.sh).

Usage:
    python3 cross_compile_lookup.py s600
    python3 cross_compile_lookup.py            # prints the whole table

Source of truth: the `robot_dev_config` repo (aarch64_toolchainfile.cmake,
x5_build.sh, s100_build.sh, all_build.sh, rdkultra_build.sh) and the
toolchain file server at archive.d-robotics.cc/toolchain/. Keep this in sync
with SKILL.md's cheat-sheet if the official mapping ever changes.
"""
from __future__ import annotations

import sys

# board key -> (display name, target arch, TROS distro, TROS path, toolchain, build script)
BOARDS = {
    "x3":    ("RDK X3",    "aarch64", "Humble",   "/opt/tros/humble", "gcc-arm-11.2", "all_build.sh"),
    "x5":    ("RDK X5",    "aarch64", "Humble",   "/opt/tros/humble", "gcc-arm-11.2", "x5_build.sh"),
    "ultra": ("RDK Ultra", "aarch64", "Foxy/Humble", "/opt/tros/foxy or /humble", "gcc-arm-11.2", "rdkultra_build.sh"),
    "s100":  ("RDK S100",  "aarch64", "Humble",   "/opt/tros/humble", "gcc-arm-11.2", "s100_build.sh"),
    "s100p": ("RDK S100P", "aarch64", "Humble",   "/opt/tros/humble", "gcc-arm-11.2", "s100_build.sh"),
    "s600":  ("RDK S600",  "aarch64", "Jazzy",    "/opt/tros/jazzy",  "gcc-arm-11.2", "s100_build.sh"),
}

# common ways a user / probe string might name the board -> canonical key
ALIASES = {
    "sunrise3": "x3", "xj3": "x3", "j3": "x3",
    "sunrise5": "x5", "rdkx5": "x5",
    "rdkultra": "ultra",
    "super100": "s100", "rdks100": "s100",
    "super100p": "s100p", "rdks100p": "s100p",
    "rdks600": "s600",
}

FIELDS = ["board", "target_arch", "tros_distro", "tros_path", "toolchain", "build_script"]


def normalize(raw: str) -> str | None:
    key = raw.strip().lower().replace("rdk_", "").replace("rdk-", "").replace(" ", "").replace("_", "")
    if key in BOARDS:
        return key
    return ALIASES.get(key)


def show(key: str) -> None:
    row = BOARDS[key]
    print(f"# {row[0]}")
    for field, value in zip(FIELDS, row):
        print(f"  {field:14s}: {value}")
    note = "The cross-compiler runs on an x86 Linux host. The build script lives in " \
           "robot_dev_config. The toolchain file (aarch64_toolchainfile.cmake) is shared " \
           "across all boards — board specificity comes from the build script + TROS distro."
    if "Jazzy" in row[2]:
        note += f" ⚠️ {row[0]} uses Jazzy (not Humble) — build a Jazzy sysroot Docker."
    print(f"  note            : {note}")


def show_all() -> None:
    print(f"{'board':12s} {'arch':10s} {'tros':12s} {'path':24s} {'toolchain':14s} {'build_script':20s}")
    print("-" * 96)
    for row in BOARDS.values():
        print(f"{row[0]:12s} {row[1]:10s} {row[2]:12s} {row[3]:24s} {row[4]:14s} {row[5]:20s}")


def main() -> int:
    if len(sys.argv) < 2:
        show_all()
        return 0
    key = normalize(sys.argv[1])
    if key is None:
        print(f"Unknown board: {sys.argv[1]!r}. Known: {', '.join(BOARDS)}", file=sys.stderr)
        return 1
    show(key)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
