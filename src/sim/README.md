# src/sim

Tick-based, deterministic simulation: inhabitants, needs,
contracts, tasks, relationships, event memory, crises.

## Purpose

`src/sim` is the simulation layer of a single realm. It owns the
state of the inhabitants (their needs, contracts, profession,
relationships, memory) and the rules that advance that state on
each tick.

The simulation is **deterministic and tick-based**: given the
same seed, the same world state, and the same player commands,
the simulation produces the same sequence of events for every
campaign, on every platform, for every Godot version. This
contract is what makes the game replayable and the local
quality suite fast.

The contract is pinned by ADR-0005 (sim-tick determinism) and
extends the module-boundary contract in
[`docs/adrs/0002-module-boundaries.md`](../adrs/0002-module-boundaries.md).

## Responsibility

`src/sim`:

- owns the per-tick RNG state. The sim is the **only** owner
  of the RNG; every other module receives a read-only handle
  for the duration of a tick (ADR-0005).
- owns the inhabitant roster and per-inhabitant state
  (needs, contracts, profession, relationships, memory),
- owns the contract set and the contract-evaluation rules,
- owns the task queue and the task-assignment rules,
- owns the relationship graph and the relationship-update
  rules,
- owns the crisis queue and the crisis-resolution rules,
- exposes a single `tick(delta_days, inhabitants, events)`
  entry point that advances the simulation by one tick,
- emits a structured event stream to the append-only
  `EventLog` on every state change.

`src/sim` does **not** render, does **not** play sound, and
does **not** read or write files.

## Public entry point

`class_name Sim` — the one `Sim` instance per loaded realm.
Owned by `src/realm/Realm`; callers do not construct it
directly. The full API (`tick`, `add_inhabitant`,
`evaluate_contracts`, …) is documented in this section as
the M2 cycle 2 and cycle 3 commits land the real data
model and the per-tick rules.

The `Sim` façade is the per-realm simulation. The companion
data carriers in `src/sim/` are the per-inhabitant,
per-contract, per-task, per-edge, per-crisis data structures
the tick advances. The M2-foundation commit ships the
skeletons (the public surface, the typed fields, the
docstrings); the M2 cycle 2 (Track A) and M2 cycle 3
(Track B) commits fill in the per-tick rules.

## Main dependencies

- `src/core` — for `SplitMix64` (every random decision in
  the tick is seeded; ADR-0005 names `Sim` as the **only**
  owner of the RNG state) and the canonical time/clock
  types.
- `src/world` — for spatial state (inhabitant positions,
  room membership). M2 cycle 2 dependency.
- `src/content` — for inhabitant definitions, contract
  templates, task templates, event templates. M2 cycle 2
  dependency.
- `src/audit` — the simulation emits its event stream to
  the audit log; the audit log is a passive observer. M2
  cycle 3 dependency.

## Must NOT depend on

- `src/realm`, `src/save`, `src/ui` — the simulation does
  not know it is part of a realm, does not know it is being
  saved, and does not know it is being rendered.
- The Godot scene tree.

The mechanical check for this rule lives in
[`tools/check_module_dependencies.sh`](../../tools/check_module_dependencies.sh).

## The tick contract (ADR-0005)

A single call to `Sim.tick(delta_days, inhabitants, events)`
advances the simulation by `delta_days` in-game days. The
tick is a pure function on the inhabitants array, the events
array, and the sim's own RNG state. The order of operations
is fixed and is exactly:

1. **RNG draw** — pull a fresh batch of uniform random
   values from the per-tick RNG.
2. **Needs decay** — every inhabitant's `Needs` are decayed
   by `TUNING_NEED_DECAY_PER_DAY * delta_days`.
3. **Task progress** — every open `Task` advances its
   `progress`; completed tasks emit `task.completed` events.
4. **Event-memory recording** — the tick's events are
   recorded into each affected inhabitant's `EventMemory`.
5. **Relationships update** — every `Relationship` edge is
   updated based on the events from step 4.
6. **Event-log append** — the tick's events are appended to
   the append-only `EventLog`.

