---
status: accepted
date: 2026-07-13
deciders: project leads
consulted: contributors
informed: all contributors
---

# 4. Spatial model

## Context and problem statement

`docs/requirements.md` §8 pins three things about the spatial
model:

1. "The realm uses a readable isometric tile grid with free zoom
   and a **fixed camera orientation**."
2. "Players designate room zones. Inhabitants furnish, operate,
   expand, repurpose, neglect, or cause room decay according to
   rules and resources."
3. "Biomes affect resources, visual identity, environmental
   opportunities, and risks."

§16 reinforces that the game-domain must be deterministic and
separated from the scene tree, and §17 makes the per-module
contract (purpose, responsibility, public entry point, main
dependencies) binding.

Several "spatial model" questions follow:

- Are we using a 2D tile grid, a 2.5D world with three.js-style
  3D math, or a hex grid?
- How are world coordinates, tile coordinates, and screen
  coordinates related, and where do the conversion functions
  live?
- What is the relationship between a *zone* (a maximal connected
  set of tiles of the same purpose) and a *room* (a zone that
  has been promoted)?
- Is the camera allowed to rotate?
- Does the tile model own the room state, or is room state
  something layered on top?

These are not separate questions. They hang together, and the
contract that ties them together is what this ADR pins.

## Decision drivers

- **Readability.** §8 calls the grid "readable". That word is
  load-bearing: the player must be able to count tiles, name
  rooms, and plan ahead. A model that hides tile boundaries
  behind procedural meshes fails this test.
- **Determinism.** §16. The spatial state must be a pure
  function of the seed and the player's input. A 3D model that
  uses floating-point math is not reproducible across
  architectures (ULP differences, FMA contractions) without
  discipline that the M5 surface area will not sustain.
- **Fixed orientation.** §8. "Fixed camera orientation" is a
  promise to the player: north is north, the same tile looks
  the same way in every campaign, and the UI does not have to
  re-anchor on rotation. Rotation is forbidden; free zoom is
  allowed.
- **Room lifecycle.** A *room* in this game is a state
  machine, not a label. A zone becomes a room by being
  *promoted*: named, given a purpose, given inhabitants. The
  promotion is a one-way state change — a room can be
  *demoted* back to a zone, but it cannot pretend to be a
  zone while still being a room.
- **Replaceability.** §16. The UI layer may need to be
  rewritten (Godot 4 → Godot 5, accessibility pass, mobile
  renderer). The spatial model must be a pure data model that
  the UI projects onto a viewport, not a model that *is* a
  viewport.

## Considered options

1. **Isometric diamond grid (2:1 tile aspect), fixed orientation,
   tile coordinates + world coordinates + screen coordinates
   separated, rooms as a promoted-zone state machine** (this).
2. **3D world with three.js-style 3D math.** Rejected: violates
   §16's determinism requirement, requires the UI to project a
   3D scene (massive cost for no gameplay benefit), and makes
   the "readable grid" promise unfulfillable.
3. **Hex grid.** Rejected: a hex grid is a defensible choice for
   *some* 4X and tactical games, but PitPact's spatial model is
   read-and-recognise, not move-and-flank. Diamond tiles are
   the right tool for "count the rooms and plan the next
   extension" gameplay.
4. **Free-form mesh with a tile grid under it.** Rejected: the
   "mesh" becomes a source of nondeterminism (vertex
   precision, normal recomputation) and a liability for
   reproducibility. The visible artefact is the tile grid.

## Decision outcome

Chosen option: **Isometric diamond grid, fixed camera orientation,
explicit coordinate systems, rooms as a promoted-zone state
machine.**

### Coordinate systems

Three coordinate systems are in play. They are distinct, the
conversions between them are pure functions, and they live in
`src/world/coordinates.gd`.

| System | Type | Unit | Purpose |
|--------|------|------|---------|
| Tile coordinates | `Vector2i` | tile index | The grid's canonical coordinate system. Deterministic. The simulation only ever talks tile coordinates. |
| World coordinates | `Vector2` | sub-tile units (256 per tile) | The intermediate coordinate system used for "things that are not on a tile boundary" — inhabitants moving along a path, a partial-construction overlay, a particle effect. World coordinates are deterministic and integer-or-fixed. |
| Screen coordinates | `Vector2` | pixels | The output of the camera projection. Not deterministic. UI-only. Never stored on a save. |

The chain of conversion is:

```
tile  --[ tile_to_world() ]-->  world  --[ world_to_screen() ]-->  screen
screen --[ screen_to_world() ]--> world --[ world_to_tile() ]-->  tile
```

`tile_to_world` and `world_to_tile` are the contract; they
live in `src/world/coordinates.gd` and are pure functions.
`world_to_screen` and `screen_to_world` are the camera's
responsibility; they live in the camera controller in `src/ui/`
and are *not* part of the deterministic contract.

### Tile geometry

