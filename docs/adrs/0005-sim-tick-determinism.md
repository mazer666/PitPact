---
status: accepted
date: 2026-07-14
deciders: project leads
consulted: contributors
informed: all contributors
---

# 5. Sim-tick determinism

## Context and problem statement

`docs/requirements.md` §16 says the game "must support
deterministic replay of generator seeds and test scenarios" and
that "deterministic game-domain logic" must be "separated from
Godot scene/UI code wherever practical". §9 (inhabitants),
§10 (resources and progression) and §11 (conflict and crises)
all place the inhabitant roster, needs, contracts, tasks,
relationships, and event memory on a single, tick-based
timeline that is read back to the player through the event log
and the realm inspector. M2 is the milestone that lands the
inhabitant roster, the contract loop, the task queue, the
relationship graph, and the event memory in `src/sim/`.

Without a written contract for **how a sim tick is ordered,
who owns the per-tick random state, and what the
deterministic-replay invariant is**, the M2 commit will ship
skeletons in one order and fill them in a different order
across the two parallel tracks that follow. The first time a
relationship decay, a crisis resolution, and a contract breach
race inside the same tick, the order of operations will have
been chosen by whoever wrote the first PR — and the choice
will be invisible in code review, untested by the local
quality suite, and a regression risk for the save/load
pipeline pinned in ADR-0003.

We need a contract that:

1. pins the *order* of operations inside a single tick,
2. names the *one* module that owns the per-tick RNG state,
3. makes the deterministic-replay invariant a property the
   build can test, and
4. does not over-constrain the next two tracks' freedom to
   fill in the rules (decay rates, contract evaluation,
   crisis resolution) — the order is fixed; the contents of
   each step are not.

## Decision drivers

- **Determinism.** §16. The sim must reproduce the same state
  at the same tick for the same seed and the same input
  events. The order of operations inside a tick is the
  single most important contributor to this property; once
  it is fixed, the rest of the determinism story is "do not
  read the wall clock, do not call `randi()`, do not let
  the UI peek at state mid-tick".
- **Replaceability.** §16, §17. The sim is a deterministic
  game-domain module. The rule "sim owns the RNG, every
  other module receives a read-only handle" is what makes
  `src/audit/` able to replay a campaign from an event log
  alone, and what makes the M5 "replay a crisis" feature
  possible without re-running the world generator.
