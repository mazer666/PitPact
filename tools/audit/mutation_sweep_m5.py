#!/usr/bin/env python3
"""M5-Foundation mutation-sweep: verify the M5
PlayableShell + UI asserts are real.

Mirrors the M0-M3 and M4 sweeps: mutate a
known-good value, run tests, assert failure.
"""

import os
import re
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent.parent
GODOT_BIN = "/usr/local/bin/godot"

MUTATIONS = [
    {
        "name": "PlayableShell SEED 4242 -> 9999",
        "path": REPO / "src/ui/playable_shell.gd",
        "find_str": "const SEED: int = 4242",
        "replace_str": "const SEED: int = 9999  # NEG_TEST",
        "expected_to_fail": "test_playable_shell",
    },
    {
        "name": "PlayableShell _VERSION 0.1.0-m5-foundation -> 9.9.9-bad",
        "path": REPO / "src/ui/playable_shell.gd",
        "find_str": "const _VERSION: String = \"0.1.0-m5-foundation\"",
        "replace_str": "const _VERSION: String = \"9.9.9-bad\"  # NEG_TEST",
        "expected_to_fail": "test_playable_shell",
    },
    {
        "name": "PlayableShell DEFAULT_DIFFICULTY 1 (BALANCED) -> 99",
        "path": REPO / "src/ui/playable_shell.gd",
        "find_str": "const DEFAULT_DIFFICULTY: int = 1",
        "replace_str": "const DEFAULT_DIFFICULTY: int = 99  # NEG_TEST",
        "expected_to_fail": "test_playable_shell",
    },
    {
        "name": "PlayableShell WORLD_W 24 -> 99",
        "path": REPO / "src/ui/playable_shell.gd",
        "find_str": "const WORLD_W: int = 24",
        "replace_str": "const WORLD_W: int = 99  # NEG_TEST",
        "expected_to_fail": "test_playable_shell",
    },
    {
        "name": "PlayableShell REALM_ANCHOR (12,12) -> (1,1)",
        "path": REPO / "src/ui/playable_shell.gd",
        "find_str": "const REALM_ANCHOR: Vector2i = Vector2i(12, 12)",
        "replace_str": "const REALM_ANCHOR: Vector2i = Vector2i(1, 1)  # NEG_TEST",
        "expected_to_fail": "test_playable_shell",
    },
    {
        "name": "PlayableShell TICKS 30 -> 999",
        "path": REPO / "src/ui/playable_shell.gd",
        "find_str": "const TICKS: int = 30",
        "replace_str": "const TICKS: int = 999  # NEG_TEST",
        "expected_to_fail": "test_playable_shell",
    },
    {
        "name": "PlayableShellUI AUTO_TICK_INTERVAL 1.0 -> 9999.0",
        "path": REPO / "src/ui/playable_shell_ui.gd",
        "find_str": "const AUTO_TICK_INTERVAL: float = 1.0",
        "replace_str": "const AUTO_TICK_INTERVAL: float = 9999.0  # NEG_TEST",
        "expected_to_fail": "test_playable_shell_ui",
    },
]


def run_tests():
    env = os.environ.copy()
    env["GODOT_SILENCE_ROOT_WARNING"] = "1"
    result = subprocess.run(
        [GODOT_BIN, "--headless", "--path", str(REPO),
         "-s", "res://addons/gut/gut_cmdln.gd",
         "-gdir=res://tests/integration,res://tests/unit,res://tests/_smoke",
         "-gprefix=test_", "-gsuffix=.gd", "-gexit"],
        env=env, capture_output=True, text=True, timeout=120,
    )
    return result.stdout + result.stderr


def parse(output):
    p = re.search(r"Passing\s+(\d+)", output)
    f = re.search(r"Failing\s+(\d+)", output)
    failed = re.findall(r"\*\s+(test_\w+)", output)
    return (int(p.group(1)) if p else 0, int(f.group(1)) if f else 0, failed)


def main():
    if not Path(GODOT_BIN).exists():
        print(f"ERROR: {GODOT_BIN} not found")
        return 1
    print("=== M5-Foundation Mutation-Sweep ===\n")
    real = 0
    silent = 0
    skipped = 0
    for i, m in enumerate(MUTATIONS, 1):
        path = m["path"]
        if not path.exists():
            print(f"[{i:2d}] SKIP: {m['name']} (no file)")
            skipped += 1
            continue
        orig = path.read_text()
        if m["find_str"] not in orig:
            print(f"[{i:2d}] SKIP: {m['name']} (no string match)")
            skipped += 1
            continue
        new = orig.replace(m["find_str"], m["replace_str"], 1)
        path.write_text(new)
        try:
            out = run_tests()
            p, f, failed = parse(out)
            expected_substr = m["expected_to_fail"]
            ok = any(expected_substr in t for t in failed)
            tag = "REAL" if ok else "SILENT"
            print(f"[{i:2d}] {tag:6s} (p={p} f={f}): {m['name']}")
            if ok:
                real += 1
            else:
                silent += 1
        except Exception as e:
            print(f"[{i:2d}] ERR: {m['name']} -- {e}")
        finally:
            path.write_text(orig)
    print(f"\nReal: {real}  Silent: {silent}  Skipped: {skipped}")
    return 0 if silent == 0 else 2


if __name__ == "__main__":
    sys.exit(main())