- **Shape.** Diamond. A tile is `TILE_W` pixels wide and
  `TILE_H` pixels tall in screen space, with the conventional
  2:1 aspect ratio for "isometric diamond" tiles.
- **Reference values.** `TILE_W = 64`, `TILE_H = 32`. These
  are pin-able in `src/world/coordinates.gd` and overridable
  in `src/content/` per-biome if a future content pack needs
  non-standard tile dimensions. The default of 64×32 is the
  §8 "readable isometric tile grid" baseline.
- **Origin.** Tile `(0, 0)` is at world coordinates `(0, 0)`;
  world coordinates grow rightward (x) and downward (y) on the
  screen; tile coordinates grow rightward (x) and downward (y)
  on the grid. A "north-west" tile has lower `x` and lower
  `y` than a "south-east" tile.
- **Z-ordering.** The painter's algorithm. Tiles are drawn in
  `(y, x)` order, back-to-front, so the visible top edge of a
  tile overlaps the bottom edge of the tile behind it. The
  z-order function is `tile_z_order(tile: Vector2i) -> int`
  and lives in `src/world/coordinates.gd`.

### Camera

- **Orientation.** Fixed. The camera never rotates. The same
  tile in the same campaign always projects to the same screen
  rectangle. This is the §8 promise; rotation is forbidden.
- **Zoom.** Free. The camera exposes a continuous `zoom` value
  in `[ZOOM_MIN, ZOOM_MAX]`. `ZOOM_MIN = 0.5`,
  `ZOOM_MAX = 3.0`. The default is `1.0`. Zoom is applied as
  a uniform scale to the projection, *not* by changing the
  tile dimensions in the data model. The data model is at
  zoom 1.0 forever.
- **Pan.** Continuous, by mouse-drag, by minimap-click, and by
  edge-of-screen scroll. Pan is a camera concern; it does
  not change the world model.
- **Camera-as-controller.** The camera is a Godot node in
  `src/ui/`. It owns no game state. It reads the realm façade
  and projects. It writes nothing back.

### Zones

A **zone** is a maximal connected set of tiles of the same
purpose. "Same purpose" means "same `ZonePurpose` enum value":
`Empty`, `Floored`, `ZonedForProduction`, `ZonedForResearch`,
`ZonedForDefence`, `ZonedForHabitation`, etc. (The exact enum
is owned by `src/content/`'s `zone_definitions.gd` and is
content, not architecture.)

- **Connectivity.** Two tiles are connected if they share an
  edge. Diagonal-only connections do not make a single zone.
- **Maximality.** A zone is *the* set of connected tiles of
  one purpose, not a subset of it. If a player designates a
  fourth tile adjacent to an existing three-tile production
  zone for the same purpose, the result is one zone of four
  tiles, not a new zone of one tile.
- **Storage.** Zones are not stored as a list of tiles. They
  are stored as a single `ZonePurpose` per tile; the connected-
  component computation is on-demand and cached. The cache is
  invalidated when a tile's `ZonePurpose` changes.
- **Lifecycle.** A zone is created by changing a tile's
  `ZonePurpose`. A zone is destroyed by reverting the tile.
  A zone can be *promoted* to a room (see below) but the
  zone itself never "becomes" the room; the zone is the
  spatial footprint, the room is the state machine that sits
  on top.

### Rooms

A **room** is a zone that has been *promoted*. Promotion is a
one-way state change: a zone can become a room, a room can be
demoted back to a zone, but a demoted room is no longer a room.

A promoted room has:

- a **name** (a localisation key, not a literal string;
  §15),
- a **purpose** (the same `ZonePurpose` the zone already
  had; promotion does not change the spatial footprint's
  purpose),
- a **state** (a `RoomState` enum: `BeingBuilt`, `Operational`,
  `Decaying`, `Abandoned`, `Ruin`),
- an **inhabitant set** (possibly empty),
- an **inventory** (resources consumed and produced, in
  canonical units; ADR-0003),
- a **history** (a read-only event log slice from
  `src/audit`).

- **Promotion.** The player names a zone, the simulation
  validates that the zone's purpose is one that *can* be
  promoted (e.g. `ZonedForProduction` → a production room),
  and the room is created with state `BeingBuilt`. The
  simulation drives the room through `Operational` →
  `Decaying` → `Abandoned` → `Ruin` based on inhabitants,
  resources, and events.
- **Demotion.** A demoted room loses its name, state,
  inhabitant set, inventory, and history. The zone remains.
  Demotion is irreversible: a demoted room is now a zone.
- **Demolition.** A demolished room is a room whose
  inhabitant set has been removed and whose tiles have been
  reverted to `Empty`. The room record is deleted; the zone
  ceases to exist. Demolition is final.
