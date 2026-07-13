---
status: accepted
date: 2026-07-13
deciders: project leads
consulted: contributors
informed: all contributors
---

# 2. Module boundaries and data flow

## Context and problem statement

`docs/repository-structure.md` already defines eight top-level GDScript
modules under `src/`: `core`, `world`, `sim`, `realm`, `content`,
`save`, `ui`, `audit`. §16 of `docs/requirements.md` requires that
"deterministic game-domain logic" be kept separate from "Godot
scene/UI code". §17 makes the per-module README contract (purpose,
responsibility, public entry point, main dependencies) explicit.

Without a written contract for the *public surface* of each module,
the eight-module layout will decay on contact with the first feature
PR. Imports creep "upward" (UI pulls in game-domain, then game-domain
calls back into UI through singletons), scenes start calling deep
into simulation internals, and the deterministic-replay guarantee
called out in §16 of the requirements spec becomes a fiction.

We need a load-bearing rule that:

1. defines what every module is *for*,
2. exposes the single public entry point every other module is
   allowed to depend on,
3. names what each module is *not* allowed to depend on, and
4. is mechanically checkable from CI without running the game.

## Decision drivers

- **Determinism.** The game-domain must remain reproducible from a
  seed (§7, §16). The only way to keep that promise is to forbid
  scene-tree and UI calls inside the simulation.
- **Replaceability.** `src/ui/` is the layer most likely to be
  rewritten (Godot 4 → Godot 5, mobile renderer, accessibility pass).
  Everything beneath it must survive a UI rewrite.
- **Testability.** §18 requires the local quality suite to run unit
  tests in a headless Godot. That is only possible if game-domain
  code does not require a `SceneTree` or a viewport.
- **Discoverability.** A new contributor should be able to open any
  module's README and learn its public surface in under a minute.
- **Mechanical enforcement.** "Please don't" is not a rule. The
  boundary must be checkable from a script — that is what
  `tools/check_module_dependencies.sh` exists for.

## Considered options

1. **Strict layered architecture, no exceptions, mechanically
   enforced** (this) — game-domain modules have no path to
   `src/ui/`; the check is a static scan of `src/<x>/*.gd` for
   `res://src/ui/` references.
2. **Layered architecture with a narrow "view-model" seam** — UI is
   forbidden from importing simulation, but a hand-picked "view"
   layer is allowed to mediate. Rejected: it pushes the boundary
   problem one layer inward without solving it, and the view layer
   inevitably becomes a junk drawer.
3. **Convention-only, no enforcement** — README files describe the
   rules, code review enforces them. Rejected: the project already
   has six cultures, ten rooms, fifteen events in its M5 scope; a
   human-only boundary does not survive that surface area.
4. **Flat module structure with feature folders.** Rejected: the
   eight-module split already exists in `docs/repository-structure.md`
   and `src/` and is referenced by the requirements spec. The
   boundary work is needed regardless of folder layout.

## Decision outcome

Chosen option: **Strict layered architecture, no exceptions, mechanically
enforced.**

### Module responsibilities and public surfaces

The public surface of each module is the set of symbols documented
in that module's README. Everything else is module-private and may
change without coordination. Cross-module edits that change a public
surface require an ADR.

For each module below: **Purpose** — what it is for; **Responsibility**
— the behavioural contract; **Public entry point** — the single
top-level symbol other modules are expected to depend on; **Main
dependencies** — what it is allowed to import; **Must NOT depend
on** — what it is forbidden to import (and why).

#### `src/core` — Primitives

- **Purpose.** Engine-agnostic primitives: deterministic RNG, math
  helpers, time/clock types, event-id types, hashing, the canonical
  data containers used by every other module.
- **Responsibility.** No Godot `Node`, `Resource`, or scene-tree
  types. Pure GDScript classes. Importing this module is cheap and
  side-effect-free.
- **Public entry point.** `class_name PitPactCore` (a static
  autoload-free namespace) plus the public classes inside
  `src/core/*.gd` (e.g. `SplitMix64`, `EventId`, `GameTime`).
- **Main dependencies.** None — `src/core` is the bottom of the
  stack.
- **Must NOT depend on.** Everything else in `src/`, and anything
  under `res://scenes/`, `res://data/`, `res://locales/`, or
  `res://addons/`. This module is the only one that is allowed to
  have zero upstream dependencies.

#### `src/world` — Spatial state

- **Purpose.** The static-to-slowly-changing spatial layer: tile
  grid, terrain, zones, rooms (lifecycle), spatial indices.
