#!/usr/bin/env python3
"""M0-M3 Mutation-Sweep: back-fill audit for the carriers
that pre-date the M4-Closeout.

Mirrors the M4 mutation-sweep harness (see
tools/audit/mutation_sweep.py): mutate a known-good
production value to a known-bad value, run the test
suite, assert the test fails.

A test that does NOT fail under a known-bad mutation
is a silent-pass. The M4-Hardening pass caught three
silent-pass bugs in the M4 surface; this harness
applies the same pattern to the M0-M3 surface.
"""

import os
import re
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent.parent
GODOT_BIN = "/usr/local/bin/godot"

# Each mutation: name, path, regex find, replace, expected test substring.
# `expected_to_fail` is matched as a substring against the failed test names;
# e.g. "needs_decay" matches "test_inhabitant_lifecycle_smoke".
MUTATIONS = [
    {
        "name": "Needs decay 0.05 -> 9.9 (impossibly fast)",
        "path": REPO / "src/sim/constants.gd",
        "find": re.compile(r"(TUNING_NEED_DECAY_PER_DAY:\s*float\s*=\s*)0\.05"),
        "replace": r"\g<1>9.9",
        "expected_to_fail": "needs_decay",
    },
    {
        "name": "Needs decay 0.05 -> 0.0 (no decay)",
        "path": REPO / "src/sim/constants.gd",
        "find": re.compile(r"(TUNING_NEED_DECAY_PER_DAY:\s*float\s*=\s*)0\.05"),
        "replace": r"\g<1>0.0",
        "expected_to_fail": "needs_decay",
    },
    {
        "name": "Morale default 0.0 -> 9.9 (maxed out at birth)",
        "path": REPO / "src/sim/morale.gd",
        "find": re.compile(r"(var\s+morale:\s*float\s*=\s*)0\.0"),
        "replace": r"\g<1>9.9",
        "expected_to_fail": "morale",
    },
    {
        "name": "Morale default stress 0.0 -> 9.9",
        "path": REPO / "src/sim/morale.gd",
        "find": re.compile(r"(var\s+stress:\s*float\s*=\s*)0\.0"),
        "replace": r"\g<1>9.9",
        "expected_to_fail": "morale",
    },
    {
        "name": "EventLog entries_in_range always returns all",
        "path": REPO / "src/sim/event_log.gd",
        "find": re.compile(r"(func entries_in_range\(from_day: float, to_day: float\) -> Array:\n\tvar out: Array = \[\]\n\tfor e in entries:)"),
        "replace": r"\g<1>\n\t\treturn entries.duplicate()  # NEG_TEST",
        "expected_to_fail": "event_log",
    },
    {
        "name": "EventLog entries_involving always returns all",
        "path": REPO / "src/sim/event_log.gd",
        "find_str": "func entries_involving(inhabitant_id: StringName) -> Array:",
        "replace_str": "func entries_involving(inhabitant_id: StringName) -> Array:\n\treturn entries.duplicate()  # NEG_TEST",
        "expected_to_fail": "event_log",
    },
    {
        "name": "Contract breach_idempotent guard deleted (re-breach allowed)",
        "path": REPO / "src/sim/contract.gd",
        "find": re.compile(r"(func breach\(time_days: float\) -> void:\n\tif breached:\n\t\treturn)"),
        "replace": r"# NEG: \1",
        "expected_to_fail": "contract",
    },
    {
        "name": "Contract is_active always true (ignore time window)",
        "path": REPO / "src/sim/contract.gd",
        "find_str": "if breached:\n\t\treturn false\n\treturn time_days >= 0.0",
        "replace_str": "if breached:\n\t\treturn false\n\treturn true  # NEG_TEST",
        "expected_to_fail": "contract",
    },
    {
        "name": "Task tick uses with-inputs rate when no inputs",
        "path": REPO / "src/sim/tasks.gd",
        "find_str": "rate = PROGRESS_PER_DAY_WITHOUT_INPUTS",
        "replace_str": "rate = PROGRESS_PER_DAY_WITH_INPUTS  # NEG_TEST",
        "expected_to_fail": "hearth",
    },
    {
        "name": "Relationship drift positive (always moves toward zero from below)",
        "path": REPO / "src/sim/constants.gd",
        "find_str": "TUNING_RELATIONSHIP_DRIFT_PER_DAY: float = 0.01",
        "replace_str": "TUNING_RELATIONSHIP_DRIFT_PER_DAY: float = -0.01  # NEG_TEST",
        "expected_to_fail": "branch",
    },
    {
        "name": "EventMemory recall ignores kind (return all)",
        "path": REPO / "src/sim/event_memory.gd",
        "find_str": "func recall(kind: StringName, current_day: float = INF) -> Array:",
        "replace_str": "func recall(kind: StringName, current_day: float = INF) -> Array:\n\treturn entries.duplicate()  # NEG_TEST",
        "expected_to_fail": "event_memory",
    },
    {
        "name": "EventMemory prune never removes (delete decay check)",
        "path": REPO / "src/sim/constants.gd",
        "find_str": "TUNING_EVENT_MEMORY_HALFLIFE_DAYS: float = 30.0",
        "replace_str": "TUNING_EVENT_MEMORY_HALFLIFE_DAYS: float = 999999.0  # NEG_TEST",
        "expected_to_fail": "event_memory",
    },
    {
        "name": "Crisis DEFAULT_TIMEOUT_DAYS 7.0 -> 0.0 (instant timeout)",
        "path": REPO / "src/sim/crisis.gd",
        "find": re.compile(r"(DEFAULT_TIMEOUT_DAYS:\s*float\s*=\s*)7\.0"),
        "replace": r"\g<1>0.0",
        "expected_to_fail": "crisis",
    },
    {
        "name": "Crisis DEFAULT_TIMEOUT_DAYS 7.0 -> 99999.0 (never timeout)",
        "path": REPO / "src/sim/crisis.gd",
        "find": re.compile(r"(DEFAULT_TIMEOUT_DAYS:\s*float\s*=\s*)7\.0"),
        "replace": r"\g<1>99999.0",
        "expected_to_fail": "crisis",
    },
    {
        "name": "Inhabitant STATE_ALIVE = 0 -> 99 (state mismatch)",
        "path": REPO / "src/sim/inhabitant.gd",
        "find_str": "STATE_ALIVE: int = 0",
        "replace_str": "STATE_ALIVE: int = 99  # NEG_TEST",
        "expected_to_fail": "inhabitant",
    },
    {
        "name": "Inhabitant STATE_DECEASED = 2 -> 99",
        "path": REPO / "src/sim/inhabitant.gd",
        "find_str": "STATE_DECEASED: int = 2",
        "replace_str": "STATE_DECEASED: int = 99  # NEG_TEST",
        "expected_to_fail": "inhabitant",
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
        env=env, capture_output=True, text=True, timeout=90,
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
    print("=== M0-M3 Mutation-Sweep ===\n")
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
        if "find_str" in m:
            if m["find_str"] not in orig:
                print(f"[{i:2d}] SKIP: {m['name']} (no string match)")
                skipped += 1
                continue
            new = orig.replace(m["find_str"], m["replace_str"], 1)
        else:
            new = m["find"].sub(m["replace"], orig, count=1)
            if new == orig:
                print(f"[{i:2d}] SKIP: {m['name']} (no regex match)")
                skipped += 1
                continue
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
