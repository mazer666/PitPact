# ADR-0009 — Best-in-class bar for `main` contributions

* **Status:** accepted
* **Date:** 2026-07-15
* **Deciders:** Mavis (team lead, on behalf of the user); the user is the
  final reviewer.

## Context and problem statement

The M3-Closeout commit was declared "green" by the team based on a
fast read of the GUT summary line ("100/100 passing"). An independent
re-read of the smoke test a few hours later surfaced a silent-pass
bug: the M3 smoke test called `world.biome_count()` on a
`WorldMap` that had no such method, the GDScript runtime raised a
"Nonexistent function" error, the `assert_true` expression evaluated
to `null`, and the test was counted as passing. The same re-read
surfaced four more issues of the same shape (an anchor that did not
record an event-log entry, a `terminal_effect` schema that was
defined but never applied, an exploration step that the smoke test
documented but did not exercise, and a `next_float` in the
`SplitMix64` PRNG that produced values in `[-0.5, 0.0)` because
GDScript's signed `int` parser silently clamps the unsigned
`0xFFFFFFFFFFFFF800` literal to `INT64_MAX`).

The pattern is not "a few bugs" — it is "the closeout gate accepts
silent-pass tests as long as the run completes". A closeout that
accepts silent-pass tests is not best in class; it is "best we could
verify in the time we had". The M3-Closeout's silent-pass test
would have shipped, the user's saves would have desynchronised, and
the M3 milestone would have been re-opened in M4.

§16 and §17 of `docs/requirements.md` make the ADR practice
explicit: "Architecture Decision Record (ADR) … when they affect
contributor workflow." This ADR affects contributor workflow: it
defines the gate that every closeout must clear.

We need a written bar for what "best in class" means in this
project, with concrete checks, so a future contributor or AI
assistant can apply it without re-litigating the principle.

## Decision

Every commit on `main` must clear the **best-in-class bar**,
defined as the union of:

1. **Architecture-grade.** The change honours the relevant ADRs, the
   module-boundary check
   (`tools/check_module_dependencies.sh`), and the ADR-driven
   determinism contract. A change that papers over a missing ADR is
   *not* best in class; the ADR is written first.

2. **Test-grade.** The change ships tests that fail before the fix
   and pass after. A test that *looks* green but silently no-ops
   (e.g. a missing method call that the test harness swallows) is
   *not* a passing test; the reviewer must run the test with a
   deliberate seed failure first, then with the fix, and observe
   the diff in the assertion count.

3. **Documentation-grade.** `README.md`, `docs/roadmap.md`,
   `CHANGELOG.md`, the relevant ADRs, and the module-level READMEs
   are updated in the same commit as the code that makes them
   stale. A documentation drift that survives a milestone closeout
   is *not* best in class.

4. **Local-quality-grade.** `./tools/run_quality.sh` is green on the
   integrated whole. A test run that passes on a single file but
   fails the full suite is *not* a green light.

5. **Content-grade.** Every new public symbol has a `class_name`, a
   docstring, and a `## ` block on every member; every
   user-visible string is externalised to
   `locales/source_strings.csv` and translated in both `en.po`
   and `de.po`; every data schema is documented in
   `docs/data-schema.md` and the schema is
   save-format-versioned.

6. **Audit-grade.** The milestone closeout is reviewed
   independently by the team lead *before* the closeout commit
   lands. The audit enumerates every test, every ADR, every doc
   claim and verifies them; a "all green" report without an
   explicit per-bucket check is *not* an audit.

The bar is the bar. If a commit cannot meet it, the commit is
split, the missing piece is shipped first, and the closeout is
retried. The user (a senior product owner) is the final reviewer;
the team lead does not declare best in class on the team's
behalf.

## Mechanics

The bar lives in `AGENTS.md` as the "Best-in-class principle"
section. Every closeout commit's commit message and CHANGELOG
entry must reference the six buckets by name. The independent
review happens in the same session as the closeout; the team
lead re-runs the smoke test, reads the smoke test's source
character-by-character, and verifies every `assert_*` actually
fires (the M3-Closeout audit re-derived each assert from the
data flow: `world.biome_count()` → `WorldMap.biome_counts.size()`,
then added the `biome_count()` method to `WorldMap` because the
method was missing on the M3-Closeout commit).

The audit produces a numbered list of findings; each finding
is either fixed in the same audit commit or carried forward as
a follow-up with a "Befund #N" tag in the CHANGELOG.

## Decision drivers

- §16 of `docs/requirements.md` (technical architecture) — the
  project must be reproducible, deterministic, and auditable.
- §17 of `docs/requirements.md` (data schemas) — the schemas
  are the contract between modules; a schema change that is
  not documented is a contract violation.
- The M3-Closeout silent-pass bug (described in the Context
  above) — the gate that accepted the bug is the gate we are
  changing.

## Considered alternatives

1. **Status quo: trust the GUT summary line.** Rejected. The
   silent-pass bug shipped exactly this way; the gate that
   produced it is the gate we are replacing.

2. **Per-line code review by a second human before every
   closeout.** Rejected as the *only* gate. The project is
   small enough that a single team lead can perform the
   audit, and the audit's mechanical checks (re-run the
   smoke test, derive each assert from the data flow,
   verify externalisation) are automatable. A second human
   is welcome on top of the audit; the audit is the floor.

3. **A formal "best in class" badge that contributors earn.**
   Rejected as ceremony. The bar is a check on the commit,
   not a recognition system. Recognition is in the
   `CREDITS.md` and the in-game codicils.

## Consequences

Positive:

- A closeout that ships is auditable; the audit log is the
  `CHANGELOG.md` "Hardened" entry per milestone.
- Silent-pass tests are caught at closeout time, not after a
  user reports a desync.
- The bar is reproducible: any future contributor can read
  `AGENTS.md` and apply it without re-litigating.

Negative:

- The audit is a real cost: the M3-Closeout hardening commit
  took an extra session. We accept this cost; the alternative
  is shipping bugs and re-opening milestones.
- The bar is local to this project. A future contributor
  joining a different codebase will not have this gate; we
  document the principle in `AGENTS.md` so the principle
  travels, not the gate.

## See also

- [`AGENTS.md`](../AGENTS.md) — the bar's "Best-in-class
  principle" section is the canonical human-readable
  restatement.
- [`CHANGELOG.md`](../CHANGELOG.md) — the M3-Closeout
  "Hardened" entry is the first audit log.
- [`docs/code-style.md`](../docs/code-style.md) — the
  best-in-class bar's "best in class" line at the top of the
  guide.
