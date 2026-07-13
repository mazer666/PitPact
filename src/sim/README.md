# src/sim

Tick-based, deterministic simulation: inhabitants, needs,
contracts, tasks, relationships, event memory.

## Purpose

`src/sim` is the simulation layer of a single realm. It owns the
state of the inhabitants (their needs, contracts, tasks,
relationships, event memory) and the rules that advance that
state on each tick.

The simulation is **deterministic and tick-based**: given the
same seed, the same world state, and the same player commands,
the simulation produces the same sequence of events for every
campaign, on every platform, for every Godot version. This
contract is what makes the game replayable and the local
quality suite fast.

## Responsibility

`src/sim`:

- owns the inhabitant roster and per-inhabitant state
  (needs, contracts, profession, relationships, memory),
- owns the contract set and the contract-evaluation rules,
- owns the task queue and the task-assignment rules,
- owns the relationship graph and the relationship-update
  rules,
- emits a structured event stream to `src/audit` on every
  state change,
- exposes a single `tick(dt)` entry point that advances the
  simulation by one tick.

`src/sim` does **not** render, does **not** play sound, and
does **not** read or write files.

## Public entry point

`class_name Simulation` — the one `Simulation` instance per
loaded realm. Owned by `src/realm/Realm`; callers do not
construct it directly.

The full API (`tick`, `add_inhabitant`, `evaluate_contracts`,
…) will be documented in this section as the M2 commit lands
the real data model. Until then the public entry point is the
`class_name Simulation` declared in `sim.gd`.

## Main dependencies

- `src/core` — for `SplitMix64` (every random decision in the
  tick is seeded) and the canonical time/clock types.
- `src/world` — for spatial state (inhabitant positions,
  room membership).
- `src/content` — for inhabitant definitions, contract
  templates, task templates, event templates.
- `src/audit` — the simulation emits its event stream to the
  audit log; the audit log is a passive observer.

## Must NOT depend on

- `src/realm`, `src/save`, `src/ui` — the simulation does
  not know it is part of a realm, does not know it is being
  saved, and does not know it is being rendered.
- The Godot scene tree.

The mechanical check for this rule lives in
[`tools/check_module_dependencies.sh`](../../tools/check_module_dependencies.sh).

## Files

| File | Public class | Status |
|------|--------------|--------|
| [`sim.gd`](sim.gd) | `Simulation` (stub) | M1 stub |
| (lands with M2) | `Inhabitant`, `Needs`, `Contract`, `Task`, `Relationship`, `EventMemory` | planned |

## See also

- [`docs/adrs/0002-module-boundaries.md`](../adrs/0002-module-boundaries.md)
- [`docs/requirements.md`](../requirements.md) §9, §10, §11, §16, §17
