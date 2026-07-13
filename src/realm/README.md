# src/realm

The player-facing realm façade. The single object the UI sees.

## Purpose

`src/realm` is the **only** module the UI is allowed to talk to
about gameplay state. It composes `src/world` (spatial state)
and `src/sim` (simulation) into a single, observable object —
the realm — and exposes the player-facing API
(`create_room`, `set_zone_purpose`, `pause`, `set_speed`,
`save`, `load`).

The realm façade is the seam that makes ADR-0002 work. Without
it, the UI would have to import from `src/world` and `src/sim`
directly, and the "UI imports game-domain modules, never the
other way" rule would not survive the first feature PR.

## Responsibility

`src/realm`:

- owns the lifecycle of one realm instance (create, load,
  tick, save, teardown),
- aggregates the world state (`WorldState`) and the simulation
  (`Simulation`) behind a single observable surface,
- routes player commands to the right subsystem
  (`set_zone_purpose` → `WorldState`,
  `pause` / `set_speed` → the simulation clock,
  `save` → `SaveService`),
- exposes read-only view models the UI binds to (room list,
  inhabitant list, event log slice),
- coordinates the save / load migration chain (see ADR-0003).

`src/realm` does **not** render, does **not** play sound, and
does **not** read player input.

## Public entry point

`class_name Realm` — the one `Realm` instance per loaded
campaign. Constructed by `RealmFactory.new_realm()` or
`RealmFactory.load_realm(path)`.

The full API (`set_zone_purpose`, `create_room`, `pause`, …)
will be documented in this section as the M1 cycle 2 commit
lands the real façade. Until then the public entry point is
the `class_name Realm` declared in `realm.gd`.

## Main dependencies

- `src/core` — for primitives.
- `src/world` — for spatial state.
- `src/sim` — for the simulation.
- `src/content` — for content data.
- `src/save` — for the save/load pipeline.
- `src/audit` — for the event log view the UI binds to.

## Must NOT depend on

- `src/ui` — the façade must be usable from a headless test
  runner and a CLI batch tool. If a feature needs both realm
  data and a screen, the UI pulls the data from the realm;
  the realm does not push into the UI.
- The Godot scene tree (for the headless-test reason above).

The mechanical check for this rule lives in
[`tools/check_module_dependencies.sh`](../../tools/check_module_dependencies.sh).

## Files

| File | Public class | Status |
|------|--------------|--------|
| [`realm.gd`](realm.gd) | `Realm`, `RealmFactory` (stubs) | M1 stub |
| (lands with M1 cycle 2) | the full façade | planned |

## See also

- [`docs/adrs/0002-module-boundaries.md`](../adrs/0002-module-boundaries.md)
- [`docs/adrs/0003-save-format.md`](../adrs/0003-save-format.md)
- [`docs/requirements.md`](../requirements.md) §5, §12, §16, §17