- **Testability.** §18. The local quality suite runs GUT
  in a headless Godot. A sim-tick contract that can be
  exercised by a unit test ("tick N times with the same
  seed and the same input events; assert deep-equal state")
  is what lets us catch tick-order regressions in CI.
- **Parallel-tracks safety.** M2 ships in two parallel
  tracks after this skeleton lands. Track A fills in
  inhabitants, needs, tasks, and event memory. Track B
  fills in contracts, relationships, and crises. The
  tick-order contract is the meeting point: if the order
  is pinned here, the two tracks can be developed
  independently and the integration test (replay a tick
  with both tracks active) is a one-file check.

## Considered options

1. **Fixed-order sim-tick, sim owns the RNG, replay
   invariant is "same seed + same input events ⇒ same
   state at every tick"** (this). The order is documented
   in this ADR and the public entry point's docstring.
2. **Event-driven sim with no fixed tick order.** Rejected:
   event-driven sims are powerful for "lots of independent
   things reacting to lots of independent things", but
   PitPact's M5 surface area is one timeline that the
   player reads back as a sequence. A fixed-order tick is
   the right tool for that game; an event-driven sim
   would put the determinism burden on the event queue's
   tie-breaking rules and would make save/load replay
   harder to test.
3. **Fixed-order sim-tick but multiple RNGs (one per
   subsystem).** Rejected: the M2 surface area is small
   enough that one RNG is enough, and one RNG makes the
   deterministic-replay invariant a one-line property of
   the sim state. Multiple RNGs would buy parallelism
   that the M2 does not need and would force every
   subsystem to coordinate its own seed.
4. **Free-order sim-tick, "the order is whatever the
   callers do".** Rejected: the determinism story
   collapses. Two PRs that happen to call the same
   subsystems in a different order would produce two
   different campaigns from the same seed. The CI cannot
   catch that without an explicit order.

## Decision outcome

Chosen option: **Fixed-order sim-tick, sim owns the RNG,
replay invariant is "same seed + same input events ⇒ same
state at every tick"**.

### The tick contract

A single call to `Sim.tick(delta_days, inhabitants, events)`
advances the simulation by `delta_days` in-game days. The
tick is a pure function on the inhabitants array, the events
array, and the sim's own RNG state; it does not read the
wall clock, does not call into the scene tree, and does not
talk to the realm façade.

The order of operations inside a tick is fixed and is
exactly the following sequence. Each step receives a
read-only handle to the sim's RNG; no step is allowed to
seed, re-seed, or stash a handle for later.

1. **RNG draw.** Pull a fresh batch of uniform random values
   from the per-tick RNG. Every subsequent step that needs
   randomness draws from this batch (or, for the rare
   step that needs more than the batch, continues to draw
   from the same handle). The batch is per-tick; a step
   may not draw across tick boundaries.
2. **Needs decay.** Each inhabitant's `Needs` are decayed
   by `TUNING_NEED_DECAY_PER_DAY * delta_days`. Recovery
   (eating, sleeping, working in a safe room) is applied
   in the same step. The decay is the first thing that
   happens, so subsequent steps see a representative
   mid-day need level rather than a yesterday-shaped one.
3. **Task progress.** Each open `Task` advances its
   `progress` by the work the assigned inhabitant can
   produce this tick. Tasks assigned to absent or
   deceased inhabitants are no-ops. A task whose progress
   reaches its `goal` is *completed* in this step and
   emits a `task.completed` event to the event log.
4. **Event-memory recording.** Any event whose `time_days`
   falls inside `[time_days, time_days + delta_days)` is
   recorded into each affected inhabitant's `EventMemory`.
   This step does not *decide* which events to emit; that
   is the previous steps' job. It only *records* the events
   the previous steps have already emitted. The
   recording happens *after* task progress so a
   `task.completed` event is visible to memory in the same
   tick it was produced.
5. **Relationships update.** Each `Relationship` edge is
   updated based on the events recorded in step 4 and on
   the inhabitants' current `Needs` from step 2. The
   per-edge change rate is
   `TUNING_RELATIONSHIP_DRIFT_PER_DAY * delta_days`. A
   relationship whose two endpoints have just experienced
   a `conflict` or a `contract.fulfilled` event sees an
   additional, content-driven delta on top of the drift.
6. **Event-log append.** The tick's events (the same
   events that step 4 recorded into memory) are appended
   to the append-only `EventLog` with their `time_days`
   set to `time_days + delta_days`. The append is the
   *last* step so the event log is consistent with the
   state produced by all the earlier steps. A
   `crisis.resolved` event is appended here, *not* in
   the crisis step (there is no "crisis step" in M2's
   skeleton; crises are content, scheduled in the
   track-B PR).

After step 6, the sim's `time_days` is advanced by
`delta_days` and the tick returns.

### The RNG ownership rule

`Sim` (the façade in `src/sim/sim.gd`) is the **only**
owner of the per-tick RNG state. The RNG is a `SplitMix64`
instance (see `src/core/rng.gd`); it is held in a private
member of `Sim` and is *never* exposed as a public
property.

Subsystems that need randomness — `Inhabitant`, `Needs`,
`Contract`, `Task`, `Relationship`, `EventMemory`,
`EventLog`, `Crisis` — receive a **read-only handle** to
the RNG for the duration of one tick. The handle
exposes `next_u64()`, `next_float()`, and `next_int(lo,
hi)`; it does *not* expose `snapshot()`, `restore()`,
`save_state()`, or `load_state()`. The handle is a
`RefCounted` value passed by value (GDScript's default
pass semantics); copying the handle does *not* give the
copy a fresh state, and the handle is invalidated at
the end of the tick.

The rule, in one sentence: **`Sim` writes the RNG state;
everyone else reads it.**

### The deterministic-replay invariant

