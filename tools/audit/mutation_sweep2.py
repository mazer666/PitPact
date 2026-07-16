#!/usr/bin/env python3
"""M4-Closeout edge-case mutation-sweep."""

import os
import re
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent.parent
GODOT_BIN = "/usr/local/bin/godot"

MUTATIONS = [
    {
        "name": "KnowledgeState prereqs_met always true",
        "path": REPO / "src/sim/knowledge_state.gd",
        "find": re.compile(r'(func prereqs_met\(state: KnowledgeState\) -> bool:[\s\S]*?return true)'),
        "replace": r"\1  # NEG_TEST",
        "expected_to_fail": "test_knowledge_state_register_research_enforces_prereqs",
    },
    {
        "name": "Settings auto_resolve_days 7 -> 99",
        "path": REPO / "src/sim/settings.gd",
        "find": re.compile(r'(auto_resolve_days: int = )7'),
        "replace": r"\g<1>99",
        "expected_to_fail": "test_settings_round_trip",
    },
    {
        "name": "KnowledgeState tick ignores negative delta (delete early return)",
        "path": REPO / "src/sim/knowledge_state.gd",
        "find": re.compile(r'(if delta_days <= 0\.0:\s*\n\s*return)'),
        "replace": r"# NEG_TEST: \1",
        "expected_to_fail": "test_knowledge_state_register_ritual_consumes_days",
    },
    {
        "name": "M4SimStep update_factions drift is 0",
        "path": REPO / "src/sim/m4_sim_step.gd",
        "find": re.compile(r'(var drift: float = )0\.01'),
        "replace": r"\g<1>0.0",
        "expected_to_fail": "test_sim_step_7d_advances_faction_stance",
    },
    {
        "name": "M4Pactmaker seal_breach effect returns false always",
        "path": REPO / "src/content/m4_pactmaker.gd",
        "find": re.compile(r'(static func _effect_seal_breach\(sim: Variant, _time_days: float\) -> bool:\s*\n\s*if sim == null:\s*\n\s*return false\s*\n\s*if sim\.crises == null:\s*\n\s*return false)'),
        "replace": r"\1\n\treturn false  # NEG_TEST",
        "expected_to_fail": "test_pactmaker_apply_power_invokes_effect",
    },
    {
        "name": "Crisis autonomous_resolve no default (no choice picked)",
        "path": REPO / "src/sim/crisis.gd",
        "find": re.compile(r'(if bool\(\(c as Dictionary\)\.get\("is_default", false\)\):\s*\n\s*pick = StringName\(String\(\(c as Dictionary\)\.get\("id", &""\)\)\)\s*\n\s*break)'),
        "replace": r"# NEG_TEST: \1",
        "expected_to_fail": "test_crisis_autonomous_resolution_after_deadline",
    },
    {
        "name": "Crisis is_autonomous_deadline_reached ignores paused (delete gate)",
        "path": REPO / "src/sim/crisis.gd",
        "find": re.compile(r'(if autonomous_outcome == &"paused":\s*\n\s*return false)'),
        "replace": r"# NEG_TEST: \1",
        "expected_to_fail": "test_crisis_paused_skips_autonomous_resolution",
    },
    {
        "name": "KnowledgeState register_research accepts rituals (delete ritual gate)",
        "path": REPO / "src/sim/knowledge_state.gd",
        "find": re.compile(r'(if node\.kind == ResearchNode\.KIND_RITUAL:\s*\n\s*return false\s*\n\s*return node\.prereqs_met\(self\))'),
        "replace": r"return true  # NEG_TEST: ritual gate deleted",
        "expected_to_fail": "test_knowledge_state_register_research_rejects_rituals",
    },
    {
        "name": "Pactmaker register_intervention always true",
        "path": REPO / "src/sim/pactmaker.gd",
        "find": re.compile(r'(func register_intervention\(\) -> bool:\s*\n\s*if not can_intervene\(\):\s*\n\s*return false\s*\n\s*intervention_count \+= 1\s*\n\s*return true)'),
        "replace": r"return true  # NEG_TEST: gate deleted",
        "expected_to_fail": "test_pactmaker_register_intervention_debits_counter",
    },
    {
        "name": "Faction update_stance does not clamp",
        "path": REPO / "src/sim/faction.gd",
        "find": re.compile(r'(var new_val: int = clampi\(current \+ delta, STANCE_MIN, STANCE_MAX\))'),
        "replace": r"var new_val: int = current + delta  # NEG_TEST: clamp deleted",
        "expected_to_fail": "test_faction_update_stance_clamps_to_range",
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
    failed = re.findall(r"\*\s+(test_\w+)", output)
    return (int(p.group(1)) if p else 0, int(f.group(1)) if f else 0, failed)


def main():
    if not Path(GODOT_BIN).exists():
        print(f"ERROR: {GODOT_BIN} not found")
        return 1
    print("=== M4-Closeout Edge-Case Mutation-Sweep ===\n")
    real = 0
    silent = 0
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
                print(f"        failed: {failed}")
        except Exception as e:
            print(f"[{i:2d}] ERR: {m['name']} -- {e}")
        finally:
            path.write_text(orig)
    print(f"\nReal: {real}  Silent: {silent}")
    return 0 if silent == 0 else 2


if __name__ == "__main__":
    sys.exit(main())
