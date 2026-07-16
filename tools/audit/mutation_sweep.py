#!/usr/bin/env python3
"""M4-Closeout mutation-sweep."""

import os
import re
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent.parent
GODOT_BIN = "/usr/local/bin/godot"

MUTATIONS = [
    {
        "name": "M4Research size 6 -> 5 (delete binding_basics)",
        "path": REPO / "src/content/m4_research.gd",
        "find": re.compile(
            r'out\.append\(\s*\n\s*_make\(\s*\n\s*&"binding_basics"[\s\S]*?\)\s*\)',
            re.MULTILINE,
        ),
        "replace": "pass  # NEG_TEST",
        "expected_to_fail": "test_m4_research_catalogue_has_six_nodes",
    },
    {
        "name": "M4Rituals size 3 -> 2 (delete bind_inhabitant)",
        "path": REPO / "src/content/m4_rituals.gd",
        "find": re.compile(
            r'out\.append\(\s*\n\s*_make_ritual\(\s*\n\s*&"bind_inhabitant"[\s\S]*?\)\s*\)',
            re.MULTILINE,
        ),
        "replace": "pass  # NEG_TEST",
        "expected_to_fail": "test_m4_rituals_catalogue_has_three_nodes",
    },
    {
        "name": "M4Pactmaker powers 3 -> 2 (delete seal_breach)",
        "path": REPO / "src/content/m4_pactmaker.gd",
        "find": re.compile(
            r'out\.append\(_make_power\(&"seal_breach"[^)]*\)\)',
            re.MULTILINE,
        ),
        "replace": "pass  # NEG_TEST",
        "expected_to_fail": "test_m4_pactmaker_has_three_powers",
    },
    {
        "name": "M4Factions size 3 -> 2 (delete lantern_clan)",
        "path": REPO / "src/content/m4_factions.gd",
        "find": re.compile(
            r'out\.append\(_make\(&"lantern_clan"[^)]*\)\)',
            re.MULTILINE,
        ),
        "replace": "pass  # NEG_TEST",
        "expected_to_fail": "test_m4_factions_catalogue_has_three_factions",
    },
    {
        "name": "M4Crises size 2 -> 1 (delete faction_dispute)",
        "path": REPO / "src/content/m4_crises.gd",
        "find": re.compile(
            r'out\.append\(_faction_dispute\(\)\)',
            re.MULTILINE,
        ),
        "replace": "out.append(_plague_outbreak())  # NEG_TEST",
        "expected_to_fail": "test_m4_crises_catalogue_has_two_crises",
    },
    {
        "name": "Difficulty CRUEL research rate 0.5 -> 9.9",
        "path": REPO / "src/sim/difficulty.gd",
        "find": re.compile(r'(CRUEL:\s*\n\s*return\s*)0\.5'),
        "replace": r"\g<1>9.9",
        "expected_to_fail": "test_difficulty_multipliers_have_documented_values",
    },
    {
        "name": "Difficulty PEACEFUL morale delta 0.05 -> 9.9",
        "path": REPO / "src/sim/difficulty.gd",
        "find": re.compile(r'(PEACEFUL:\s*\n\s*return\s*)0\.05'),
        "replace": r"\g<1>9.9",
        "expected_to_fail": "test_difficulty_multipliers_have_documented_values",
    },
    {
        "name": "Difficulty CRUEL crisis chance 0.1 -> 9.9",
        "path": REPO / "src/sim/difficulty.gd",
        "find": re.compile(r'(CRUEL:\s*\n\s*return\s*)0\.1'),
        "replace": r"\g<1>9.9",
        "expected_to_fail": "test_difficulty_multipliers_have_documented_values",
    },
    {
        "name": "Crisis DEFAULT_AUTONOMOUS_RESOLUTION_DAYS 14.0 -> 1.0",
        "path": REPO / "src/sim/crisis.gd",
        "find": re.compile(r'(DEFAULT_AUTONOMOUS_RESOLUTION_DAYS:\s*float\s*=\s*)14\.0'),
        "replace": r"\g<1>1.0",
        "expected_to_fail": "test_sim_step_7e_resolves_autonomous_crisis",
    },
    {
        "name": "M4Pactmaker INTERVENTION_LIMIT_PER_YEAR 3 -> 99",
        "path": REPO / "src/content/m4_pactmaker.gd",
        "find": re.compile(r'(INTERVENTION_LIMIT_PER_YEAR:\s*int\s*=\s*)3'),
        "replace": r"\g<1>99",
        "expected_to_fail": "test_m4_pactmaker_has_three_powers",
    },
    {
        "name": "Settings DIFFICULTY_BALANCED = 1 -> 99",
        "path": REPO / "src/sim/settings.gd",
        "find": re.compile(r'(DIFFICULTY_BALANCED:\s*int\s*=\s*)1'),
        "replace": r"\g<1>99",
        "expected_to_fail": "test_settings_round_trip",
    },
    {
        "name": "Faction HOSTILE_THRESHOLD -50 -> 0",
        "path": REPO / "src/sim/faction.gd",
        "find": re.compile(r'(-50)'),
        "replace": "0",
        "expected_to_fail": "test_faction_is_hostile_to_predicate",
    },
    {
        "name": "KnowledgeState register_research prereqs_met revert (delete prereqs check)",
        "path": REPO / "src/sim/knowledge_state.gd",
        "find": re.compile(r'(if not node\.prereqs_met\(self\):\s*\n\s*return false\s*\n\s*)(if node\.kind == ResearchNode\.KIND_RITUAL:)'),
        "replace": r"\1# NEG: prereq check disabled\n\t\t\2",
        "expected_to_fail": "test_knowledge_state_register_research_enforces_prereqs",
    },
    {
        "name": "Crisis is_autonomous_deadline_reached always false",
        "path": REPO / "src/sim/crisis.gd",
        "find": re.compile(r'(return \(time_days - _triggered_at_day\) >= autonomous_resolution_days)'),
        "replace": r"\1 + 999999.0",
        "expected_to_fail": "test_sim_step_7e_resolves_autonomous_crisis",
    },
]


