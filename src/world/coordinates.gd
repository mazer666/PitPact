# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — pure coordinate-conversion helpers (ADR-0004).
#
# Three coordinate systems exist (ADR-0004):
#
#   * Tile coordinates — `Vector2i`. The simulation's only
#     coordinate system. Deterministic. Integer.
#   * World coordinates — `Vector2`. Sub-tile units; 256
#     units per tile edge. Used for "things that are not on
#     a tile boundary" (inhabitants moving along a path, a
#     partial-construction overlay). Deterministic.
#   * Screen coordinates — `Vector2`. Pixels. UI-only. NEVER
#     stored on a save (see ADR-0004 "screen coordinates are
#     an output of the camera; they are not part of the
#     save").
#
# This file pins the `tile_to_world` and `world_to_tile`
# conversions as pure functions. `world_to_screen` and
# `screen_to_world` are the camera's responsibility and live
# in `src/ui/`.
#
# Per ADR-0002, this file does not import from any other
# `src/<module>/`. It is a pure GDScript file.
class_name WorldCoordinates
extends RefCounted

## The default tile dimensions in sub-tile world units. One
## tile is `TILE_W` units wide and `TILE_H` units tall, with
## the conventional 2:1 isometric-diamond aspect ratio. The
## values match the reference of `TILE_W = 64` and `TILE_H =
## 32` pixels in screen space (ADR-0004); in world units
## (256 units per tile edge) the ratio is preserved by
## halving the y extent. The simulation only ever reads
## `TILE_W` and `TILE_H`; per-biome overrides land in
## `src/content/biome_def.gd` once that file exists.
const TILE_W: int = 256
const TILE_H: int = 128

## The sub-tile unit count per tile edge. World coordinates
## are scaled by `SUBTILE_UNITS` relative to tile
## coordinates, so a position at the centre of a tile is at
## `(0.5 * SUBTILE_UNITS, 0.5 * SUBTILE_UNITS)` in world
## coordinates relative to that tile's origin. Pinned to 256
## to keep the math simple (one byte of fraction).
const SUBTILE_UNITS: int = 256

## The origin of a tile in world coordinates. Tile `(0, 0)`
## is at world `(0, 0)`; world grows right (x) and down (y)
## on the screen; tile coordinates grow right (x) and down
## (y) on the grid (ADR-0004).
const ORIGIN: Vector2 = Vector2(0.0, 0.0)


## Convert a tile coordinate to world coordinates. Returns
## the position of the tile's TOP-LEFT corner in world
## units. The tile is `TILE_W` units wide and `TILE_H`
## units tall in world space; the centre of the tile is at
## `(tile_to_world(t) + (TILE_W/2, TILE_H/2))`.
##
## The function is the canonical reference for ADR-0004's
## `tile_to_world`. It is pure: same input → same output,
## no side effects, no scene-tree access.
static func tile_to_world(tile: Vector2i) -> Vector2:
	return Vector2(float(tile.x) * float(TILE_W), float(tile.y) * float(TILE_H))


## Convert world coordinates to a tile coordinate. The result
## is the integer tile that contains `world_pos`. `world_pos`
## is in world units; out-of-bounds positions are NOT clamped
## (use the grid's `is_in_bounds` to test validity, since
## "what tile contains this off-grid point" is a meaningful
## question during a click that lands just outside the
## realm).
##
## The function is the canonical reference for ADR-0004's
## `world_to_tile`. It is pure.
static func world_to_tile(world_pos: Vector2) -> Vector2i:
	# Integer floor division. Negative coordinates floor
	# towards negative infinity, so a `world_pos` of `(-1,
	# -1)` maps to tile `(-1, -1)`, not `(0, 0)`. This is
	# the conventional mathematical floor and matches
	# every other "grid → continuous" conversion in
	# ADR-0004.
	var tx: int = int(floor(world_pos.x / float(TILE_W)))
	var ty: int = int(floor(world_pos.y / float(TILE_H)))
	return Vector2i(tx, ty)


## Painter's-algorithm z-order for a tile. Tiles are drawn
## in `(y, x)` order, back-to-front, so the visible top
## edge of a tile overlaps the bottom edge of the tile
## behind it (ADR-0004). The returned integer is unique per
## tile in a single grid and is monotonic in `y + x`: a
## tile with a larger `y + x` is in front of a tile with a
## smaller `y + x`.
##
## The function is the canonical reference for ADR-0004's
## `tile_z_order`. It is pure.
static func tile_z_order(tile: Vector2i) -> int:
	# `y + x` is the depth axis. We multiply by a width
	# bound so two tiles with the same `y + x` but
	# different `x` still get a stable order. The bound
	# is the canonical `INT32_MAX / 4`, which is large
	# enough that any real grid stays within it.
	return (tile.y + tile.x) * 1073741824 + tile.x
