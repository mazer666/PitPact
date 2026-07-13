# src/world

Spatial state of a realm: tile grid, zones, rooms, spatial indices.

## Purpose

`src/world` owns the spatial layer of a single realm: the tile
grid, the zone (connected-set-of-tiles) data, the room lifecycle
defined in [`docs/adrs/0004-spatial-model.md`](../adrs/0004-spatial-model.md),
and the spatial indices used by the simulation and the UI.

The data model is integer-coordinate and scene-tree-free. The UI
projects this state onto a viewport; the simulation reads and
mutates it; the save format serialises it.

## Responsibility

`src/world`:

- stores the tile grid (one `ZonePurpose` per tile, per
  ADR-0004),
- computes connected components (zones) on demand and caches
  the result with a documented invalidation rule,
- tracks the room lifecycle (`BeingBuilt → Operational →
  Decaying → Abandoned → Ruin`),
- exposes pure spatial queries (`tile_at`, `tiles_in_zone`,
  `room_at`, `tiles_in_room`),
- exposes pure coordinate conversions
  (`tile_to_world`, `world_to_tile`, `tile_z_order`) per
  ADR-0004.

`src/world` does **not** run inhabitants, does **not** advance
time, and does **not** read or write the UI scene tree.

## Public entry point

`class_name WorldState` — the one `WorldState` instance per
loaded realm. Created by `src/realm/RealmFactory` and never
hand-constructed by callers.

The full public surface (signatures and contracts) will be
documented in this section as the M1 cycle 2 commit lands the
real data model. Until then the public entry point is the
`class_name WorldState` declared in `world.gd`.

## Main dependencies

- `src/core` — for `SplitMix64` (deterministic zone labelling
  and tie-breaking) and the canonical time/clock types.
- `src/content` — for `ZonePurpose`, room definitions, and
  biome metadata.

## Must NOT depend on

- `src/sim`, `src/realm`, `src/save`, `src/ui`, `src/audit` —
  the world does not know what is in its rooms, who is
  playing, or how the screen looks.
- The Godot scene tree.

The mechanical check for this rule lives in
[`tools/check_module_dependencies.sh`](../../tools/check_module_dependencies.sh).

## Files

| File | Public class | Status |
|------|--------------|--------|
| [`world.gd`](world.gd) | `WorldState` (stub) | M1 stub |
| (lands with cycle 2) | `TileGrid` | planned |
| (lands with cycle 2) | `Zone` | planned |
| (lands with cycle 2) | `Room` | planned |
| (lands with cycle 2) | `coordinates.gd` | planned (ADR-0004) |

## See also

- [`docs/adrs/0002-module-boundaries.md`](../adrs/0002-module-boundaries.md)
- [`docs/adrs/0004-spatial-model.md`](../adrs/0004-spatial-model.md)
- [`docs/requirements.md`](../requirements.md) §8, §16, §17
