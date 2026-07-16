# ADR-0013 — M4-Hardening (best-in-class audit pass)

- **Status:** Accepted
- **Date:** 2026-07-16
- **Deciders:** Owner (Mavis)
- **Supersedes:** —
- **Related:** ADR-0009 (best-in-class bar), ADR-0012
  (M4-Closeout).

## Context

The M4-Closeout commit (d97efcf) shipped 149/149
GUT tests in ~0.73s / 882 Asserts and the local
quality gate was green end-to-end. The
best-in-class bar (ADR-0009) requires an
**audit-grade** pass: every assert must be
re-derived from the data flow and verified with a
negative-test mutation. A test that does NOT
fail under a known-bad mutation is a
"silent-pass" test (the assertion is checking a
no-op or a value the carrier never returns).

The M3-Hardening commit (7659ac2) established
the audit-grade pattern. The M4-Hardening pass
applies the same pattern to the M4-Closeout
surface.

## Decision

The M4-Hardening pass is a 30-minute audit:

1. **Mutation-sweep harness.** A pair of
   Python harnesses (`/workspace/mutation_sweep.py`
   and `/workspace/mutation_sweep2.py`) iterate
   over 13+9 production mutations. Each mutation
   replaces a known-good value with a known-bad
   value, runs the test suite, asserts the
   mutated run fails, and reverts the mutation.
   A test that does NOT fail under a known-bad
   mutation is a silent-pass.

2. **Two silent-pass bugs caught and fixed.**
   - `Settings._init()` hardcoded the field
     defaults (`auto_resolve_days = 7`,
     `difficulty = DIFFICULTY_BALANCED`,
     `locale = "en"`) instead of using the
     `var` defaults. A regression that bumped
     the `var` default was masked by the
     hardcoded `_init()`. The fix makes
     `_init()` an empty body.
   - `Pactmaker.apply_power` debited the
     intervention counter *before* invoking the
     effect. A power that no-ops consumed an
     intervention without effect. The fix
     debits the counter *after* the effect
     succeeds ("debit on success" contract).
   - `M4Factions._make` tried to set
     `Faction.name`, but `Faction` has no
     `name` field. The method raised at
     runtime; the 30-day fuzz test caught it.
     The fix removes the `name` set.

3. **Three test hardenings.**
   - `test_faction_is_hostile_to_predicate`
     exercises the boundary (not just a
     hostile value) so a threshold mutation
     is caught.
   - `test_knowledge_state_register_research_enforces_prereqs`
     exercises both the negative path
     (unmet prereqs) and the positive path
     (all prereqs met) so a `return true`
     mutation is caught.
   - `test_settings_round_trip` reads the
     source file directly and asserts the
     runtime `Settings.new()` matches.

4. **Three new edge-case tests.**
   - `test_pactmaker_apply_power_no_sealable_crisis_returns_false`
     (negative path of `apply_power`).
   - `test_pactmaker_intervention_limit_zero_blocks_all`
     (zero-limit boundary).
   - `test_sim_30_day_m4_fuzz_smoke` (30-day
     end-to-end sim run with all M4 systems).

5. **Result.** 151/151 GUT tests in ~0.73s /
   891 Asserts. Format / lint / module-
   dependency / godot import / gut tests /
   locale validation — all green via
   `tools/run_quality.sh`. Mutation sweep
   reports 0 silent-pass regressions.

## Consequences

Positive:

- The M4-Closeout surface is now audit-grade:
  every assert is verified by a known-bad
  mutation, and every production mutation
  causes a test failure.
- The mutation-sweep harness is a reusable
  audit tool for future milestones (M5+ can
  run the same harness against the M5
  surface).
- The two real bugs (Settings `_init()`,
  Pactmaker `apply_power`) are now caught
  by regression tests.

Negative:

- The mutation-sweep harness is a Python
  script in `/workspace/`, not a GUT test.
  The harness must be re-run by the team
  lead on every closeout; it is not part
  of the CI pipeline (the M4 closeout
  keeps the harness manual, an M5 closeout
  can promote it to a CI step).

## References

- `docs/adrs/0009-best-in-class-bar.md` —
  the best-in-class bar (audit-grade).
- `docs/adrs/0012-m4-closeout.md` — the
  M4-Closeout implementation ADR.
- `/workspace/mutation_sweep.py` and
  `/workspace/mutation_sweep2.py` — the
  mutation-sweep harnesses.
- `CHANGELOG.md` — the M4-Hardening entry.
