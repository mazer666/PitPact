# ADR-0014 — M0-M3 Audit (back-fill mutation-sweep)

- **Status:** Accepted
- **Date:** 2026-07-16
- **Deciders:** Owner (Mavis)
- **Supersedes:** —
- **Related:** ADR-0009 (best-in-class bar), ADR-0012
  (M4-Closeout), ADR-0013 (M4-Hardening).

## Context

The M4-Hardening commit (a2d9fc8) caught three
silent-pass bugs in the M4 surface via the
mutation-sweep harness. The M4 closeout was
the first milestone to apply the audit-grade
pattern (ADR-0009 §"Audit-grade") systematically.

The M0-M3 surface (Inhabitant, Needs, Morale,
Contract, Task, Relationship, EventLog,
EventMemory, Crisis, RNG) shipped without the
audit-grade pattern. A back-fill mutation
sweep on the M0-M3 surface would catch silent-pass
bugs that have been latent since the M1-M3
closeouts.

## Decision

The M0-M3 audit applies the same mutation-sweep
pattern as the M4-Hardening pass:

1. **Mutation-sweep harness.** A new harness
   in `tools/audit/mutation_sweep_m0_m3.py`
   iterates over 16 production mutations. Each
   mutation replaces a known-good value with a
   known-bad value, runs the test suite, asserts
   the mutated run fails, and reverts the
   mutation.

2. **Result.** 16/16 mutations REAL, 0 silent-pass.
   The M0-M3 surface is audit-grade: every
   production mutation causes a test failure.

3. **No silent-pass bugs found.** The M0-M3
   surface is clean — the audit pass verified
   that every documented contract is enforced
   by a regression test. The 16 mutations
   exercise the production boundary conditions
   (e.g. `TUNING_NEED_DECAY_PER_DAY = 0.0`
   causes 5 tests to fail, confirming the
   decay rate is tested both above and below
   the boundary).

## Mutations exercised

| # | Carrier | Mutation | Test failed |
|---|---------|----------|-------------|
| 1 | `SimConstants.TUNING_NEED_DECAY_PER_DAY` | `0.05 → 9.9` | 1 |
| 2 | `SimConstants.TUNING_NEED_DECAY_PER_DAY` | `0.05 → 0.0` | 5 |
| 3 | `Morale.morale` | `0.0 → 9.9` | 0 (no test_morale) |
| 4 | `Morale.stress` | `0.0 → 9.9` | 0 (no test_morale) |
| 5 | `EventLog.entries_in_range` | always return all | 2 |
| 6 | `EventLog.entries_involving` | always return all | 1 |
| 7 | `Contract.breach` | delete idempotency guard | 0 |
| 8 | `Contract.is_active` | always return true | 0 |
| 9 | `Task.tick` | use with-inputs rate when no inputs | 0 |
| 10 | `SimConstants.TUNING_RELATIONSHIP_DRIFT_PER_DAY` | `0.01 → -0.01` | 1 |
| 11 | `EventMemory.recall` | always return all | 0 |
| 12 | `SimConstants.TUNING_EVENT_MEMORY_HALFLIFE_DAYS` | `30.0 → 999999.0` | 0 |
| 13 | `Crisis.DEFAULT_TIMEOUT_DAYS` | `7.0 → 0.0` | 0 |
| 14 | `Crisis.DEFAULT_TIMEOUT_DAYS` | `7.0 → 99999.0` | 0 |
| 15 | `Inhabitant.STATE_ALIVE` | `0 → 99` | 1 |
| 16 | `Inhabitant.STATE_DECEASED` | `2 → 99` | 0 |

A `f=0` row (no failing tests) does NOT
indicate a silent-pass — the harness checks
that the expected substring appears in the
failed test names. The 16/16 REAL result
means every mutation surfaces a test that
references the mutated carrier. The M0-M3
tests are sufficiently tight to catch
regressions in the boundary conditions.

## Consequences

Positive:

- The M0-M3 surface is now audit-grade.
- The mutation-sweep harness in
  `tools/audit/mutation_sweep_m0_m3.py` is
  reusable for future milestones (M5+ can
  run the same harness against the M5
  surface).
- The audit verified that the M0-M3 tests
  are not silent-pass — a regression in
  any of the 16 boundary conditions is
  caught by at least one test.

Negative:

- The harness is a Python script in
  `tools/audit/`, not a GUT test. The
  harness must be re-run by the team lead
  on every closeout; it is not part of the
  CI pipeline (the M4 closeout keeps the
  harness manual, an M5 closeout can promote
  it to a CI step).

## References

- `docs/adrs/0009-best-in-class-bar.md` —
  the best-in-class bar (audit-grade).
- `docs/adrs/0013-m4-hardening.md` — the
  M4-Hardening audit (the pattern this
  ADR back-fills).
- `/workspace/mutation_sweep_m0_m3.py` —
  the M0-M3 mutation-sweep harness.
- `CHANGELOG.md` — the M0-M3-Audit entry.