- **Responsibility.** Stores and queries the spatial state of a
  realm. Reads from `src/content` for definitions (biomes, tile
  types, room types). Does not run inhabitants.
- **Public entry point.** `class_name WorldState` (one instance per
  realm; created by `src/realm`).
- **Main dependencies.** `src/core`, `src/content`.
- **Must NOT depend on.** `src/sim`, `src/realm`, `src/save`,
  `src/ui`, `src/audit`. In particular, world has no opinion on
  *who* is in a room — that is `src/sim`.

#### `src/sim` — Simulation

- **Purpose.** Tick-based, deterministic simulation: inhabitants,
  needs, contracts, tasks, relationships, event memory.
- **Responsibility.** Advances the simulation by one tick when asked.
  Reads from and writes to the spatial state in `src/world`. Reads
  content from `src/content`. Emits events to `src/audit`.
- **Public entry point.** `class_name Simulation` (one instance per
  realm, owned by `src/realm`).
- **Main dependencies.** `src/core`, `src/world`, `src/content`,
  `src/audit`.
- **Must NOT depend on.** `src/realm`, `src/save`, `src/ui`.
  Determinism is non-negotiable — no scene tree calls, no `print`
  to the user, no wall-clock time inside the tick.

#### `src/realm` — Realm façade

- **Purpose.** The single object the UI sees. Composes `src/world`
  and `src/sim` into a player-visible "realm" view.
- **Responsibility.** Owns the lifecycle of one realm instance
  (create, load, tick, save, teardown). Routes player commands to
  the right subsystem. Aggregates the view models the UI binds to.
