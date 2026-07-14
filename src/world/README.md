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

The M3-foundation commit adds a second public entry point,
`class_name WorldGenerator` in [`generator.gd`](generator.gd),
which is the deterministic pure function
`WorldGenerator.generate(seed, width, height, constraints)
-> WorldMap` pinned by
[ADR-0007](../adrs/0007-world-generator-determinism.md). The
generator builds the realm's `WorldMap` from a seed and a
constraint set; the realm façade materialises a `WorldState`
and a `Sim` from the `WorldMap`. The M3-foundation commit
ships the signature and the no-op body; the M3 cycle 2
(Track A) commit fills in the body.

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
| [`world.gd`](world.gd) | `WorldState` | M1 (Track A) |
| [`grid.gd`](grid.gd) | `Grid` | M1 (Track A) |
| [`tile.gd`](tile.gd) | `Tile` | M1 (Track A) |
| [`zone.gd`](zone.gd) | `ZoneOps` / `ZoneGrid` | M1 (Track A) |
| [`coordinates.gd`](coordinates.gd) | `WorldCoordinates` | M1 (Track A, ADR-0004) |
| [`tile_map.gd`](tile_map.gd) | `WorldTileMapLayer` | M1 (Track A) |
| [`zone_painter.gd`](zone_painter.gd) | `ZonePainterTool` | M1 (Track A) |
| [`demo_realm.gd`](demo_realm.gd) | `DemoRealm` | M1 (Track A, placeholder) |
| [`generator.gd`](generator.gd) | `WorldGenerator` (with inner `WorldMap`, `GeneratorConstraintError`) | M3-foundation skeleton (ADR-0007) |
| [`biome.gd`](biome.gd) | `Biome` | M3-foundation skeleton |
| [`exploration.gd`](exploration.gd) | `ExplorationMap` | M3-foundation skeleton |
| [`narrative_anchor.gd`](narrative_anchor.gd) | `NarrativeAnchor` | M3-foundation skeleton |
| [`branch.gd`](branch.gd) | `BranchNode` | M3-foundation skeleton (ADR-0008) |
| (lands with M3 cycle 2 Track A) | per-biome placement, per-tile biome catalogue, fog-of-war reveal | planned |
| (lands with M3 cycle 2 Track B) | per-anchor placement, branch-node root set | planned |

## See also

- [`docs/adrs/0002-module-boundaries.md`](../adrs/0002-module-boundaries.md)
- [`docs/adrs/0004-spatial-model.md`](../adrs/0004-spatial-model.md)
- [`docs/adrs/0007-world-generator-determinism.md`](../adrs/0007-world-generator-determinism.md)
- [`docs/adrs/0008-branching-event-schema.md`](../adrs/0008-branching-event-schema.md)
- [`docs/requirements.md`](../requirements.md) §7, §8, §11, §16, §17
- [`tests/_smoke/test_world_skeleton.gd`](../../tests/_smoke/test_world_skeleton.gd) —
  the M3-foundation skeleton smoke test (15 tests, all green).