> For any seed `s` and any sequence of input events `E =
> [e_0, e_1, …, e_n]`, two `Sim` instances constructed
> with the same seed `s` and ticked through the same
> sequence of input events with the same per-tick
> `delta_days` produce identical state at every tick.

"Identical state" means:

- the `time_days` value is identical,
- the inhabitants array is element-wise deep-equal
  (same ids, same culture, same name, same role, same
  position, same state, same `Needs`, same `EventMemory`
  entries),
- the events array is element-wise deep-equal (same
  `EventEntry` dicts in the same order),
- the `EventLog` is element-wise deep-equal (same
  entries, same `time_days`, same `id`s),
- the relationship graph is edge-set-equal and
  edge-attribute-equal (same `a`, same `b`, same
  `affinity`, same `history`).

The invariant is what `tests/sim/test_sim_replay.gd`
(M2 cycle 3) will assert: load two `Sim` instances with
the same seed, run the same tick sequence with the same
input events, assert deep-equal at every tick. A
regression in the tick order or the RNG ownership rule
will fail that test.

### What is *not* in the contract

The contract pins the *order* of operations and the
*ownership* of the RNG. It does *not* pin:

- the **contents** of each step (decay rates, contract
  evaluation rules, crisis resolution rules). Those are
  the track-A and track-B commits; they are documented
  in their own ADRs and tuned in `src/sim/constants.gd`.
- the **shape** of the events the tick produces. The
  `EventEntry` dict's keys are pinned in the skeleton
  (`id`, `time_days`, `kind`, `summary`, `affected`),
  but the *kinds* (`"task.completed"`, `"needs.low"`,
  `"contract.breached"`, `"crisis.resolved"`, …) are
  content and land with the track that produces them.
- the **per-inhabitant** state inside one tick. The
  contract says "every inhabitant's needs are decayed
  before any task is progressed" — it does not say *in
  what order* the inhabitants are processed inside
  step 2 or step 3. The order *within* a step is
  pinned separately in the skeleton's docstrings
  (alphabetical by `id`, the determinism-friendly
  default).
