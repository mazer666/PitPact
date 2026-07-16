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
Godot 4.7+ headless, with **149/149 GUT tests
passing in ~0.73s / 882 Asserts** (GUT 9.4.0,
Godot 4.7+) covering the integrated M0–M4 whole.
See the M0-Closeout, M1-Closeout, M2-Closeout,
M3-Closeout, M4-foundation, and M4-Closeout
entries below for the detailed histories.

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
