# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — the fog-of-war data carrier (M3-foundation skeleton).
#
# `ExplorationMap` is the per-realm fog-of-war state.
# The exploration map is a 2D grid of `bool` values
# aligned with the realm's tile grid; a tile is
# "revealed" iff `revealed[y * w + x]` is `true`. The
# M3 acceptance criterion "exploration" (§8 of
# `docs/requirements.md`) is the player-driven
# reveal of the realm's tiles; the renderer reads
# the map and either renders a tile in full (revealed)
# or as a darkened silhouette (unrevealed).
#
# The skeleton declares the public surface that M3
# cycle 2 (Track A) will fill in. The fields are:
#
#   * `w`, `h` — the grid's dimensions in tiles. The
#     dimensions are fixed at construction; resizing
#     the map mid-campaign is not supported (a
#     resized map is a new map; the realm façade
#     tears the old one down and constructs a new
#     one).
#   * `revealed` — a flat 2D `Array` of `bool` values.
#     Indexed as `revealed[y * w + x]`. The M3 default
#     is "all tiles are unrevealed except the Hearth's
#     tile and its 3x3 neighbourhood" (the player
#     always starts near the Hearth). The M3 cycle 2
#     (Track A) commit pins the initial-reveal rule.
#   * `home_position` — the Hearth's tile coordinate.
#     The save/load pipeline (ADR-0003) round-trips
#     this value under `body.world.exploration.
#     home_position`. A negative value
#     (`Vector2i(-1, -1)`) means "the Hearth has not
#     been placed yet"; the realm façade treats
#     that case as "no home, no initial reveal".
#
# Per ADR-0002, this file does not import from
# `src/ui`, `src/sim`, `src/realm`, `src/save`, or
# `src/audit`. It imports from `src/core` and
# `src/content` only.
class_name ExplorationMap
extends RefCounted

## The width of the fog-of-war grid, in tiles.
## Fixed at construction. The save body stores
## this value under `body.world.exploration.w`.
var w: int = 0

## The height of the fog-of-war grid, in tiles.
## Fixed at construction. The save body stores
## this value under `body.world.exploration.h`.
var h: int = 0

## The flat 2D `Array` of `bool` values. Indexed
## as `revealed[y * w + x]`. The M3 default is
## "all tiles are unrevealed except the Hearth's
## tile and its 3x3 neighbourhood" (the M3 cycle
## 2 Track A commit pins the rule). The save body
## stores this array under
## `body.world.exploration.revealed`.
var revealed: Array = []

## The Hearth's tile coordinate. The save body
## stores this value under
## `body.world.exploration.home_position`. A
## negative value (`Vector2i(-1, -1)`) means "the
## Hearth has not been placed yet"; the realm
## façade treats that case as "no home, no
## initial reveal".
var home_position: Vector2i = Vector2i(-1, -1)


## Default constructor. Builds a `p_w` x `p_h`
## fog-of-war grid with all tiles unrevealed and
## the Hearth at `Vector2i(-1, -1)`. The M3 cycle
## 2 (Track A) commit adds a constructor variant
## that accepts the realm's `WorldMap` and applies
## the initial-reveal rule.
func _init(p_w: int = 0, p_h: int = 0) -> void:
	w = max(0, p_w)
	h = max(0, p_h)
	revealed.resize(w * h)
	for i in range(revealed.size()):
		revealed[i] = false
	home_position = Vector2i(-1, -1)


## Bounds check. Returns true iff `(x, y)` is a
## valid tile coordinate in this grid. The
## renderer uses this to clip a "reveal this
## area" request to the realm's bounds.
func is_in_bounds(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < w and y < h


## Bounds check on a `Vector2i`. Convenience for
## the renderer, which already deals in
## `Vector2i`.
func is_in_bounds_v(tile: Vector2i) -> bool:
	return is_in_bounds(tile.x, tile.y)


## Reveal a single tile. Returns true on success,
## false if `(x, y)` is out of bounds. The M3
## cycle 2 (Track A) commit pins the per-tile
## reveal rule (the M3 default is "a tile is
## revealed if the player can see it from an
## adjacent revealed tile or from the Hearth").
##
## The M3-foundation skeleton ships a no-op
## implementation: the function records the
## value but does not propagate. The propagation
## rule is the M3 cycle 2 commit's responsibility.
func reveal(x: int, y: int) -> bool:
	if not is_in_bounds(x, y):
		return false
	revealed[y * w + x] = true
	return true


## Equality by value. Two exploration maps are
## equal iff they have the same `w`, `h`,
## `home_position`, and a per-tile match across
## the whole `revealed` array. Used by the M3
## cycle 2 (Track A) determinism test to assert
## the generator's exploration map is deep-equal
## across two runs of the same seed.
func equals(other: ExplorationMap) -> bool:
	if other == null:
		return false
	if w != other.w or h != other.h:
		return false
	if home_position != other.home_position:
		return false
	if revealed.size() != other.revealed.size():
		return false
	for i in range(revealed.size()):
		if bool(revealed[i]) != bool(other.revealed[i]):
			return false
	return true