def run_tests():
    env = os.environ.copy()
    env["GODOT_SILENCE_ROOT_WARNING"] = "1"
    result = subprocess.run(
        [GODOT_BIN, "--headless", "--path", str(REPO),
         "-s", "res://addons/gut/gut_cmdln.gd",
         "-gdir=res://tests/integration", "-gprefix=test_", "-gsuffix=.gd", "-gexit"],
        env=env, capture_output=True, text=True, timeout=60,
    )
    return result.stdout + result.stderr


def parse(output):
    p = re.search(r"Passing\s+(\d+)", output)
    f = re.search(r"Failing\s+(\d+)", output)
    failed = re.findall(r"^\*\s+(\w+)", output, re.MULTILINE)
    return (int(p.group(1)) if p else 0, int(f.group(1)) if f else 0, failed)


def main():
    if not Path(GODOT_BIN).exists():
        print(f"ERROR: {GODOT_BIN} not found")
        return 1
    print("=== M4-Closeout Mutation-Sweep ===\n")
    real = 0
    silent = 0
    broken = 0
    for i, m in enumerate(MUTATIONS, 1):
        path = m["path"]
        if not path.exists():
            print(f"[{i:2d}] SKIP: {m['name']} (no file)")
            continue
        orig = path.read_text()
        new = m["find"].sub(m["replace"], orig, count=1)
        if new == orig:
            print(f"[{i:2d}] SKIP: {m['name']} (no regex match)")
            continue
        path.write_text(new)
        try:
            out = run_tests()
            p, f, failed = parse(out)
            ok = m["expected_to_fail"] in failed
            tag = "REAL" if ok else "SILENT"
            print(f"[{i:2d}] {tag:6s} (p={p} f={f}): {m['name']}")
            if ok:
                real += 1
            else:
                silent += 1
        except Exception as e:
            print(f"[{i:2d}] ERR: {m['name']} — {e}")
            broken += 1
        finally:
            path.write_text(orig)
    print(f"\nReal: {real}  Silent: {silent}  Broken: {broken}")
    return 0 if silent == 0 else 2


if __name__ == "__main__":
    sys.exit(main())