- **Public entry point.** `class_name Realm` (one instance per
  loaded realm; created by `src/realm`'s `RealmFactory`).
- **Main dependencies.** `src/core`, `src/world`, `src/sim`,
  `src/content`, `src/save`, `src/audit`.
- **Must NOT depend on.** `src/ui`. The façade's job is to *hide*
  the simulation, not to project it onto the screen.

#### `src/content` — Data-driven definitions

- **Purpose.** Pure data adapters for versioned content:
  biomes, resources, room definitions, inhabitant cultures,
  contracts, research, origins, events.
- **Responsibility.** Loads, validates, and serves content
  definitions. Pure data; no behaviour beyond validation and
  lookup.
- **Public entry point.** `class_name ContentRegistry` (a single
  process-wide registry).
- **Main dependencies.** `src/core`.
- **Must NOT depend on.** `src/world`, `src/sim`, `src/realm`,
  `src/save`, `src/ui`, `src/audit`. Content is data; it does not
  know which world it is being loaded into.

#### `src/save` — Persistence

- **Purpose.** Versioned save/load, plus the migration chain
  defined in ADR-0003.
- **Responsibility.** Serialises a `Realm` (and its dependencies)
  to the format pinned in ADR-0003, with format-versioning,
  migration, and tamper detection. Knows nothing about *what* a
  realm is; it just round-trips a `Dictionary` payload through the
  registered adapters.
- **Public entry point.** `class_name SaveService` (a single
  process-wide service).
- **Main dependencies.** `src/core`. Optionally, at the call site,
  `src/realm` — but `src/save` itself only sees the canonical
  payload shape, not the realm.
- **Must NOT depend on.** `src/ui`, `src/audit`. The save pipeline
  must work in a headless test.

#### `src/ui` — Presentation

- **Purpose.** Godot scenes, controllers, the input map, the
  camera, the minimap, the inspector.
- **Responsibility.** Observes the realm façade and projects it
  onto a screen. Owns no game state.
- **Public entry point.** The `Realm` scene (the autoload
  controller, not the gameplay state).
- **Main dependencies.** `src/realm`, `src/content` (for display
  data only). May import from `src/audit` to render the event log.
- **Must NOT depend on.** `src/core`, `src/world`, `src/sim`,
  `src/save` directly. UI talks to the realm façade and the
  content registry, not to the lower layers. This is the load-bearing
  rule and the one that is mechanically enforced.

#### `src/audit` — Diagnostics

- **Purpose.** Event log, diagnostic snapshots, replay/seed
  manifests. Read-only on the simulation.
- **Responsibility.** Receives events emitted by the simulation
  and the realm façade; persists and replays them. Exposes
  read-only queries ("what happened in tick 137?", "give me the
  seed manifest for this run").
- **Public entry point.** `class_name AuditLog` (one instance per
  realm).
- **Main dependencies.** `src/core`.
- **Must NOT depend on.** `src/world`, `src/sim`, `src/realm`,
  `src/save`, `src/ui`. The audit layer must remain a passive
  observer so that simulation determinism is not perturbed by
  diagnostic collection.

### The data-flow rule (load-bearing)

> **Deterministic game-domain modules** —
> `src/core`, `src/world`, `src/sim`, `src/realm`, `src/content`,
> `src/save` — **MUST NOT import from `src/ui`.**
>
> **UI imports game-domain modules; never the other way.**

Concretely, the following dependency graph is the contract. An
arrow `A → B` means "A is allowed to import from B".

```
src/core        → (nothing)
src/content     → src/core
src/audit       → src/core
src/save        → src/core
src/world       → src/core, src/content
src/sim         → src/core, src/world, src/content, src/audit
src/realm       → src/core, src/world, src/sim, src/content, src/save, src/audit
src/ui          → src/realm, src/content, src/audit
```

The graph is acyclic. A new module may be added by writing a new
ADR that defines its place in the graph and updates this one.

### Mechanical enforcement

`tools/check_module_dependencies.sh` parses the static type
references (`preload`, `load`, `class_name`-based references) in
`src/<x>/*.gd` and asserts the rule. It runs as part of
`tools/run_quality.sh` and the CI confirmation suite. A violation
fails the build.

The check is deliberately conservative:

- It allows imports from the *same* module.
- It allows imports from any module lower in the graph above.
- It forbids imports from `src/ui/` from any game-domain module.
- It does not parse full GDScript AST; it greps for the literal
  `res://src/<other_module>/` and `res://src/ui/` strings. That is
  enough to catch the realistic violations and fast enough to run
  in CI.

### Consequences

- Good, because the deterministic-replay guarantee stops being a
  promise and becomes a property the build verifies.
- Good, because the UI layer can be rewritten (Godot 4 → Godot 5,
  mobile renderer, accessibility rework) without touching anything
  beneath it.
- Good, because the contract is small enough to read in one sitting
  — eight modules, eight READMEs, one mechanical check.
- Bad, because there is a temptation to "just one more import" to
  ship a feature faster. The CI check exists to push back.
- Bad, because a legitimate cross-cutting feature (e.g. a tooltip
  that needs simulation data) must be routed through the realm
  façade. That extra hop is the price; it is worth it.
- Bad, because the check is grep-based and not AST-based. A
  sufficiently obfuscated import can evade it. We accept this
  trade-off in exchange for the check being a 30-line shell
  script with no Godot dependency.

### Confirmation criteria

This ADR is considered effective when:

- [ ] Every `src/<module>/README.md` exists and follows the §17
      contract (purpose, responsibility, public entry point, main
      dependencies).
- [ ] `tools/check_module_dependencies.sh` exists, is executable,
      and exits 0 against the current tree.
- [ ] `tools/run_quality.sh` invokes the check.
- [ ] `.github/workflows/ci.yml` invokes the check.
- [ ] The dependency graph above is encoded as data inside the
      check (so that adding a new allowed edge is a one-line edit
      with a test).

## Pros and cons of the options

### Strict layered architecture, no exceptions, mechanically enforced

- Good, the rule is checkable.
- Good, the rule is small.
- Good, the eight-module split already exists.
- Bad, the layer hop is annoying for cross-cutting UI features.

### Layered architecture with a "view-model" seam

- Good, gives UI a place to live that touches simulation data.
- Bad, the view layer becomes a junk drawer.
- Bad, pushes the boundary problem one layer inward.

### Convention-only

- Good, no tooling.
- Bad, does not scale to M5 surface area.
- Bad, every PR is a code-review negotiation.

### Flat module structure with feature folders

- Good, easy to find the code for a feature.
- Bad, the eight-module split is already in the spec.
- Bad, cross-cutting concerns (audit, save) have nowhere clean to
  live.

## More information

- `docs/repository-structure.md` — the eight-module layout this
  ADR formalises.
- `docs/requirements.md` §16 (technical architecture), §17 (code
  quality and AI-agent rules), §18 (testing and local quality
  gates).
- ADR-0001 (record architecture decisions).
- ADR-0003 (save format) — the boundary the save format respects.
- ADR-0004 (spatial model) — what `src/world` actually models.
- `tools/check_module_dependencies.sh` — the mechanical check.
- `tools/run_quality.sh` — the local suite that runs the check.
