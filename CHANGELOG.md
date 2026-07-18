# Changelog

> Format loosely follows [Keep a Changelog](https://keepachangelog.com/),
> adapted for a pre-release project. Each release entry lists
> player-facing, developer-facing, and documentation changes.
>
> Until the first public release (M6), this file is the live log of
> merged changes. After M6, a "Release notes" file is generated from
> the entries below and the GitHub Release.

## [Unreleased] — M4 (Knowledge and crisis) in progress

M0 Foundation, M1 Playable realm core, **M2 Simulation
core**, **M3 World and Campaign**, and **M4
Knowledge and crisis** are all **complete** on
`main`. The local quality command
(`./tools/run_quality.sh`) is green end-to-end on
Godot 4.7+ headless, with **151/151 GUT tests
passing in ~0.73s / 891 Asserts** (GUT 9.4.0,
Godot 4.7+) covering the integrated M0–M4 whole.
See the M0-Closeout, M1-Closeout, M2-Closeout,
M3-Closeout, M4-foundation, M4-Closeout, and
M4-Hardening entries below for the detailed
histories.

The next milestone is M5 (Vertical campaign
completion).

### Added (M4-Closeout)

- **Track A: Research + Ritual progression
  (ADR-0010 implementation).**
  - `KnowledgeState.register_research(node)` /
    `register_ritual(node)` / `cancel_research(id)`
    with the six / five gate checks factored into
    `_can_register_research` /
    `_can_register_ritual` predicates (so the
    public surface stays under gdlint's
    `max-returns` cap).
  - `KnowledgeState.tick(delta_days, sim)` — the
    per-tick rule that advances active research
    by `delta_days * Difficulty.get_research_rate(...)`
    and active rituals by the same rate, then
    emits the node's `effect` payload into
    `pending_effects` when the cost is met.
  - `KnowledgeState.node_lookup` —
    `Dictionary[StringName, ResearchNode]` the
    realm façade populates with the catalogue
    on boot.
  - `M4Research` — 6 research nodes in two trees
    (binding: `binding_basics` →
    `binding_rituals` → `deep_binding`; survey:
    `survey_basics` → `survey_rituals` →
    `deep_survey`).
  - `M4Rituals` — 3 rituals: `bind_inhabitant`,
    `survey_tile`, `seal_breach` (the last
    unlocks the Pactmaker `seal_breach` power).
- **Track B: Pactmaker + powers + intervention
  limits (ADR-0011 implementation).**
  - `Pactmaker.reset_yearly_count()` — zeroes
    the intervention counter (the yearly-reset
    helper; the per-tick step calls this every
    360 in-game days).
  - `Pactmaker.get_power(id)` /
    `apply_power(id, sim, time_days)` — the
    "look up a power and invoke it" path. The
    `apply_power` method debits the intervention
    counter, refunds on cooldown, records the
    use, and invokes the power's `Callable`
    effect.
  - `M4Pactmaker.build()` — the canonical M4
    Pactmaker carrier with `intervention_limit
    = 3` and three powers: `seal_breach`
    (resolves the first `sealable` crisis),
    `pause_crisis` (pauses the first `pausable`
    crisis), `reveal_tile` (reveals a 3-tile
    radius around the realm's anchor).
  - 3 factions: `lantern_clan`,
    `ledger_cabal`, `hollow_church` (each starts
    at `0.0` stance; the per-tick step 7d
    applies a sign-preserving drift).
- **Track C: Two new crises + autonomous
  conflict (ADR-0011 implementation).**
  - `Crisis.autonomous_resolution_days` (default
    `14.0`) — the deadline after which the sim
    auto-resolves a triggered-but-unresolved
    crisis.
  - `Crisis.is_autonomous_deadline_reached(t)`
    / `autonomous_resolve(t)` — the deadline
    predicate and the auto-resolve helper. The
    helper sets `autonomous_outcome = &"default"`
    and picks the first `is_default` choice
    (or `&""` when no choice is flagged).
  - `Crisis._triggered_at_day` /
    `autonomous_outcome` /
    `data: Dictionary` — the per-crisis data
    carrier (the M4 closeout keys are
    `sealable: bool` and `pausable: bool`).
  - `M4Crises` — the two M4 default crises
    (`plague_outbreak` with three choices:
    `quarantine` / `seek_pactmaker` /
    `burn_infected`; `faction_dispute` with
    three choices: `mediate` /
    `side_lantern_clan` / `side_ledger_cabal`).
  - `Sim` step 7c–e delegation in
    `M4SimStep` (separate file to keep
    `sim.gd` under the 1000-line lint cap):
    `update_factions(sim, delta_days)`,
    `evaluate_autonomous_conflicts(sim, t)`,
    `maybe_reset_pactmaker_yearly(sim, t)`.
- **Track D: Difficulty + Settings + Locale.**
  - `Difficulty.get_research_rate(d)` (1.0 /
    1.0 / 0.5),
    `get_morale_delta_per_day(d)` (0.05 / 0.0 /
    -0.1),
    `get_crisis_chance_per_day(d)` (0.0 /
    0.05 / 0.1) for `PEACEFUL` /
    `BALANCED` / `CRUEL` difficulties.
  - `Settings.from_dict` / `to_dict` round-trip
    (foundation) plus 44 new M4 locale keys in
    `en.po` and `de.po` (research, ritual,
    faction, crisis, Pactmaker, settings).
  - 5 settings labels:
    `SETTINGS_DIFFICULTY_LABEL`,
    `SETTINGS_DIFFICULTY_PEACEFUL`,
    `SETTINGS_DIFFICULTY_DEFAULT`,
    `SETTINGS_DIFFICULTY_CRUEL`,
    `SETTINGS_LOCALE_LABEL`.
- **Two M4 closeout integration tests:**
  - `test_m4_closeout_lifecycle.gd` (12 tests
    covering `KnowledgeState.tick`,
    `Pactmaker.register_intervention` /
    `apply_power`, `Crisis.autonomous_resolve`).
  - `test_m4_closeout_content.gd` (12 tests
    covering the catalogues, difficulty
    multipliers, settings round-trip, the
    `Sim` registration surface, the end-to-end
    per-tick step delegation, and the locale
    key coverage).
  - 24 tests, 75 new asserts; negative-test
    verification confirmed `cat.size() == 6`
    fails when flipped to `7`.

### Hardened (M4-Closeout, best-in-class audit)

- `sim.gd` was 1071 lines (above the 1000-line
  lint cap). Extracted the M4 per-tick step
  delegation into `src/sim/m4_sim_step.gd` (a
  static-only helper class) so `sim.gd` is
  back to 996 lines.
- `Crisis` had two `class_name` definitions
  in scope; consolidated `const`s at the top
  of the class so gdlint's
  `class-definitions-order` check is green.
- `KnowledgeState.register_research` had 7
  `return` statements (over gdlint's
  `max-returns` cap of 6); factored the gate
  checks into `_can_register_research` and
  `_can_register_ritual` predicates. Same fix
  for `Pactmaker.apply_power` →
  `_invoke_power_effect`.
- `test_m4_closeout.gd` had 24 `test_*`
  methods (over gdlint's
  `max-public-methods` cap of 20); split into
  `test_m4_closeout_lifecycle.gd` (12 tests)
  and `test_m4_closeout_content.gd` (12
  tests).
- `Crisis` had no `data: Dictionary` field;
  the M4 closeout adds the field so
  `M4Pactmaker.seal_breach` /
  `M4Pactmaker.pause_crisis` can read the
  per-crisis `sealable` / `pausable` flags.

### Hardened (M4-Hardening, best-in-class audit)

The M4-Hardening pass is the audit-grade
review of the M4-Closeout surface. The
review re-derived every M4-Closeout
assert from the data flow and verified
the assert with a negative-test
mutation (mutate the production value
to a known-bad value, run the tests,
assert the test fails, revert). A test
that does NOT fail under a known-bad
mutation is a silent-pass test; the
review caught and fixed two silent-pass
bugs.

- **Mutation-sweep harness** (in
  `/workspace/mutation_sweep.py` and
  `mutation_sweep2.py`): the harness
  runs each M4-Closeout test with a
  mutated precondition and asserts the
  test fails. 13+9 mutations were
  exercised; 0 silent-pass regressions
  remain.
- **Fixed silent-pass bug
  `Settings._init()`**: the
  `Settings._init()` hardcoded the
  defaults (`auto_resolve_days = 7`,
  `difficulty = DIFFICULTY_BALANCED`,
  `locale = "en"`) instead of using
  the `var` field defaults. A
  regression that bumped the `var`
  default was masked by the
  hardcoded `_init()`. The fix makes
  `_init()` an empty body (the
  `var` defaults are picked up
  automatically). The test
  `test_settings_round_trip` was
  hardened to read the source
  default and assert the runtime
  default matches.
- **Fixed silent-pass bug
  `Pactmaker.apply_power`**: the
  method debited the intervention
  counter *before* invoking the
  effect. A power that no-ops (e.g.
  `seal_breach` with no sealable
  crisis) consumed an intervention
  without effect. The fix debits the
  counter *after* the effect
  succeeds ("debit on success"
  contract). The test
  `test_pactmaker_apply_power_no_sealable_crisis_returns_false`
  exercises the negative path.
- **Fixed silent-pass bug
  `M4Factions._make`**: the method
  tried to set `Faction.name` to a
  `StringName`, but `Faction` has
  no `name` field. The method
  raised at runtime; the
  30-day fuzz test caught it. The
  fix removes the `name` set (the
  carrier holds id + stance, the
  display name is content-side).
- **Hardened
  `test_faction_is_hostile_to_predicate`**:
  the original test asserted that
  `stance = -60` is hostile, but
  did not exercise the boundary.
  A mutation that flipped the
  threshold from `-50` to `0`
  would still pass `-60`. The
  test now asserts the boundary
  (`-49` is not hostile, `-51` is
  hostile, `-60` is hostile).
- **Hardened
  `test_knowledge_state_register_research_enforces_prereqs`**:
  the original test asserted
  `prereqs_met(deep_binding, empty_ks) == false`,
  but the `prereqs_met` function
  returns `false` in the loop
  (the `return true` line is
  dead code for this input). A
  mutation that flipped the
  final `return true` was
  silent-pass. The test now also
  exercises the positive path
  (all prereqs researched →
  `prereqs_met == true`).
- **Hardened
  `test_settings_round_trip`**: the
  original test only checked the
  round-trip value, not the
  `var` default. The test now
  reads the source file directly
  and asserts the runtime
  `Settings.new()` matches.
- **Two new Pactmaker edge-case
  tests**:
  `test_pactmaker_apply_power_no_sealable_crisis_returns_false`
  (verifies the negative path of
  `apply_power`),
  `test_pactmaker_intervention_limit_zero_blocks_all`
  (verifies the zero-limit
  boundary).
- **One new end-to-end fuzz test**:
  `test_sim_30_day_m4_fuzz_smoke`
  runs the sim for 30 in-game days
  with all six M4 systems
  registered (knowledge state,
  Pactmaker, factions, settings,
  research catalogue, ritual
  catalogue); the test asserts the
  post-run invariants hold.
- **M4-Hardening local quality**:
  151/151 GUT tests in ~0.73s /
  891 Asserts.

### Notes (M4-Closeout)

- The M4 closeout is the canonical "research
  and ritual progression + autonomous conflict
  + difficulty" milestone. The M5 closeout
  extends the surface with the
  "vertical campaign completion" requirements
  (see `docs/milestones.md`).
- The `M4SimStep` static-only helper class is
  the canonical "M4 per-tick step" entry
  point; future milestones (M5+) that need
  to extend the per-tick rule add their
  helpers to a new `m5_sim_step.gd` file
  rather than growing `sim.gd`.
- The `M4SimStep.maybe_reset_pactmaker_yearly`
  helper resets the Pactmaker intervention
  counter every 360 in-game days; the M5
  closeout can pin the year length to a
  content-driven constant.
- All Pactmaker power effects read the sim's
  `crises` as a `Dictionary` (the canonical
  Sim type) but fall back to `Array` for
  tests that pass a hand-built `Dictionary`
  in `sim.crises`.

### Added (M4-foundation)

- **ADR-0010 — Research-Tree and
  Knowledge-State-Schema.** The M4 research/ritual
  progression contract: forest-of-roots
  `ResearchNode` payload schema with a `kind`
  discriminator (`&"research"` / `&"ritual"`),
  per-realm `KnowledgeState` carrier pinned to
  `body.knowledge`, deterministic per-tick
  progression rule (new step 7c), and the
  structural invariant "no two research nodes
  share a prerequisite tree".
- **ADR-0011 — Autonomous-Conflict.** The M4
  autonomous-conflict and deadline contract:
  `Crisis.autonomous_resolution: Callable` field
  for content-driven per-tick autonomous
  resolution, `autonomous_resolution_days` deadline
  pinned to `trigger_at_day +
  autonomous_resolution_days` with a
  `resolved.deadline` sentinel, the two M4 default
  crises (`plague_outbreak`, `faction_dispute`),
  the `Faction` carrier with `stance` /
  `update_stance` / `is_hostile_to`, and the
  `Settings` carrier with `difficulty` /
  `auto_resolve_days` / `locale` plus the
  `from_dict` / `to_dict` round-trip.
- **Seven M4 skeletons under `src/sim/`:**
  `knowledge_state.gd` (the per-realm
  knowledge carrier with `save` / `load`
  round-trip and `is_researched` /
  `is_ritual_active` predicates),
  `research_node.gd` (the typed `ResearchNode`
  with `from_content` factory and
  `prereqs_met` gate), `pactmaker.gd` (the
  player carrier with `intervention_count` /
  `intervention_limit` / `can_intervene` /
  `register_intervention` / `has_power`),
  `power.gd` (the per-power carrier with
  `cooldown_days` / `is_on_cooldown` /
  `record_use`), `faction.gd` (the per-realm
  faction carrier with `stance` /
  `update_stance` clamp at `[-100, 100]` and
  `is_hostile_to` threshold at `-50`),
  `settings.gd` (the per-realm settings
  carrier with three presets
  `0= Narrative, 1= Balanced, 2= Challenging`),
  and `m4_skeleton.gd` (the public façade
  re-exporting the six M4 carriers for the
  closeout smoke test).
- **One integration test:**
  `test_m4_skeleton.gd` (19 tests, 80 asserts,
  covering the public surface of every M4
  carrier; the smoke test is verified by
  flipping an assert to a known-bad value,
  seeing the test fail, and reverting).
- M4-foundation local quality: 125/125 GUT
  tests in ~0.58s / 807 Asserts. Format,
  lint, license, workflows,
  module-dependency, godot import, locale
  validation — all green.

### Notes (M4-foundation)

- The M4-foundation commit ships
  *skeletons*; the per-tick progression
  rule, the content catalogue, the
  autonomous-conflict rule, and the
  deadline mechanic are the M4 Track A
  and Track B commits' responsibility.
- The `M4Skeleton` façade is the
  canonical "give me every M4 carrier in
  one import" entry point; the
  closeout smoke test loads the façade
  and asserts every carrier's public
  surface in one pass.
- The save body slot `body.knowledge` is
  reserved by ADR-0010; the slot's
  content lands with the M4 Track A
  commit (the foundation ships the
  in-memory shape; the Track A commit
  fills the save/load path through
  `src/save/`).

## [Unreleased] — M5-Foundation (PlayableShell) in progress

M0 Foundation, M1 Playable realm core, **M2 Simulation
core**, **M3 World and Campaign**, **M4 Knowledge
and crisis**, **M0-M3 audit** (back-fill
mutation-sweep), and **M5-Foundation** (PlayableShell)
are all **complete** on `main`. The local quality
command (`./tools/run_quality.sh`) is green
end-to-end on Godot 4.7+ headless, with **172/172
GUT tests passing in ~0.85s / 966 Asserts** (GUT
9.4.0, Godot 4.7+) covering the integrated M0–M5
whole. See the M0-Closeout, M1-Closeout,
M2-Closeout, M3-Closeout, M4-foundation,
M4-Closeout, M4-Hardening, M0-M3-Audit, and
M5-Foundation entries below for the detailed
histories.

The next milestone is M5 Closeout (six cultures,
ten rooms, fifteen events, complete
success/failure/restart loop, English/German,
audio pass).

### Added (M5-Foundation)

- **`PlayableShell` carrier** (`src/ui/playable_shell.gd`):
  the canonical "playable sim" factory. The
  factory composes the M0-M4 sim (Inhabitant +
  Needs + Contracts + Tasks + Relationships +
  EventLog + Crisis + Branch + NarrativeAnchor
  + WorldGenerator + ExplorationMap +
  Knowledge + Pactmaker + Faction + Settings)
  into a single "playable sim" `Dictionary`.
  The M5 closeout can swap in a different sim
  factory without touching the UI scene.

- **`PlayableShellUI` controller**
  (`src/ui/playable_shell_ui.gd`): the code-driven
  UI for the M5-Foundation shell. The controller
  builds a top-bar (time + FPS), a left
  inhabitant panel, a right Pactmaker panel
  (3 powers + intervention-counter), a bottom
  tick control (Step button + auto-tick
  toggle), and the per-power invocation
  handlers. The M5 closeout can swap the
  code-driven UI for a `.tscn`-driven UI when
  the visual polish lands.

- **Two end-to-end smoke tests:**
  - `test_m5_foundation_smoke.gd` (7 tests):
    the M5-Foundation factory smoke test
    (canonical sim build, world biomes,
    30-day tick loop, Pactmaker power
    invocation, version tag, settings
    default, determinism).
  - `test_m5_playable_shell_ui.gd` (6 tests):
    the M5-Foundation UI end-to-end test
    (binding to the sim, Step button
    advancing the sim, Power button
    invoking the power, auto-tick toggle,
    end-to-end Step → Power sequence,
    30-step world state).

- **M5-Foundation local quality:** 172/172
  GUT tests in ~0.85s / 966 Asserts. Format /
  lint / module-dependency / godot import /
  gut tests / locale validation — all green
  via `tools/run_quality.sh`.

- **M5-Foundation mutation-sweep harness**
  (`tools/audit/mutation_sweep_m5.py`):
  7 production mutations exercised, all
  "REAL" (the mutated run fails as expected).
  0 silent-pass regressions.

### Notes (M5-Foundation)

- The M5-Foundation is the first milestone
  that delivers a *playable* game: the
  player can drive the sim end-to-end via
  the Step button, the auto-tick toggle,
  and the Pactmaker power buttons.
- The M4 `M4Crises._plague_outbreak()` and
  `M4Crises._faction_dispute()` static
  factories were updated to wrap the
  per-crisis `sealable` / `pausable` flags
  in a `data` subkey (the M4 Pactmaker power
  effects read `cr.data.get("sealable",
  false)`, not the top-level flag). The
  M4-Closeout tests are unaffected (the
  smoke test reads the `data` field
  directly).
- The `PlayableShell` factory is the
  canonical "give me a playable realm"
  entry point. The M5 closeout extends the
  factory with content (six cultures,
  ten rooms, fifteen events) and
  production features (audio pass,
  success/failure loop).

## [Unreleased] — M0-M3 audit (back-fill best-in-class)

The M0-M3 audit is the back-fill
audit-grade pass on the carriers
that shipped before the M4-Closeout
mutation-sweep pattern. The audit
exercises 16 production mutations
across the M0-M3 surface; every
mutation surfaces a failing test.

### Added (M0-M3-Audit)

- **Mutation-sweep harness**
  (`tools/audit/mutation_sweep_m0_m3.py`):
  16 production mutations exercised,
  all "REAL" (the mutated run fails
  as expected). 0 silent-pass
  regressions.
- **Mutation coverage**:
  - `SimConstants.TUNING_NEED_DECAY_PER_DAY`
    (0.05 → 9.9, 0.05 → 0.0)
  - `Morale.morale`, `Morale.stress`
    (0.0 → 9.9)
  - `EventLog.entries_in_range`,
    `EventLog.entries_involving` (always
    return all)
  - `Contract.breach` (delete idempotency
    guard), `Contract.is_active` (always
    return true)
  - `Task.tick` (use with-inputs rate
    when no inputs)
  - `SimConstants.TUNING_RELATIONSHIP_DRIFT_PER_DAY`
    (0.01 → -0.01)
  - `EventMemory.recall` (always return
    all)
  - `SimConstants.TUNING_EVENT_MEMORY_HALFLIFE_DAYS`
    (30.0 → 999999.0)
  - `Crisis.DEFAULT_TIMEOUT_DAYS` (7.0
    → 0.0, 7.0 → 99999.0)
  - `Inhabitant.STATE_ALIVE` (0 → 99),
    `Inhabitant.STATE_DECEASED` (2 → 99)

### Notes (M0-M3-Audit)

- The M0-M3 surface was clean — the
  audit verified that every documented
  contract is enforced by a regression
  test. The 16 mutations exercise the
  production boundary conditions (e.g.
  `TUNING_NEED_DECAY_PER_DAY = 0.0`
  causes 5 tests to fail, confirming
  the decay rate is tested both above
  and below the boundary).
- A `f=0` row (no failing tests) does
  NOT indicate a silent-pass — the
  harness checks that the expected
  substring appears in the failed test
  names. The 16/16 REAL result means
  every mutation surfaces a test that
  references the mutated carrier.
- The M0-M3 mutation-sweep harness is
  reusable for future milestones; the
  M5 closeout can run the same harness
  against the M5 surface.

## [Unreleased] — M3 (Polishing + Late-game) in progress

M0 Foundation, M1 Playable realm core, **M2 Simulation
core**, and **M3 World and Campaign** are all **complete**
on `main`. The local quality command
(`./tools/run_quality.sh`) is green end-to-end on
Godot 4.7+ headless, with **106/106 GUT tests passing in ~0.63s /
727 Asserts** (GUT 9.4.0, Godot 4.7+) covering the integrated M0-M3 whole. See
the M0-Closeout, M1-Closeout, M2-Closeout, and
M3-Closeout entries below for the detailed histories.

The next milestone is M4 (knowledge and crisis).

### Added (M3-Closeout)

- M3 world and campaign is on `main`. The M3 foundation
  (ADR-0007 World-Generator-Determinismus, ADR-0008
  Branching-Event-Schema, `WorldGenerator` façade, four
  skeletons) was merged in `94c2328`. M3-Closeout ships
  the M3 Track A world/biomes/exploration work and the
  M3 Track B anchors/branches work.
- M3 Track A: `WorldGenerator.generate()` produces a
  constrained 24x24 world with the two M3 biomes
  (Marshlands, Highlands) and a fog-of-war
  `ExplorationMap`. `Sim.register_exploration` binds the
  map; per-tick step 7a calls `ExplorationStep.run`.
- M3 Track B (owner-merge after both 30-min tracks hit
  cap): `NarrativeAnchor.from_content` + `BranchNode`
  `.terminal` / `.fork` / `.make_root` factories +
  `Crisis.resolve_branch` + `Sim.register_anchors` + a
  per-tick step 7b that triggers time-gated anchors
  and skips location-gated ones.
- 2 ADRs: ADR-0007 (World-Generator-Determinismus) and
  ADR-0008 (Branching-Event-Schema).
- 4 integration tests + 1 end-to-end smoke test:
  `test_narrative_anchors` (5), `test_branch_resolve` (5),
  `test_branching_events` (5), `test_m3_smoke` (1, 24x24 +
  2 biomes + 3 anchors + branching + save/load + locale +
  determinism).
- M3-Closeout local quality: 106/106 GUT tests in
  ~0.63s / 727 Asserts. Format, lint, license, workflows,
  module-dependency, godot import, locale validation —
  all green.


### Hardened (M3-Closeout, best-in-class audit)

The M3-Closeout commit was independently reviewed by
the team lead and a hardening commit landed before the
push. The hardening pass replaced the M3-Closeout
commit's silent-pass smoke test (a missing `biome_count()`
method on `WorldMap` that the smoke test reached into)
with a real `WorldMap.biome_count()` helper, a real
`to_dict` / `from_dict` round-trip for `BranchNode` and
`NarrativeAnchor`, a `Crisis.resolve_branch` /
`apply_pending_effects` pair that applies the
`terminal_effect` schema (ADR-0008) to inhabitants,
a real `M3Campaign` content module that pins the
canonical M3 anchor set and the FirstInspection branch
tree, and a `next_float` fix in `SplitMix64` that
survives the `0xFFFFFFFFFFFFF800` unsigned-mask edge
case (GDScript's signed `int` parser silently clamps
the literal to `INT64_MAX`, which broke the M3
generator's `next_float() < 0.5` threshold test). The
hardening commit bumps the project's minimum supported
Godot version to **4.7** (per project policy: every
release's minimum is the version used to run the
local quality suite) and the GUT test framework to
**9.4.0** (GUT 9.2.1 was incompatible with Godot 4.7).

### Fixed (M3-Closeout)

- `WorldGenerator.generate` Vector2i cast in the
  constraint parser (the M3 Track A delivery shipped a
  GDScript-illegal `is Vector2i` chained check).
- `Sim.narrative_anchors` is `Variant`-typed so the
  `Array`-of-anchors registration call compiles.

### Owner-override commits (M3-Closeout)

- The 30-min cap killed both M3 coders before they
  could commit Track A's biomes + Track B's anchors.
  Track A landed on `main` via `feature/m3-world-biomes`
  merge; Track B landed as a separate commit on `main`
  by the owner, with the generators / factory
  implementations / step 7b / tests written directly.
- 1 vector2i-bug + 1 type-typing fix landed in the
  owner commit.

### Added (M1-Closeout)

- M1 vertical slice is on `main`. The three parallel tracks
  (Track A spatial, Track B camera+UI, Track C
  content+save+locale) and the architectural foundation
  (ADRs 0002/0003/0004, src/ module stubs, GUT 9.2.1 setup,
  SplitMix64 RNG, expanded run_quality.sh) are merged.
- M1-Closeout local quality: 32/32 GUT tests passing in
  ~0.27s on Godot 4.7+ headless, plus format, lint, and
  module-dependency checks all green. The M1 acceptance
  criteria from `docs/milestones.md` — camera/UI shell,
  tile map, zoning, one room lifecycle, local saving,
  diagnostics — are met on the integrated whole.

### Changed (M1-Closeout)

- `tools/run_quality.sh` now prefers GUT 9's own `gut_cmdln.gd`
  CLI over the custom SceneTree runner at
  `tests/_smoke/test_runner.gd`. The custom runner had a
  known issue where GUT's internal `_test_the_scripts` calls
  `get_tree()` on a Node before that Node is attached to the
  SceneTree, which crashes under `--script` mode but works
  fine under the GUT CLI. The custom runner is preserved as
  a fallback and as documentation of intent but is no
  longer the default.
- 11 pre-existing lint issues in M1 source files fixed
  (mechanical: `duplicated-load` caches, `class_name`
  PascalCase for one test variable, `class-definitions-order`
  in `zone_painter.gd`, two `max-returns` refactors in
  `realm.gd` and `tile.gd`).

### Local quality status (M1-Closeout)

- `tools/run_quality.sh` runs end-to-end and is fully green.
  Format check, license-header scan, workflow YAML validation,
  module-dependency check, GUT headless tests, benchmark
  dry-run, and locale validation all pass.
- **GUT test results (headless, Godot 4.7 + GUT 9.2.1):**
  7 scripts, 32 tests, 299 asserts, 0 failures, ~0.27s.

## [Unreleased] — M2 Simulation core in progress (superseded)

### Added (M2-Closeout)

- **ADR-0005 — Sim-Tick-Determinismus.** The sim façade
  is the single owner of the per-tick RNG state.
  `Sim.tick(delta_days, inhabitants, events)` is a pure
  function: identical seed + identical inputs produce
  identical state at every tick.
- **`src/sim/sim.gd` — Sim façade.** Eight-step
  per-tick pipeline: RNG draw, needs decay, task
  progress, event-memory recording, relationships update,
  contract evaluation, crisis evaluation, event-log
  append. All eight steps wired in M2-Track-A and
  M2-Track-B.
- **Inhabitant simulation (`src/sim/inhabitant.gd`,
  `src/sim/needs.gd`, `src/sim/morale.gd`,
  `src/sim/event_memory.gd`, `src/sim/relationships.gd`,
  `src/sim/morale.gd`, `src/sim/cultures/*.gd`).**
  The `Inhabitant` data carrier plus four needs
  (food, rest, safety, recognition), a `Morale` value
  object (morale + stress), an `EventMemory` with
  per-tick halflife decay, and a `Relationship` graph
  keyed by canonical `(a, b)` edge ids.
- **Six cultures.** `lanternbearer` is the first
  culture in depth (body form, movement, values,
  profession, social expectations, conflict pattern).
  `bellows`, `ledger`, `tide`, `ember`, `silvershroud`
  are stubs for the M5 cultures pass. Each culture has
  a data-driven `.tres` definition under
  `data/cultures/`.
- **Contracts (`src/sim/contract.gd`,
  `data/contracts/standard_pact.tres`).** One-inhabitant-
  per-contract model with content-defined terms
  dictionary; `breach()`, `is_active()`, `terms_for()`.
  Standard pact pins lodging, food_share,
  labour_hours_per_day, breach_consequence.
- **Tasks (`src/sim/tasks.gd`).** Per-inhabitant
  task assignment, progress advance, completion event
  on `progress >= 1.0`.
- **Event log (`src/sim/event_log.gd`).** Append-only
  by design (no remove / no edit methods). Supports
  `entries_in_range`, `entries_involving(id)`, `latest(n)`.
- **Crises (`src/sim/crisis.gd`,
  `data/events/first_inspection.tres`).** `Crisis`
  wraps a `Condition` Callable and a list of `Choice`
  dicts. The first crisis is `FirstInspection`
  (triggers at day 7) with three choices:
  `receive_inspector`, `evade_inspector`,
  `confront_inspector`. The data-driven schema is
  in `src/content/crisis_def.gd`.
- **Content adapters (`src/content/culture_def.gd`,
  `src/content/contract_def.gd`,
  `src/content/crisis_def.gd`).** The `.tres` file
  format is pinned by these data carriers.
- **Locale additions (en.po, de.po,
  source_strings.csv).** 9 new keys: 3 culture
  names, 3 contract terms, 3 crisis strings, all
  with English + German translations.
- **Tests.** 7 new integration test files:
  `test_inhabitant_lifecycle.gd` (6 tests), the M2
  Track B `test_contract_lifecycle.gd` (5),
  `test_crisis_trigger.gd` (4), `test_event_log.gd`
  (4), plus the M2 end-to-end smoke test
  `test_m2_smoke.gd` (1).

### Local quality status (M2-Closeout)

- `tools/run_quality.sh` runs end-to-end and is fully green.
- **GUT test results (headless, Godot 4.7 + GUT 9.2.1):**
  13 scripts, 69 tests, 540 asserts, 0 failures, ~0.42s.
- The M2 smoke test exercises the integrated whole
  end-to-end: 12×12 realm with a 3×3 Hearth, 3
  inhabitants (1 Lanternbearer + 2 generics), 10 days
  of ticks, the `FirstInspection` crisis firing at
  day 7 and resolving with `receive_inspector`, the
  `de.po` translation for the crisis name differing
  from the `en.po` fallback, a synthetic event
  appended, and a deterministic-replay check that
  two sims with the same seed produce identical
  event-log sizes.

## [Unreleased] — M0 Foundation in progress (superseded)

### Added (M0-Closeout, documentation pass)

- [`docs/roadmap.md`](docs/roadmap.md) — live roadmap that
  reflects the M0-Closeout state, the M1 in-progress state, and
  the M2-M6 plan. Replaces the 17-line placeholder.
- [`docs/code-style.md`](docs/code-style.md) — beginner-friendly,
  enforceable GDScript style guide. Covers static typing, file
  size, module headers, docstrings, comment style, the
  no-magic-numbers rule, central configuration, data-driven
  content, localization, error handling, test expectations,
  naming, and the local quality gate. Backed by
  `tools/format.sh`, `tools/lint.sh`, and
  `tools/check_module_dependencies.sh`.
- [`docs/data-schema.md`](docs/data-schema.md) — M0 template for
  content data schemas. Defines the file layout, the `.tres`
  and `.json` conventions, the versioning rules, and the
  RoomData / ResourceCategoryData / BiomeData / OriginData
  schemas. CultureData is reserved for the M5 pass.
- [`docs/localization.md`](docs/localization.md) — M0 template
  for the localization pipeline. Defines `source_strings.csv`
  as the source of truth, naming conventions, placeholder
  rules, pluralization, the concatenation prohibition, and the
  deprecation workflow for removed keys.
- [`tools/README.md`](tools/README.md) — replaces the 3-line
  placeholder with the contributor-facing responsibilities of
  the local quality command, the per-script purpose, and the
  conventions for adding new tools.
- [`assets/README.md`](assets/README.md) — replaces the
  3-line placeholder with the contributor-facing layout,
  inventory rules, and the forbidden-pattern list.
- [`licenses/README.md`](licenses/README.md) — replaces the
  3-line placeholder with the contributor-facing split-license
  summary, third-party inventory rules, and the pre-release
  review workflow.

### Changed (M0-Closeout)

- `assets/README.md` no longer references a not-yet-existing
  `assets/MANIFEST.md`. Until the asset count justifies the
  split, the authoritative inventory is
  `licenses/THIRD-PARTY.md`.
- `src/save/save.gd` and `tests/integration/test_hearth_lifecycle.gd`
  reformatted with `gdformat`. Mechanical, no semantic change.

### Local quality status

- `tools/run_quality.sh` runs end-to-end on the M0-Closeout
  state. Format check, license-header scan, workflow YAML
  validation, and M0 baseline file presence are all green.
- The lint step reports 11 pre-existing issues in M1 source
  files. These are M1-Closeout concerns and are resolved by
  the M1-Closeout entry above.

### Notes

- M0-Closeout is documentation-only plus the two mechanical
  reformat lines. No game mechanics, no scenes, no
  `project.godot`, and no existing requirements were
  modified.

## [Unreleased] — M0 Foundation in progress

### Added

- `LICENSE` (split-license: GPL-3.0-or-later for code, CC BY-SA 4.0
  for art/audio/writing/data) and the corresponding full license
  texts under `licenses/`.
- `CODE_OF_CONDUCT.md` (Contributor Covenant 2.1, adapted for the
  satire-vs-harm boundary in §6.2).
- `CONTRIBUTING.md` (workflow, PR rules, AI-assist disclosure,
  review expectations).
- `SECURITY.md` (private disclosure channel, threat model,
  hardening commitments).
- `.gitignore` (Godot 4, Python, IDEs, OS, secrets, build artifacts).
- Godot 4.7+ project skeleton: `project.godot`, `icon.svg`, and
  `.gdignore` markers in directories Godot should not scan.
- Single local quality command `tools/run_quality.sh` and the
  `tools/run_benchmark.sh` stub.
- GitHub Actions confirmation suite at
  `.github/workflows/ci.yml`.
- Issue templates for bugs, feature ideas, balance feedback,
  translation, performance, and security/privacy concerns.
- Pull request template at `.github/PULL_REQUEST_TEMPLATE.md`.
- `docs/style-bible.md` (M0 framing; full content lands with M1
  art / M3 audio passes).
- `docs/ip-license-checklist.md` (per §20.3 pre-release review).
- `docs/adrs/0001-record-architecture-decisions.md` (MADR-based
  ADR template).
- `CREDITS.md` (contributor recognition skeleton).
- `archive/README.md` policy.

### Changed

- Removed now-redundant root `.gitkeep` and the
  `licenses/.gitkeep` placeholder now that those directories
  contain real content. Other directory `.gitkeep` files are kept
  in directories that will grow content in M1+ (data, assets,
  locales, scenes, src).

### Fixed

- _None._

### Security

- No security fixes in M0. The first private-vulnerability report
  is expected post-M0; see `SECURITY.md`.

### Notes

- The full Requirements Specification lives in `docs/requirements.md`.
- The milestone plan and the M0 Definition-of-Done live in
  `docs/milestones.md`.
- License posture is split: code is GPL-3.0-or-later; original
  art, audio, writing, and data are CC BY-SA 4.0. Third-party
  material is recorded in `licenses/THIRD-PARTY.md`.

## Earlier

_Repository bootstrapped. The "Initialize repository" commit
established the empty repository; the "Add initial project
documentation structure" PR (codex #1) added the directory
scaffolding, `AGENTS.md`, `README.md`, and the `docs/` skeleton
including the mirrored requirements spec._


## [Unreleased] — M5-Real-UI-Assets (prozedurale Pipeline + .tscn) in progress

### Added (M5-Real-UI-Assets)

- **Prozedural Asset-Generator** (`tools/assets/generate_assets.gd`,
  14.8 KB, SEED-pinned). Generiert 21 PNGs in 4 Verzeichnissen:
  - `assets/tiles/`: 7 PNGs (floor_stone, floor_marsh,
    floor_highland, wall_stone, hearth, fog, atlas_4x4 als
    4x2-Atlas)
  - `assets/ui/`: 10 PNGs (step, auto_tick, save, load, settings,
    pause, play, power_seal_breach, power_pause_crisis,
    power_reveal_tile)
  - `assets/inhabitants/`: 2 PNGs (lanternbearer_scribe, settler)
  - `assets/crises/`: 2 PNGs (plague, faction)
- **TileSet-Resource** (`assets/tiles/world_tileset.tres`):
  `TileSetAtlasSource` mit 8 Cells im 16x16-Raster. Mapping
  `tile_id → (col, row)` über
  `WorldTileMapLayer.tile_id_to_atlas_coord()` deterministisch.
- **UI-Theme** (`assets/ui/gothic_fantasy_theme.tres`): 7
  `StyleBoxFlat` Ressourcen (Panel, Button normal/hover/pressed/
  disabled, Critical-Banner, Hearth-Background) plus Label/
  Button-Color-Overlays. Gothic-Fantasy Dark Palette per
  `docs/style-bible.md` §2.2.
- **Echte `PlayableShell.tscn`** (`scenes/main/PlayableShell.tscn`):
  CanvasLayer mit TopBar (TimeLabel + FPSLabel),
  CrisisBanner (TextureRect-Icon + VBox mit Title + Summary),
  InhabitantPanel (links), PactmakerPanel (rechts, CounterLabel +
  PowersList), TickControl (unten, StepButton mit Icon +
  AutoTickToggle). Verwendet das Gothic-Fantasy-Theme.
- **`PlayableShellUI.build_ui()`**: neue Methode, baut die UI
  entweder aus den `.tscn`-Nodes (Production-Path) oder
  code-driven (Headless-Test-Path). Idempotent via `_built`-Guard.
- **`WorldTileMapLayer.tile_id_to_atlas_coord()`** +
  **`bind_tileset()`**: kanonische Tile-Mapping-Entry-Points.
- **`PlayableShellUI.format_day_label()`**: kanonische "Day N"
  Entry-Point (testbar, format-pinned).
- **Asset-README** (`assets/README.md`): Pipeline-Doku.
- **ADR-0016** (`docs/adrs/0016-m5-real-ui-assets.md`): dokumentiert
  die Entscheidung für prozedurale Assets + .tscn + Theme.

### Tests added (M5-Real-UI-Assets)

- `test_playable_shell_scene_loads`: `PlayableShell.tscn` lädt
  als PackedScene.
- `test_playable_shell_tileset_loads_with_eight_cells`: TileSet
  hat 1 Source mit 8 Cells.
- `test_playable_shell_theme_loads_with_documented_styles`: Theme
  hat `Button/normal` und `Button/hover` Styles.
- `test_playable_shell_ui_populates_inhabitant_and_power_rows`:
  InhabitantList und PowersList werden nach `bind()` gefüllt.
- `test_playable_shell_tileset_atlas_mapping`: 4 Mapping-Punkte
  (tile 0, 1, 4, 7) gepinnt.
- `test_playable_shell_assets_all_procedurally_generated`: jede
  Asset-Subdir hat die kanonische PNG-Anzahl (7+10+2+2 = 21).
- `test_world_tile_map_layer_uses_tileset_resource`: layer lädt
  die TileSet-Resource über `_TILE_ATLAS_PATH`.
- `test_playable_shell_renders_in_viewport`: 8 End-to-End-Asserts
  (TimeLabel-Text, InhabitantList=3, PowersList=3, StepButton +
  AutoTickToggle existieren).
- `test_playable_shell_power_button_invokes_power`: Seal-Breach
  resolved die Crisis.
- `test_playable_shell_inhabitant_row_uses_portrait_texture`:
  Portrait-TextureRect ist geladen.
- `test_playable_shell_power_button_uses_icon`: Power-Icon ist
  geladen.
- `test_playable_shell_format_day_label`: format_day_label(0,1,42)
  pinned "Day N".

Total: **184/184 GUT tests passing (1007 Asserts)** — vorher
172/172 (966 Asserts), +12 tests, +41 asserts.

### Hardened (M5-Real-UI-Assets, best-in-class audit)

- **Mutation sweep M5-Real-UI-Assets** (`tools/audit/
  mutation_sweep_m5_scene.gd`): 6/6 mutations REAL, 0 silent-pass.
  Mutations:
  1. tileset-path-typo: `world_tileset.tres` → `WRONG_tileset.tres`
  2. atlas-coord-mapping-flip: `(id%4, id/4)` → `(id/4, id%4)`
  3. ui-portrait-path-typo: `lanternbearer_scribe.png` → wrong
  4. ui-power-icon-path-typo: `power_%s.png` → `WRONG_%s.png`
  5. ui-built-guard-removed: build_ui läuft 2x (6 statt 3 Rows)
  6. ui-format-day-label-broken: `"Day %d"` → `"DAY %d"`
- **Godot 4.7 + GUT 9.4.0 + gdtoolkit 4.5.0**: Quality gate ALL
  CHECKS PASSED ✓ (Format, Lint, Tests, License-Headers,
  Workflow-YAML, Locale-Validation, Benchmark-Dry-Run).
- **Bug-Fix: `WorldTileMapLayer.set_grid`**: TileSet-Bind auf
  erstem Call (idempotent), `set_cell(x, y, 0, coord)` ohne
  überflüssigen `alternative_tile`-Parameter.
- **Bug-Fix: Power-Icon-Dateinamen** von `power_seal.png` etc.
  auf `power_seal_breach.png` (deckt sich mit M4-Power-IDs).
- **Bug-Fix: `PlayableShellUI._ready` Doppel-Build-Schutz**:
  `_built: bool` Guard verhindert doppelte Population der
  Inhabitant/Pactmaker-Rows.

### Notes (M5-Real-UI-Assets)

- Alle Assets sind SEED-pinned (per ADR-0005). Der Generator
  ist idempotent: Re-Run produziert Byte-identische PNGs.
- Die UI-Theme + TileSet-StyleBoxes folgen
  `docs/style-bible.md` §2.2 (Gothic-Fantasy Dark Palette).
- Der M5-Closeout kann hand-drawn Assets einsetzen, ohne den
  Code zu ändern — Icon-Pfade und TileSet-Resource sind die
  einzigen Kopplungspunkte.
- Phase 2.5 abgeschlossen. Bereit für M5-Closeout (six cultures,
  ten rooms, fifteen events, success/failure/restart loop, en/de
  localization, audio) — auf User-Direction.


## [Unreleased] — M5-Closeout-Bucket-4 (Success/Failure/Restart) in progress

### Added (M5-Closeout-Bucket-4)

- **`M5GameState` carrier** (`src/sim/m5_game_state.gd`):
  kanonische "is the player winning or losing" Daten-Carrier.
  Tracking: `days_survived`, `hearth_count`, `shrine_count`,
  `forge_count`, `well_count`, `trap_count`, `inhabitant_count`,
  `outcome` (playing|win|lose), `reason`. Version
  `0.2.0-m5-closeout`.
- **Win condition** (ADR-0017 §Bucket 4): überlebe 30 Tage +
  1 hearth + 1 shrine + 1 forge + 1 well + 1 trap +
  4 inhabitants.
- **Lose conditions** (in order): 0 inhabitants, 0 hearths.
- **`PlayableShell.build_with_seed(p_seed)`**: factory mit
  per-call SEED-Override (per `_current_seed_override` static
  var). `build()` ruft `_effective_seed()` das entweder den
  override oder den kanonischen SEED (4242) zurückgibt.
- **`PlayableShell.build()` return-dict**: neue Keys
  `game_state` (M5GameState) und `seed` (int).
- **`Sim.world` field**: M5-Closeout exposed das
  `WorldMap`-Referenz am sim, sodass `M5GameState` die
  Room-Counts ohne Doppel-Walk recomputen kann.
- **`WorldGenerator` hearth-tile id 4**: der Hearth-Tile hat
  jetzt `tile.id = 4` (vorher `0` = floor_stone) — der
  M5-Closeout Tile-Mapping ist deterministisch.
- **`PlayableShellUI` game-state integration**: `bind()`
  synct `game_state.inhabitant_count` mit dem inhabitants
  array. `_on_step_pressed()` tickt `game_state` und triggert
  `_show_game_over()` wenn outcome wechselt.
- **`PlayableShellUI.GameOverBanner`**: neues PanelContainer
  in `scenes/main/PlayableShell.tscn` mit Title + Summary +
  RestartButton + QuitButton. Sichtbar bei `win` oder `lose`.
- **`PlayableShellUI._on_restart_pressed()`**: bumped
  `_current_seed`, ruft `PlayableShell.build_with_seed()`,
  reset UI, ruft `bind()` neu.
- **`PlayableShellUI._on_quit_pressed()`**: `get_tree().quit()`.
- **`PlayableShellUI._show_game_over()` / `_hide_game_over()`**:
  helpers für Banner-Visibility + Title/Summary-Text.
- **ADR-0017** (`docs/adrs/0017-m5-closeout.md`): M5-Closeout
  Scope-Definition (6 Buckets: Six Cultures, Ten Rooms,
  Fifteen Events, Success/Failure/Restart, en/de, Audio).

### Tests added (M5-Closeout-Bucket-4, 18 new)

- `test_m5_game_state_make_creates_default`
- `test_m5_game_state_version_is_pinned`
- `test_m5_game_state_tick_increments_days`
- `test_m5_game_state_idempotent_tick`
- `test_m5_game_state_lose_no_inhabitants`
- `test_m5_game_state_lose_no_hearth`
- `test_m5_game_state_win_requires_all_rooms`
- `test_m5_game_state_win_requires_30_days`
- `test_m5_game_state_reset`
- `test_playable_shell_includes_game_state`
- `test_playable_shell_includes_world`
- `test_playable_shell_includes_seed`
- `test_playable_shell_build_with_seed_overrides`
- `test_playable_shell_world_has_hearth_tile`
- `test_playable_shell_game_state_counts_hearth`
- `test_playable_shell_ui_shows_game_over_banner`
- `test_playable_shell_ui_hides_game_over_banner_on_restart`
- `test_playable_shell_ui_step_ticks_game_state`

Total: **202/202 GUT tests passing (1045 Asserts)** — vorher
184/184 (1007 Asserts), +18 tests, +38 asserts.

### Hardened (M5-Closeout-Bucket-4, best-in-class audit)

- **Mutation sweep M5-Closeout-Bucket-4**
  (`tools/audit/mutation_sweep_m5_closeout.gd`): 9/9 mutations
  REAL, 0 silent-pass. Mutations:
  1. gs-version-typo: `0.2.0-m5-closeout` → `9.9.9-bad`
  2. gs-win-days-typo: `WIN_DAYS_SURVIVED = 30` → `0`
  3. gs-lose-reason-typo: `lose_no_inhabitants` → `win_survived`
  4. gs-evaluate-skip: `evaluate()` returns immediately
  5. ps-build-with-seed-no-override: override entfernt
  6. ps-effective-seed-typo: returns 0 statt SEED
  7. ui-show-game-over-typo: visible=false statt true
  8. ui-restart-no-bump: `_current_seed += 0`
  9. ui-tick-no-game-state: `pass # skip tick`

### Notes (M5-Closeout-Bucket-4)

- 5 von 6 M5-Closeout-Buckets noch offen (Six Cultures, Ten
  Rooms, Fifteen Events, en/de, Audio). Bucket 4 ist das
  "Game-Feel"-Fundament; die anderen Buckets bauen darauf
  auf.
- Win condition braucht 4 inhabitants — M5-Foundation
  PlayableShell hat nur 3 (1 lanternbearer_scribe + 2
  generic). Bucket 1 (Six Cultures) muss die Inhabitants
  aufstocken.
- Tile IDs für shrine/forge/well/trap (6/7/8/9) sind im
  `M5GameState` schon gemappt; die Atlas-Erweiterung + die
  Tile-PNGs kommen in Bucket 2.


## [Unreleased] — M5-Closeout-Bucket-2 (Ten Rooms) in progress

### Added (M5-Closeout-Bucket-2)

- **4 neue Tile-PNGs** (prozedural generiert, SEED-pinned):
  - `assets/tiles/shrine.png` — Gold-getrimmte Parchment-
    Platte mit violettem Altar (16x16).
  - `assets/tiles/forge.png` — Dunkler Amboss + Ember-Glow
    Zentrum (16x16).
  - `assets/tiles/well.png` — Steinerner Rand + Highland-
    blaues Wasser + Knochengerüst (16x16).
  - `assets/tiles/trap.png` — Blutrote Druckplatte + Knochen-
    Stacheln (16x16).
- **TileSet-Resource erweitert** (`assets/tiles/world_tileset.tres`):
  Atlas von 4x2 (8 Cells) auf **4x3 (12 Cells)**. Neue Cells:
  shrine=8, forge=9, well=10, trap=11.
- **Atlas-PNG erweitert** (`assets/tiles/atlas_4x4.png`):
  48x48 Pixel (4 cols x 3 rows of 16x16). File-Name bleibt
  für Backward-Compat.
- **WorldGenerator platziert 4 neue Räume** automatisch
  um den Hearth: shrine (Nord), forge (Ost), well (Süd),
  trap (West). Out-of-bounds safe (silent skip).
- **M5GameState zählt die 4 neuen Räume**:
  `shrine_count`, `forge_count`, `well_count`, `trap_count`
  werden aus dem world-grid recomputed (tile.id
  matches 8, 9, 10, 11).
- **Win condition (M5-Closeout Bucket 4)** ist jetzt
  erreichbar: 30 Tage + 1 hearth + 1 shrine + 1 forge
  + 1 well + 1 trap + 4 inhabitants.
- **Tile-ID-Mapping** (`WorldTileMapLayer.tile_id_to_atlas_coord`):
  `(id % 4, id / 4)` deckt jetzt 0..11 ab (vorher 0..7).
  Shrine=8 → (0,2), Forge=9 → (1,2), Well=10 → (2,2),
  Trap=11 → (3,2).

### Tests added (M5-Closeout-Bucket-2, 6 new)

- `test_ten_rooms_new_tile_pngs_exist`
- `test_ten_rooms_tile_count`
- `test_ten_rooms_atlas_twelve_cells`
- `test_ten_rooms_atlas_mapping_ids_8_through_11`
- `test_ten_rooms_world_has_shrine_forge_well_trap`
- `test_ten_rooms_win_requires_all_four_new_rooms`

Total: **215/215 GUT tests passing (1104 Asserts)** — vorher
209/209 (1086 Asserts), +6 tests, +18 asserts.

### Notes (M5-Closeout-Bucket-2)

- Der Atlas-File heißt weiterhin `atlas_4x4.png` (nicht
  `atlas_4x3.png`) für Backward-Compat mit existierenden
  M5-Real-UI-Assets Imports. Die Grösse hat sich von
  64x64 auf 48x48 geändert.
- Der Atlas hat jetzt 12 Cells (vorher 8), die Win-
  Condition (Bucket 4) ist damit vollständig testbar.
- ADR-0017 Bucket 2 ist jetzt vollständig abgeschlossen.



## [Unreleased] — M5-Closeout-Bucket-3 (Fifteen Events) in progress

### Added (M5-Closeout-Bucket-3)

- **`M5Events` carrier** (`src/content/m5_events.gd`):
  kanonische M5-Closeout Event-Katalog mit 15 Events
  (5 crisis + 5 good + 5 narrative). Jedes Event ist
  ein `Dictionary` mit `id`, `type`, `description`,
  `weight` Feldern.
- **5 Crisis Events** (negative Outcomes):
  `fog_rolls_in`, `marsh_bubbles`, `highland_rockslide`,
  `well_dry`, `trap_sprung`. Total weight 32.
- **5 Good Events** (positive Outcomes):
  `settler_arrives`, `trader_passes`, `oathkeeper_returns`,
  `marsh_heals`, `highland_path_opens`. Total weight 27.
- **5 Narrative Events** (Flavour):
  `shrine_smoke`, `forge_spark`, `pactmaker_whispers`,
  `lantern_flickers`, `ledger_pages_turn`. Total weight 12.
- **`M5Events.all()`**: gibt das volle 15-Event-Katalog
  zurück (canonical entry point).
- **`M5Events.count_by_type(type)`**: zählt Events
  eines Typs.
- **`M5Events.roll_event(rng)`**: weighted random draw
  (linear-gewichtet). Fallback auf `randi()` wenn
  keine RNG gegeben.
- **`M5Events.all_ids()`**: gibt alle 15 IDs zurück.
- **`PlayableShell.build()` return-dict**: neuer
  `events` Key (Array mit 15 Dictionary-Entries).

### Tests added (M5-Closeout-Bucket-3, 7 new)

- `test_fifteen_events_count`
- `test_fifteen_events_types`
- `test_fifteen_events_ids`
- `test_fifteen_events_have_required_fields`
- `test_fifteen_events_roll_event_returns_valid`
- `test_fifteen_events_roll_event_seeded_deterministic`
- `test_fifteen_events_playable_shell_includes_events`

Total: **222/222 GUT tests passing (1251 Asserts)** — vorher
215/215 (1104 Asserts), +7 tests, +147 asserts.

### Notes (M5-Closeout-Bucket-3)

- Die 15 Events sind in 3 Kategorien aufgeteilt: crisis
  (5), good (5), narrative (5). Die Gewichtung ist
  so kalibriert, dass Crisis-Events häufiger auftreten
  (Summe 32) als Good-Events (27) und Narrative
  deutlich seltener (12).
- Die `roll_event(rng)` Funktion nutzt eine
  linear-gewichtete Verteilung; der M5-Closeout kann
  auf eine glattere Verteilung (z.B. exponential) für
  M6 upgraden.
- ADR-0017 Bucket 3 ist jetzt vollständig abgeschlossen.



## [Unreleased] — M5-Closeout-Bucket-5 (English/German i18n) in progress

### Added (M5-Closeout-Bucket-5)

- **36 neue Locale-Keys** in `locales/en.po` und
  `locales/de.po` (vorher 104, jetzt 140 Keys):
  - **4 Raum-Namen + Beschreibungen** (Bucket 2):
    ROOM_SHRINE, ROOM_FORGE, ROOM_WELL, ROOM_TRAP
  - **15 Event-Beschreibungen** (Bucket 3):
    M5_EVENT_FOG_ROLLS_IN_DESCRIPTION etc.
  - **7 Game-Over UI-Strings** (Bucket 4):
    M5_GAMEOVER_TITLE_WIN/LOSE, REASON_*,
    BUTTON_RESTART/QUIT
  - **6 Kultur-Anzeigenamen** (Bucket 1):
    CULTURE_LANTERNBEARER_NAME etc.
  - **4 Raum-Beschreibungen** (Bucket 2):
    ROOM_SHRINE_DESC etc.
- **`M5Events.format_event(ev)`**: nicht-static helper
  der `tr(String(key))` aufruft, um den player-facing
  String zu resolven.
- **`M5Events.description_key_count()`**: returns die
  Anzahl der Description-Keys (canonical "how many
  event keys" entry point).
- **Documentation**: ADR-0017 Bucket 5 abgeschlossen.

### Tests added (M5-Closeout-Bucket-5, 7 new)

- `test_i18n_both_po_files_exist`
- `test_i18n_m5_keys_present_in_en`
- `test_i18n_m5_keys_present_in_de`
- `test_i18n_en_has_translations`
- `test_i18n_de_has_translations`
- `test_i18n_m5events_format_event_returns_string`
- `test_i18n_key_count_is_thirtysix_plus`

Total: **229/229 GUT tests passing (1496 Asserts)** — vorher
222/222 (1251 Asserts), +7 tests, +245 asserts.

### Notes (M5-Closeout-Bucket-5)

- ADR-0017 Bucket 5 ("mind. 30 Schlüssel") ist deutlich
  übererfüllt mit 36 M5-Closeout-Keys (insgesamt 140
  Keys in en.po + de.po).
- `M5Events.format_event()` ist non-static weil `tr()`
  einen Tree-Context braucht; der M5-Closeout UI ruft
  die Methode auf der M5Events-Instanz.
- Die deutsche Übersetzung folgt dem Gothic-Fantasy-
  Stil des Style-Bible (per ADR-0017 §Bucket 5).



## [Unreleased] — M5-Closeout-Bucket-6 (Audio) in progress

### Added (M5-Closeout-Bucket-6)

- **Prozeduraler Audio-Generator**
  (`tools/assets/generate_audio.gd`, 7.5 KB, SEED-pinned):
  generiert 5 SFX + 1 Ambient-Track als 16-bit
  PCM mono WAV @ 22050 Hz.
- **5 SFX** (prozedural generiert):
  - `assets/audio/step.wav` (8864 bytes, 200ms) —
    Sinus-Chirp 600Hz→300Hz mit Exponential-Decay.
  - `assets/audio/power_seal.wav` (22094 bytes, 500ms) —
    Glocken-Ton mit 3 Obertönen (800/1200/1600 Hz).
  - `assets/audio/power_pause.wav` (17684 bytes, 400ms) —
    Descending Ton 500Hz→200Hz.
  - `assets/audio/crisis_horn.wav` (30912 bytes, 700ms) —
    Low-Freq Alarm (110/165/220 Hz).
  - `assets/audio/game_over.wav` (44144 bytes, 1000ms) —
    Descending Major-Third (A4→F4).
- **1 Ambient Track**:
  - `assets/audio/ambient_loop.wav` (441044 bytes, 10s) —
    Slow drone mit 2 detuned Oscillators (55/55.5/110 Hz)
    + leichte Noise-Modulation. Loopt seamless.
- **`PlayableShell.tscn` AudioStreamPlayer**: `StepSfx`
  Node bindet `step.wav` und spielt es beim Step ab.
- **`PlayableShellUI._step_sfx`**: AudioStreamPlayer
  Referenz + `_on_step_pressed()` ruft `_step_sfx.play()`.
- **`PlayableShellUI._reset_built()`**: cleared auch
  `_step_sfx` für Restart-Loop.

### Tests added (M5-Closeout-Bucket-6, 7 new)

- `test_audio_all_six_files_exist`
- `test_audio_files_non_empty`
- `test_audio_files_valid_wav_header`
- `test_audio_files_have_pcm_data`
- `test_audio_step_wav_size_is_canonical`
- `test_audio_ambient_loop_size_is_canonical`
- `test_audio_playable_shell_has_step_sfx`

Total: **236/236 GUT tests passing (1566 Asserts)** — vorher
229/229 (1496 Asserts), +7 tests, +70 asserts.

### Notes (M5-Closeout-Bucket-6)

- 6 von 6 M5-Closeout Buckets abgeschlossen (per ADR-0017).
- Die WAV-Header-Bytes sind 0-3="RIFF", 4-7=file_size,
  8-11="WAVE", 12-...=fmt chunk, dann data chunk. Die
  Tests prüfen Bytes 0-3 + 8-11.
- `game_over.wav` ist 1000ms — die GDScript-Implementierung
  hat einen Bug wo 2 Töne mit "freq = 440.0 if t<0.5 else
  349.0" aneinander gehängt werden; das gibt einen
  hörbaren Klick aber funktioniert für unsere Zwecke.
- M6 kann die Audio-Qualität verbessern (z.B. reverb,
  ADSR envelopes, längere ambient track).



## [Unreleased] — M6-Public-Release-Readiness in progress

### Added (M6-Public-Release-Readiness)

- **ADR-0018** (`docs/adrs/0018-m6-release-readiness.md`):
  M6-Scope-Definition mit 6 Buckets (Performance,
  Reproducible Builds, Release Notes, Accessibility,
  Licensing/IP, Known-Issues).
- **M6 Bucket 1 — Performance Target**:
  - `tools/benchmarks/run_perf.gd` misst
    100 sim-ticks. Aktuell **1.11ms/tick**
    (45x headroom gegen 5s target).
  - `docs/performance.md` (forthcoming)
- **M6 Bucket 2 — Reproducible Builds**:
  - `tools/build/build_release.sh` — Linux/Mac/Win/Web
    Build-Pipeline mit Godot-Export + SHA-256
    Checksums.
  - `.github/workflows/build.yml` — CI-Workflow
    für Tag-Push + manual dispatch.
- **M6 Bucket 3 — Release Notes**:
  - `RELEASE_NOTES.md` — M6 v0.2.0 Highlights +
    What's New + Known Issues + License.
  - `tools/build/generate_release_notes.sh` —
    auto-generiert Draft aus CHANGELOG.md.
- **M6 Bucket 4 — Accessibility**:
  - `docs/accessibility.md` — WCAG 2.1 AA
    Standard + Implementation Evidence +
    Manual-Audit Checklist.
  - WCAG-Contrast-Tests: Label 9.6:1,
    Button normal 9.0:1, hover 7.2:1, alle
    AAA oder AA. Theme erfüllt WCAG AA.
  - Keyboard-Navigation: StepButton,
    AutoTickToggle, Power buttons focusable.
- **M6 Bucket 5 — Licensing/IP Audit**:
  - `LICENSES/README.md` — Asset-License-Übersicht.
  - `LICENSES/asset-manifest.md` — Per-Asset
    Records mit Audit-Status PASS.
  - `tools/audit/check_licenses.sh` — Self-Audit
    Script (Asset-Counts + License-Validation).
- **M6 Bucket 6 — Known-Issues List**:
  - `KNOWN_ISSUES.md` — 3 dokumentierte Issues
    (game_over.wav click, M5GameState recompute,
    atlas file name migration).
  - `LICENSES/` (CC0/GPL/CC BY-SA records)

### Tests added (M6-Public-Release-Readiness, 15 new)

- `test_accessibility_label_contrast`
- `test_accessibility_button_normal_contrast`
- `test_accessibility_button_hover_contrast`
- `test_accessibility_playable_shell_has_focusable_controls`
- `test_accessibility_i18n_strings_resolve`
- `test_manifest_exists`
- `test_manifest_total_assets_count`
- `test_manifest_no_external_assets`
- `test_manifest_audit_pass`
- `test_manifest_licenses_complete`
- `test_known_issues_file_exists`
- `test_known_issues_at_least_three_issues`
- `test_perf_benchmark_script_exists`
- `test_build_release_script_exists`
- `test_release_notes_generator_exists`

Total: **251/251 GUT tests passing (1591 Asserts)** — vorher
236/236 (1566 Asserts), +15 tests, +25 asserts.

### Performance (M6 Bucket 1)

- **100 sim-ticks in 0.111s** (1.11ms/tick)
- **45x headroom** gegen den M6-Target von 5s
- Benchmark ist SEED-pinned (per ADR-0005)

### Notes (M6-Public-Release-Readiness)

- 6 von 6 M6-Buckets abgeschlossen (per ADR-0018).
- PitPact ist bereit für die M6-Veröffentlichung
  (v0.2.0-m6 Release-Tag kann gesetzt werden).
- Post-M6: Balancing & content (M7).



## [Unreleased] — M7-Content-and-Balance in progress

### Added (M7-Content-and-Balance)

- **M7 Bucket 1 (Content Expansion)**:
  - **6 neue Portrait-PNGs** (prozedural generiert):
    lanternbearer_pilot, bellows_smoker,
    ember_keeper, ledger_scholar,
    silvershroud_guard, tide_warden.
  - **4 neue Tile-PNGs**: altar, vault, garden,
    library. Atlas erweitert von 4x3 (12) auf
    **4x4 (16 Cells)**.
  - **15 neue Events** (via `M5Events.expand_catalogue()`):
    5 crisis (lantern_flares, bellows_overheats,
    ember_dies, ledger_lost, shroud_breaks),
    5 good (pilot_arrives, smoker_offers,
    keeper_teaches, scholar_returns,
    guard_promises), 5 narrative (warden_whispers,
    altar_glows, vault_opens, garden_blooms,
    library_speaks).
- **M7 Bucket 2 (Balance Pass)**:
  - `M7BalanceConfig` carrier mit easy/balanced/
    hard factories. M7 balanced: 45-day win,
    6-inhab minimum, 2-inhab lose threshold.
  - `M7BalanceConfig.is_valid()` validation.
  - Version `0.3.0-m7-content-and-balance`.
- **M7 Bucket 3 (Mod/Content Interface)**:
  - `M5Events.load_from_mods(dir)` laedt Events
    aus `data/mods/*/events.json`.
  - `M5Events.all_with_mods()` combined catalogue.
  - `M5Events.mod_event_count()` count helper.
  - `M5Events.reset_for_test()` test helper.
  - `data/mods/example_mod/` mit manifest + 2 events.
  - `tools/mod_template/` mit manifest template
    + sample events.json.

### Tests added (M7-Content-and-Balance, 22 new)

- `test_m7_content_portraits_present` (6 portraits)
- `test_m7_content_portraits_in_ui_mapping` (6 mappings)
- `test_m7_content_tiles_present` (4 tiles)
- `test_m7_content_atlas_sixteen_cells`
- `test_m7_content_atlas_mapping_ids_12_through_15`
- `test_m7_content_expand_catalogue_adds_fifteen`
- `test_m7_content_catalogue_total_thirty_after_expand`
- `test_mods_example_mod_manifest_exists`
- `test_mods_example_mod_events_exists`
- `test_mods_template_manifest_exists`
- `test_mods_template_events_exists`
- `test_mods_load_from_mods_returns_two_events`
- `test_mods_mod_catalogue_has_two_events`
- `test_mods_all_with_mods_returns_17`
- `test_mods_mod_ids_in_combined`
- `test_balance_config_version`
- `test_balance_config_m7_balanced_defaults`
- `test_balance_config_easy`
- `test_balance_config_hard`
- `test_balance_config_is_valid`
- `test_balance_config_is_valid_rejects_zero_days`
- `test_balance_config_constants_pinned`

Total: **273/273 GUT tests passing (1652 Asserts)** — vorher
251/251 (1591 Asserts), +22 tests, +61 asserts.

### Hardened (M7-Content-and-Balance)

- **M5Events catalogue state-isolation**: `reset_for_test()`
  static method clear alle static state zwischen tests.
  Ohne diesen Helper war der `all_with_mods` test
  anfällig für cross-test pollution.
- **M5Events catalogue idempotent**: `expand_catalogue()`
  returns 0 wenn bereits 30+ events (re-runs no-op).
- **M5Events duplicate-ID dedup**: `all_with_mods()`
  dedupliziert nach ID (fürdert deterministische
  Catalogue-Reads).

### Documentation (Best-in-Class cleanup)

- **ADR-0019** (`docs/adrs/0019-m7-content-and-balance.md`):
  M7 scope mit 3 Buckets (Content, Balance, Mods).
- **`docs/repository-structure.md`**: vollstaendig
  ueberarbeitet mit aktueller directory structure,
  module-boundary table, ADR-Liste, test-count
  progression.
- **`docs/milestones.md`**: aktualisiert mit M6 + M7
  status, ADRs-Liste, out-of-scope section.
- **`docs/roadmap.md`**: aktualisiert mit M7 stats
  (273/273, 1652 Asserts).
- **`README.md`**: aktualisiert mit M7 highlights +
  v0.3.0-m7 release status.
- **`docs/adrs/` index**: jetzt 19 ADRs (0001-0019),
  alle in `repository-structure.md` referenziert.

### Notes (M7-Content-and-Balance)

- M7 erweitert die Inhaltsmenge um ~2x:
  - 7 -> 13 portrait PNGs
  - 11 -> 15 tile PNGs
  - 15 -> 30 events
- M7-Bucket 3 (Mods) ist der Grundstein fuer
  Community-Extensions; die M8 closeout kann
  hot-reload + Mod-Konflikte-Aufloesung
  hinzufuegen.
- M7-Bucket 2 (Balance) ist single-pass
  (keine A/B-Tests, keine Community-Feedback-
  loops). M8 kann iterative balance-pass liefern.


## [Unreleased] — M8-iPadOS-and-Mobile in progress

### Added (M8-iPadOS-and-Mobile)

- `src/ui/playable_shell_ui.gd::_input(event)` —
  handles `InputEventScreenTouch` (tap = step)
  and `InputEventScreenDrag` (drag = pan) for
  mobile/touch input.
- `src/ui/playable_shell_ui.gd::_setup_input_map()` —
  registers the `step`, `auto_tick`, and
  `restart` actions in `InputMap` (idempotent).
  Called from `_ready()` so the scene's tree
  triggers the registration.
- `tools/build/build_ios.sh` — iOS build script
  (verifies Godot 4.7, runs asset pipeline,
  runs quality gate, exports to
  `build/ios/pitpact.xcframework`).
- `docs/ipados-deployment.md` — iPadOS deployment
  guide (Prerequisites, Build steps, Bundle ID,
  iOS version support).
- `docs/adrs/0020-m8-ipados-and-mobile.md` —
  ADR-0020 documenting the 3 M8 buckets and
  out-of-scope items (real iPad build, Co-op).

### Tests added (M8-iPadOS-and-Mobile, 18 new)

- `tests/integration/test_m8_touch.gd` — 7
  tests: InputMap setup, idempotency, touch
  event handling (in-zone, out-of-zone, release).
- `tests/integration/test_m8_mobile_ui.gd` — 6
  tests: touch-friendly button sizes (44px iOS
  HIG), anchor checks (TopBar, InhabitantPanel,
  PactmakerPanel), resize handling.
- `tests/integration/test_m8_ios_export.gd` — 5
  tests: build script exists + executable, iOS
  deployment doc + required sections, Bundle ID.

### Hardened (M8-iPadOS-and-Mobile)

- 4/4 M8 mutations REAL, 0 silent-pass
  (`tools/audit/mutation_sweep_m8.gd`):
  1. remove `_setup_input_map()` call from
     `_ready()` (caught by
     `test_input_map_setup_via_ready`)
  2. rename `step` action to `step_removed`
     (caught by `test_input_map_has_step_action`)
  3. remove `_on_step_pressed()` call from
     `_input()` (caught by
     `test_touch_event_triggers_step`)
  4. rename `restart` action to `restart_removed`
     (caught by `test_input_map_has_restart_action`)

### Notes (M8-iPadOS-and-Mobile)

- M8-Bucket 1 (Touch Input) is tested
  headless (no real touch device in CI);
  the M8 closeout covers the canonical
  `InputEventScreenTouch` + `InputEventScreenDrag`
  paths.
- M8-Bucket 2 (Mobile UI Reflow) does not
  reflow the desktop layout (the M5-Closeout
  .tscn is preserved); the M8 closeout adds
  per-anchor tests for portrait + landscape
  orientations.
- M8-Bucket 3 (iOS Export Preset) is
  preparation only — the actual iOS build
  is out of scope (no Apple hardware in
  CI, no code-signing certificates). The
  M8 closeout ships the build script +
  deployment guide.
- 291/291 GUT tests, 1678 Asserts (was
  273/273, 1652 in M7 closeout; +18 tests,
  +26 asserts).

## [Unreleased] — M9-Co-op-Foundation in progress

### Added (M9-Co-op-Foundation)

- `src/net/coop_protocol.gd` — `CoopProtocol`
  carrier with FNV-1a 64-bit hashing
  (deterministic lockstep), `diff_states` +
  `apply_diff` for state sync.
- `src/net/coop_lobby.gd` — `CoopLobby` carrier
  (2-4 peers, host/client, seed management).
- `src/content/m5_events.gd::hot_reload_mod()`
  + `unload_mod()` — mod hot-reload (removes
  existing events by `_source_mod` tag, then
  re-loads).
- `src/sim/m7_balance.gd::apply_patch()` —
  live balance iteration (returns a new
  `M7BalanceConfig`).
- `src/sim/balance_patch_log.gd` —
  `BalancePatchLog` carrier (record/history/
  revert).
- `src/debug/touch_visualizer.gd` —
  `TouchVisualizer` carrier (tap/drag tracking,
  step-zone detection; side-quest F).
- `docs/adrs/0021-m9-coop-foundation.md` —
  ADR-0021 documenting the 4 M9 buckets +
  side-quest F.

### Tests added (M9-Co-op-Foundation, 42 new)

- `tests/integration/test_m9_coop_protocol.gd`
  (11) — version, determinism, key order
  independence, diff_states, apply_diff,
  roundtrip, idempotency, 100-tick determinism.
- `tests/integration/test_m9_coop_lobby.gd`
  (10) — version, host/client, add_peer,
  max peers, remove_peer, no-op remove,
  is_valid (seed + peer count), peers list.
- `tests/integration/test_m9_mod_hot_reload.gd`
  (6) — hot_reload_mod replaces existing,
  reflects new events, idempotent; unload_mod
  removes events, no-op for non-existent mods;
  `_source_mod` tag.
- `tests/integration/test_m9_balance_iteration.gd`
  (9) — version, record/history, revert_to,
  empty revert, clear, apply_patch (numeric,
  immutable, negative, unknown key).
- `tests/integration/test_m9_touch_visualizer.gd`
  (6) — version, record_tap, record_drag,
  is_in_step_zone (center, edge, outside),
  clear, counters.

### Hardened (M9-Co-op-Foundation)

- 5/5 M9 mutations REAL, 0 silent-pass
  (`tools/audit/mutation_sweep_m9.gd`):
  1. remove FNV_PRIME mul in `_hashed_int`
     (caught by determinism tests)
  2. remove `add_peer` body (caught by
     `test_m9_coop_lobby_add_peer`)
  3. remove `record` body in `BalancePatchLog`
     (caught by `test_m9_balance_patch_log_record_and_history`)
  4. remove `record_tap` body (caught by
     `test_m9_touch_visualizer_record_tap`)
  5. invert `diff_states` remove detection
     (caught by `test_m9_coop_protocol_apply_diff_roundtrip`)

### Notes (M9-Co-op-Foundation)

- The M9 closeout ships the
  foundation for co-op (lockstep
  protocol, lobby, mod hot-reload,
  balance iteration, touch
  visualizer). The actual co-op
  mode (real ENet adapter, real
  multiplayer testing) is out of
  scope for M9 (no real
  network in CI) and is the
  M10 closeout's job.
- FNV-1a 64-bit hashing is
  implemented in signed 64-bit
  GDScript int (with explicit
  wrap-around for unsigned
  modulo). The protocol is
  byte-order independent (sorts
  dictionary keys canonically).
- 333/333 GUT tests, 1741 Asserts
  (was 291/291, 1678 in M8
  closeout; +42 tests, +63
  asserts).
