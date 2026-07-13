# src/core

Engine-agnostic primitives used by every other module.

## Purpose

`src/core` is the bottom of the module stack defined in
[`docs/adrs/0002-module-boundaries.md`](../adrs/0002-module-boundaries.md).
It holds the deterministic, scene-tree-free primitives that the rest
of the codebase depends on:

- the deterministic random-number generator
  ([`SplitMix64`](rng.gd)),
- canonical time / clock types (lands with the simulation),
- canonical math helpers (deterministic, integer-or-fixed-point),
- event-id types and the event bus primitives (lands with the
  audit layer),
- canonical hashing helpers (lands with the save layer).

## Responsibility

`src/core` *only* provides types and pure functions. It does not
own game state, does not read files, does not log to the user, and
does not depend on the scene tree.

## Public entry point

The public surface of this module is the set of `class_name`s
exported by the files under `src/core/`:

- `SplitMix64` — [`rng.gd`](rng.gd).

Additional public classes will be added as the codebase grows;
each new class must come with a docstring and a unit test before
any other module is allowed to depend on it.

## Main dependencies

**None.** This is the only module allowed to have zero upstream
dependencies within the project, and it must remain that way. If a
new primitive needs another module, it does not belong in
`src/core`.

## Must NOT depend on

- `src/world`, `src/sim`, `src/realm`, `src/content`, `src/save`,
  `src/ui`, `src/audit` — nothing in `src/`.
- `res://scenes/`, `res://data/`, `res://locales/`,
  `res://addons/` — no Godot scene, data, locale, or addon
  dependencies.
- The Godot scene tree, `Node`, `Resource`, `Image`, or any other
  engine-typed value.

The mechanical check for this rule lives in
[`tools/check_module_dependencies.sh`](../../tools/check_module_dependencies.sh).

## Determinism contract

Every public class in `src/core` is required to be **fully
deterministic**. A given input must produce the same output on
every run, on every platform, for every supported Godot version.
This contract is what makes ADR-0002's "game-domain modules have
no path to UI" rule worth enforcing: a UI bug cannot perturb a
simulation, and a simulation bug cannot perturb a UI.

## Files

| File | Public class | Status |
|------|--------------|--------|
| [`rng.gd`](rng.gd) | `SplitMix64` | M1 stub (deterministic, unit-tested) |

## See also

- [`docs/adrs/0001-record-architecture-decisions.md`](../adrs/0001-record-architecture-decisions.md)
- [`docs/adrs/0002-module-boundaries.md`](../adrs/0002-module-boundaries.md)
- [`docs/requirements.md`](../requirements.md) §16, §17