- **No conflation.** A room's *state* (`BeingBuilt`,
  `Operational`, …) and a tile's *zone purpose* are
  different fields on different objects. The tile does not
  know it is part of a room. The room knows its tiles. This
  is the rule that the spec calls out under "Reject: any
  model that conflates tile and room state."

### What is rejected

The following are explicitly **not** allowed:

- **Any model that requires three.js-style 3D math.** The
  spatial state is a 2D grid. No perspective projection, no
  vertex normals, no quaternions. The visible 2.5D is a
  presentation effect, not a data-model effect.
- **Any model that conflates tile and room state.** A tile
  has a `ZonePurpose`. A room has a `RoomState`. These are
  different fields, on different objects, and they do not
  shadow each other.
- **Any model that makes rotation cheap.** The camera
  orientation is fixed. A "rotate camera" feature is a
  scope change that requires a new ADR.
- **Any model that hides tile boundaries.** The grid is
  visible. The grid is the player's planning surface. A
  free-form mesh that obscures the grid is out.
- **Any model that stores screen coordinates in the data
  layer.** Screen coordinates are an output of the
  camera; they are not part of the save.

### Consequences

- Good, because the grid is visible, the coordinates are
  integer, the conversions are pure functions, and the
  determinism promise is upholdable.
- Good, because a "rotate camera" feature is *not* a
  bug fix; it is a scope change. The fixed orientation
  rule makes the player-facing UI predictable across
  campaigns.
- Good, because the zone-vs-room distinction is a hard
  data-model distinction. A future "I want a 6×3 zone
  of empty floor that isn't a room" feature is a one-line
  change; a future "what if rooms were tile flags" mistake
  is a structural mistake that this ADR prevents.
- Bad, because "free zoom only" is more restrictive than
  "free camera". The §8 contract is what we accept; the
  price is the inability to follow a tall inhabitant with
  the camera.
- Bad, because the "promoted zone" model means that room
  data is a small index layered on top of the zone grid,
  not a re-organisation of the grid. That is the right
  trade-off for determinism; it is one more concept to
  teach a new contributor.

### Confirmation criteria

This ADR is considered effective when:

- [ ] `src/world/coordinates.gd` exists and exposes
      `tile_to_world`, `world_to_tile`, and
      `tile_z_order` as pure, unit-tested functions.
- [ ] `src/world/zone.gd` exists and exposes a
      `ZonePurpose` enum and a connected-component query
      with a documented cache-invalidation rule.
- [ ] `src/world/room.gd` exists and exposes a `RoomState`
      enum and a `promote(zone, name, purpose) -> Room`
      function whose return value is a `Room`, not a
      `Zone`.
- [ ] `tests/world/test_coordinates.gd` exists with
      round-trip tests for the conversions, and a
      determinism test that asserts the same tile in two
      different `WorldState` instances produces the same
      world coordinates.
- [ ] The fixed-orientation rule is encoded as an
      assertion in the camera controller: the camera's
      rotation is `0.0` and any non-zero write is a no-op
      with a logged warning.

## Pros and cons of the options

### Isometric diamond grid, fixed orientation, three coordinate systems, rooms as a promoted-zone state machine

- Good, integer coordinates.
- Good, deterministic.
- Good, readable.
- Good, room lifecycle is explicit.
- Bad, "free zoom only" is more restrictive than "free
  camera". (Accepted; this is the §8 contract.)
- Bad, two concepts (zone and room) instead of one. (A
  single conflated concept is a future bug; the price of
  keeping them separate is small.)

### 3D world with three.js-style 3D math

- Good, flexible camera.
- Good, can do anything.
- Bad, floating-point nondeterminism.
- Bad, "readable grid" promise is unfulfillable.
- Bad, the 2.5D visible artefact is the player's mental
  model; a 3D data model is a thousand-times-overspec.

### Hex grid

- Good, no diagonal ambiguity.
- Bad, "count the rooms and plan the next extension"
  gameplay is harder on hex.
- Bad, the §8 "isometric tile grid" language is a square
  grid.
- Bad, the entire visual style guide assumes a square
  grid.

### Free-form mesh with a tile grid under it

- Good, artists can paint organic shapes.
- Bad, the mesh is nondeterministic.
- Bad, the "mesh" layer becomes a liability for save
  reproducibility and mod compatibility.

## More information

- `docs/requirements.md` §8 (realm building and spatial
  simulation), §15 (localization), §16 (technical
  architecture), §17 (code quality).
- ADR-0001 (record architecture decisions).
- ADR-0002 (module boundaries) — the `src/world` module
  boundary.
- ADR-0003 (save format) — the canonical body that stores
  the world state.
- `src/world/README.md` (lands with this ADR).
- `src/world/coordinates.gd` (lands with this ADR).
- `src/world/zone.gd` (lands with this ADR).
- `src/world/room.gd` (lands with this ADR).
- `tests/world/test_coordinates.gd` (lands with this ADR).
- `tests/world/test_zone_room.gd` (lands with this ADR).