After step 6, the sim's `time_days` is advanced by
`delta_days` and the tick returns. The full contract lives
in [`docs/adrs/0005-sim-tick-determinism.md`](../adrs/0005-sim-tick-determinism.md).

## The deterministic-replay invariant

> For any seed `s` and any sequence of input events `E =
> [e_0, e_1, …, e_n]`, two `Sim` instances constructed
> with the same seed `s` and ticked through the same
> sequence of input events with the same per-tick
> `delta_days` produce identical state at every tick.

The M2-foundation commit cannot exercise this invariant
because the tick body is a no-op. The M2 cycle 3 commit
adds `tests/sim/test_sim_replay.gd`, which is the
mechanical check for ADR-0005.

## Files

| File | Public class | Status |
|------|--------------|--------|
| [`sim.gd`](sim.gd) | `Sim` (skeleton) | M2 foundation |
| [`inhabitant.gd`](inhabitant.gd) | `Inhabitant` (skeleton) | M2 foundation |
| [`needs.gd`](needs.gd) | `Needs` (skeleton) | M2 foundation |
| [`event_memory.gd`](event_memory.gd) | `EventMemory` (skeleton) | M2 foundation |
| [`relationships.gd`](relationships.gd) | `Relationship` (skeleton) | M2 foundation |
| [`contract.gd`](contract.gd) | `Contract` (skeleton) | M2 foundation |
| [`tasks.gd`](tasks.gd) | `Task` (skeleton) | M2 foundation |
| [`event_log.gd`](event_log.gd) | `EventLog` (skeleton) | M2 foundation |
| [`crisis.gd`](crisis.gd) | `Crisis` (skeleton) | M2 foundation |
| [`constants.gd`](constants.gd) | `SimConstants` (tuning) | M2 foundation |
| [`knowledge_state.gd`](knowledge_state.gd) | `KnowledgeState` (skeleton) | M4 foundation |
| [`research_node.gd`](research_node.gd) | `ResearchNode` (skeleton) | M4 foundation |
| [`pactmaker.gd`](pactmaker.gd) | `Pactmaker` (skeleton) | M4 foundation |
| [`power.gd`](power.gd) | `Power` (skeleton) | M4 foundation |
| [`faction.gd`](faction.gd) | `Faction` (skeleton) | M4 foundation |
| [`settings.gd`](settings.gd) | `Settings` (skeleton) | M4 foundation |
| [`m4_skeleton.gd`](m4_skeleton.gd) | `M4Skeleton` (façade) | M4 foundation |
| (lands with M2 cycle 2 / Track A) | per-tick needs decay; per-tick task progress; per-inhabitant memory recording | planned |
| (lands with M2 cycle 3 / Track B) | per-tick relationships update; per-tick contract evaluation; per-tick crisis resolution; replay test | planned |
| (lands with M4 Track A) | per-tick research/ritual progression; content catalogue loader; per-power registration | planned |
| (lands with M4 Track B) | per-tick autonomous conflict; deadline mechanic; per-tick Pactmaker intervention | planned |

## See also

- [`docs/adrs/0002-module-boundaries.md`](../adrs/0002-module-boundaries.md)
- [`docs/adrs/0005-sim-tick-determinism.md`](../adrs/0005-sim-tick-determinism.md)
- [`docs/adrs/0010-research-tree-schema.md`](../adrs/0010-research-tree-schema.md) — the M4 research/ritual/knowledge contract.
- [`docs/adrs/0011-autonomous-conflict.md`](../adrs/0011-autonomous-conflict.md) — the M4 autonomous-conflict and deadline contract.
- [`docs/requirements.md`](../requirements.md) §9, §10, §11, §16, §17
- [`tests/_smoke/test_sim_skeleton.gd`](../../tests/_smoke/test_sim_skeleton.gd) — the
  M2-foundation smoke test (17 tests, all green).
- [`tests/integration/test_m4_skeleton.gd`](../../tests/integration/test_m4_skeleton.gd) — the
  M4-foundation smoke test (19 tests, 80 asserts, all green).
- [`tests/sim/test_sim_replay.gd`](../../tests/sim/test_sim_replay.gd) — the
  ADR-0005 replay test (lands with M2 cycle 3).