- the **scheduler** that decides *when* to call
  `Sim.tick()`. The realm façade is responsible for
  that call; the sim is passive. (See §5 of
  `docs/requirements.md` — "important decisions may
  automatically pause the game" — and the realm
  façade's tick loop in `src/realm/realm.gd`.)

### Module-boundary impact

Per ADR-0002, `src/sim` is forbidden from importing
`src/ui`, `src/realm`, or `src/save`. This ADR reinforces
that rule for the M2 track: the sim does not call into
the realm façade to fetch the time, does not read from
the save layer to reload RNG state mid-tick, and does
not project anything onto the screen.

The M2 skeleton is the *first* time the sim gains a
non-empty public surface (the `tick` method and the
nine `class_name`d data carriers in `src/sim/`). Every
class in this commit respects the ADR-0002 boundary:
the only `res://` imports in the new files are
`res://src/core/` (for `SplitMix64` and the module
namespace) and the `res://src/content/` stub (planned
for the M2 cycle 2 commit; the skeletons in this PR
declare the dependency but do not actually preload it
yet).

### Mechanical enforcement

The deterministic-replay invariant is mechanically
enforced by a test in
`tests/sim/test_sim_replay.gd` (M2 cycle 3). The test:

1. constructs two `Sim` instances with the same seed,
2. feeds the same sequence of input events to both,
3. ticks both with the same `delta_days`,
4. asserts deep-equal state at every tick.

A regression in the tick order (a step that runs in
the wrong place) or in the RNG ownership rule (a
subsystem that mutates the RNG state) will fail this
test.

The module-dependency check
(`tools/check_module_dependencies.sh`) enforces the
boundary mechanically today; the replay test is the
companion mechanical check for this ADR.

### Consequences

- Good, because the determinism story is one sentence
  long: "same seed + same input events ⇒ same state".
  Every other determinism claim in the project (save
  format, replay, benchmark reproducibility, headless
  test) is a corollary of that sentence.
- Good, because the tick order is small and visible. A
  new contributor can read the six steps in a minute
  and know exactly what their subsystem is allowed to
  do inside a tick.
- Good, because the RNG ownership rule is one rule,
  not a coordination problem. Subsystems that need
  randomness receive a read-only handle; the sim owns
  the state.
- Good, because the parallel tracks A and B can be
  developed against a stable contract. The contract is
  the meeting point.
- Bad, because "fixed order" is a load-bearing
  constraint. A future subsystem that wants to be
  event-driven inside a tick will have to push the
  event-driven logic *into* a step, not *around* the
  tick. That is the right trade-off for a
  single-timeline game.
- Bad, because the replay test is a single test for a
  large contract. A regression that only shows up at
  tick 1000 will not be caught by a tick-1 test. The
  test will exercise a long-enough sequence (≥ 100
  ticks) to make the order-mixing bugs surface; the
  exact length is recorded in the test's docstring.
- Bad, because the per-tick RNG batch is small. A
  subsystem that needs more random values than the
  batch holds will have to ask the sim for them. This
  is a coordination step, not a free-for-all, and the
  batch size is the next thing the M2 track-A commit
  will pin.

### Confirmation criteria

This ADR is considered effective when:

- [ ] `docs/adrs/0005-sim-tick-determinism.md` exists
      with this frontmatter and this decision outcome.
- [ ] `src/sim/sim.gd` exposes a `tick(delta_days,
      inhabitants, events) -> void` method whose
      docstring names the six steps in the order
      documented above.
- [ ] `src/sim/sim.gd` holds the per-tick RNG state in
      a private member; the public surface exposes no
      `snapshot`/`restore`/`save_state`/`load_state`
      methods on the sim itself (only on the
      `SplitMix64` instance the sim owns).
- [ ] The skeleton classes in `src/sim/` (Inhabitant,
      Needs, EventMemory, Relationship, Contract, Task,
      EventLog, Crisis) declare their public surface
      exactly as documented in this ADR's skeleton
      section, and the public surface is the only
      thing the track-A and track-B commits are
      allowed to add to.
- [ ] `tools/check_module_dependencies.sh` is green
      against the new `src/sim/` files.
- [ ] `./tools/run_quality.sh` is green at the end of
      the M2-foundation commit.

## Pros and cons of the options

### Fixed-order sim-tick, sim owns the RNG, replay invariant pinned

- Good, determinism is a one-sentence property.
- Good, the order is small and visible.
- Good, parallel tracks A and B have a stable meeting
  point.
- Bad, fixed order is a load-bearing constraint.
- Bad, the replay test is a single test for a large
  contract.

### Event-driven sim with no fixed tick order

- Good, flexible.
- Good, every subsystem reacts to every other.
- Bad, determinism becomes a tie-breaking-rules
  problem, not a contract problem.
- Bad, save/load replay is harder to test.

### Fixed-order sim-tick with multiple RNGs

- Good, enables parallelism.
- Bad, every subsystem has to coordinate its own
  seed.
- Bad, the determinism invariant is now a set of
  invariants, not one.
- Bad, the M2 surface area does not need it.

### Free-order sim-tick

- Good, simplest to implement.
- Bad, the determinism story collapses.
- Bad, two PRs in different orders produce two
  campaigns from the same seed.

## More information

- `docs/requirements.md` §9 (inhabitants), §10
  (resources and progression), §11 (conflict and
  crises), §16 (technical architecture).
- `docs/adrs/0001-record-architecture-decisions.md`
  — the format this ADR uses.
- `docs/adrs/0002-module-boundaries.md` — the
  `src/sim` boundary this ADR reinforces.
- `docs/adrs/0003-save-format.md` — the save body
  that stores `body.sim.rng_state` and is the
  bridge between this ADR and the M5 replay
  feature.
- `src/core/rng.gd` — the `SplitMix64` RNG this ADR
  pins as the sim's only sanctioned randomness
  source.
- `src/sim/README.md` — the per-module contract
  (§17 of requirements) for `src/sim`.
- `tests/sim/test_sim_replay.gd` (M2 cycle 3) — the
  mechanical check for this ADR.
