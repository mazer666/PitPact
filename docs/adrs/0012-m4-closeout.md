# ADR-0012 — M4-Closeout Implementation

- **Status:** Accepted
- **Date:** 2026-07-16
- **Deciders:** Owner (Mavis)
- **Supersedes:** —
- **Related:** ADR-0009 (best-in-class bar), ADR-0010
  (research-tree schema), ADR-0011 (autonomous
  conflict).

## Context

The M4-foundation commit (ADR-0010, ADR-0011) landed
the seven `src/sim/` skeletons (`KnowledgeState`,
`ResearchNode`, `Pactmaker`, `Power`, `Faction`,
`Settings`, `M4Skeleton`) and the 19-test
`test_m4_skeleton.gd` smoke test. The M4-Closeout
fills the four tracks (A: research/ritual
progression, B: Pactmaker powers + intervention
limits, C: two new crises + autonomous conflict,
D: difficulty + settings + locale) with concrete
implementations, content catalogues, and end-to-end
tests.

The M4-Closeout is held to the best-in-class bar
(ADR-0009): architecture-grade, test-grade,
documentation-grade, local-quality-grade,
content-grade, audit-grade.

## Decision

The M4-Closeout is implemented as four tracks
plus a hardening pass:

1. **Track A — Research + Ritual progression
   (ADR-0010 implementation).**
   - `KnowledgeState.register_research(node)` /
     `register_ritual(node)` /
     `cancel_research(id)` with the gate
     checks factored into `_can_register_research`
     and `_can_register_ritual` predicates (the
     predicates keep the public surface under
     gdlint's `max-returns` cap).
   - `KnowledgeState.tick(delta_days, sim)` —
     the per-tick rule (new step 7c) that advances
     active research / rituals by
     `delta_days * Difficulty.get_research_rate(...)`
     and emits the node's `effect` payload into
     `pending_effects` when the cost is met.
   - `KnowledgeState.node_lookup` —
     `Dictionary[StringName, ResearchNode]` the
     realm façade populates with the catalogue
     on boot.
   - `M4Research` — 6 research nodes in two
     trees (binding + survey, both
     `forest-of-roots` per ADR-0010).
   - `M4Rituals` — 3 rituals (`bind_inhabitant`,
     `survey_tile`, `seal_breach`).

2. **Track B — Pactmaker + powers + intervention
   limits.**
   - `Pactmaker.reset_yearly_count()` /
     `get_power(id)` /
     `apply_power(id, sim, time_days)`.
   - The `apply_power` method debits the
     intervention counter, refunds on cooldown,
     records the use, and invokes the power's
     `Callable` effect.
   - `M4Pactmaker.build()` — the canonical M4
     Pactmaker (`intervention_limit = 3`, three
     powers: `seal_breach`, `pause_crisis`,
     `reveal_tile`).
   - `M4Factions` — 3 factions (`lantern_clan`,
     `ledger_cabal`, `hollow_church`).

3. **Track C — Two new crises + autonomous
   conflict (ADR-0011 implementation).**
   - `Crisis.autonomous_resolution_days`
     (default `14.0`) —
     `is_autonomous_deadline_reached(t)` /
     `autonomous_resolve(t)` — the deadline
     predicate and the auto-resolve helper.
   - `Crisis._triggered_at_day` /
     `autonomous_outcome` /
     `data: Dictionary` — the per-crisis data
     carrier (`sealable: bool` /
     `pausable: bool`).
   - `M4Crises` — the two M4 default crises
     (`plague_outbreak`, `faction_dispute`).
   - `M4SimStep` — static-only helper class
     (in a separate file to keep `sim.gd` under
     the 1000-line lint cap) with
     `update_factions`, `evaluate_autonomous_conflicts`,
     `maybe_reset_pactmaker_yearly`.

4. **Track D — Difficulty + Settings + Locale.**
   - `Difficulty.get_research_rate(d)` (1.0 /
     1.0 / 0.5),
     `get_morale_delta_per_day(d)` (0.05 /
     0.0 / -0.1),
     `get_crisis_chance_per_day(d)` (0.0 /
     0.05 / 0.1) for `PEACEFUL` /
     `BALANCED` / `CRUEL`.
   - 44 new M4 locale keys in `en.po` and
     `de.po` (research, ritual, faction,
     crisis, Pactmaker, settings).

5. **Hardening pass (best-in-class audit).**
   - `sim.gd` was 1071 lines (above the
     1000-line lint cap). Extracted the M4
     per-tick step delegation into
     `src/sim/m4_sim_step.gd`; `sim.gd` is
     back to 996 lines.
   - `Crisis` `const`s consolidated at the
     top of the class (gdlint's
     `class-definitions-order`).
   - `KnowledgeState.register_research` /
     `register_ritual` /
     `Pactmaker.apply_power` factored into
     `_can_register_*` /
     `_invoke_power_effect` helpers
     (gdlint's `max-returns` cap).
   - `test_m4_closeout.gd` (24 tests) split
     into `test_m4_closeout_lifecycle.gd`
     (12 tests) and
     `test_m4_closeout_content.gd` (12 tests)
     (gdlint's `max-public-methods` cap).
   - `Crisis` extended with `data: Dictionary`
     field so the Pactmaker power effects can
     read the `sealable` / `pausable` flags.
   - Negative-test verification confirmed
     `M4Research.all().size() == 6` is a real
     assert (flipped to `7` → test failed as
     expected).
   - 24 M4-Closeout tests, 75 new asserts;
     **149/149 GUT tests in ~0.73s / 882
     Asserts** on Godot 4.7+ headless.

## Consequences

Positive:

- The M4-Closeout delivers the full
  research/ritual progression, Pactmaker
  intervention, autonomous-conflict, and
  difficulty surfaces the milestone plan
  pins.
- The M4-Closeout is the canonical "research
  + ritual + autonomous crisis + difficulty"
  reference for M5+ content passes.
- The 24-test end-to-end smoke test is the
  mechanical regression net for the M4
  surface; the next milestone that touches
  any of the M4 carriers runs the test
  before merging.

Negative:

- The `M4SimStep` static-only helper class
  adds a third "sim helper" file (after
  `ExplorationStep`); future milestones
  should consider whether to consolidate
  the helpers or keep them split (the M4
  closeout's choice is "split" — each
  milestone owns its own helper file).
- The `KnowledgeState.node_lookup` field is
  a public-mutable field (the realm façade
  sets it on boot); the M5 closeout can
  harden this to a setter method or a
  constructor argument.

## References

- `docs/adrs/0009-best-in-class-bar.md` —
  the best-in-class bar.
- `docs/adrs/0010-research-tree-schema.md` —
  the research-tree schema.
- `docs/adrs/0011-autonomous-conflict.md` —
  the autonomous-conflict schema.
- `docs/milestones.md` — the M4 milestone
  Definition-of-Done.
- `CHANGELOG.md` — the M4-Closeout entry.
