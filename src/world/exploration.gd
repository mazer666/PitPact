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
# Per ADR-0002, this file does not import from
# `src/ui`, `src/sim`, `src/realm`, `src/save`, or
# `src/audit`. It imports from `src/core` and
# `src/content` only.
class_name ExplorationMap
extends RefCounted

## The width of the fog-of-war grid, in tiles.
var w: int = 0

## The height of the fog-of-war grid, in tiles.
var h: int = 0

## The flat 2D `Array` of `bool` values. Indexed
## as `revealed[y * w + x]`.
var revealed: Array = []

## The Hearth's tile coordinate.
var home_position: Vector2i = Vector2i(-1, -1)


## Default constructor. Builds a `p_w` x `p_h`
## fog-of-war grid with all tiles unrevealed and
## the Hearth at `Vector2i(-1, -1)`. A non-negative
## `p_home_position` reveals the Hearth's tile and
## its `p_initial_radius`-Manhattan neighbourhood.
func _init(
	p_w: int = 0,
	p_h: int = 0,
	p_home_position: Vector2i = Vector2i(-1, -1),
	p_initial_radius: int = 1
) -> void:
	w = max(0, p_w)
	h = max(0, p_h)
	home_position = p_home_position
	revealed.resize(w * h)
	for i in range(revealed.size()):
		revealed[i] = false
	if (
		home_position.x >= 0
		and home_position.y >= 0
		and home_position.x < w
		and home_position.y < h
	):
		reveal(home_position, max(0, p_initial_radius))


## Bounds check. Returns true iff `(x, y)` is a
## valid tile coordinate in this grid.
func is_in_bounds(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < w and y < h


## Bounds check on a `Vector2i`.
func is_in_bounds_v(tile: Vector2i) -> bool:
	return is_in_bounds(tile.x, tile.y)


## Reveal a single tile. Returns `true` on success,
## `false` if `(x, y)` is out of bounds. The
## M3-Closeout is the canonical entry point for
## "the player explores a single tile".
func reveal_tile(x: int, y: int) -> bool:
	if not is_in_bounds(x, y):
		return false
	revealed[y * w + x] = true
	return true


## Reveal the `radius`-Manhattan neighbourhood
## around `position`. A Manhattan neighbourhood
## is the set of tiles `(x', y')` such that
## `|x' - position.x| + |y' - position.y| <=
## radius`. Returns the newly-revealed tiles as
## an `Array` of `Vector2i` (in painter's-
## algorithm order). The M3 sim's per-tick
## step 7a (`ExplorationStep.run`) calls this
## entry point; the call site reads
## `emap.reveal(target, 2)`.
func reveal(position: Vector2i, radius: int) -> Array:
	var newly_revealed: Array = []
	var r: int = max(0, radius)
	if not is_in_bounds_v(position):
		return newly_revealed
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			if abs(dx) + abs(dy) > r:
				continue
			var nx: int = position.x + dx
			var ny: int = position.y + dy
			if not is_in_bounds(nx, ny):
				continue
			var idx: int = ny * w + nx
			if not bool(revealed[idx]):
				revealed[idx] = true
				newly_revealed.append(Vector2i(nx, ny))
	return newly_revealed


## Alias for `reveal`. The two-argument form is
## the canonical entry point; the alias exists
## for callers that prefer the verb "reveal a
## radius" (the M3-Closeout shipped
## `reveal_radius` first and the sim's per-tick
## step 7a calls it; the alias keeps the older
## name working).
func reveal_radius(position: Vector2i, radius: int) -> Array:
	return reveal(position, radius)


## Count the revealed tiles.
func count_revealed() -> int:
	var n: int = 0
	for v in revealed:
		if bool(v):
			n += 1
	return n


## Total tile count.
func total_tiles() -> int:
	return w * h


## Whether the realm is fully revealed.
func is_fully_revealed() -> bool:
	return count_revealed() >= total_tiles()


## Pick the nearest unrevealed tile to `from`.
## The walk is a BFS from `from` over the
## 4-connected grid.
func nearest_unrevealed(from: Vector2i) -> Variant:
	if is_fully_revealed():
		return null
	if not is_in_bounds_v(from):
		return null
	var visited: PackedByteArray = PackedByteArray()
	visited.resize(revealed.size())
	for i in range(visited.size()):
		visited[i] = 0
	var queue: Array = [from]
	visited[from.y * w + from.x] = 1
	while queue.size() > 0:
		var cur: Vector2i = queue.pop_front()
		if not bool(revealed[cur.y * w + cur.x]):
			return cur
		var neighbours: Array = [
			Vector2i(cur.x - 1, cur.y),
			Vector2i(cur.x + 1, cur.y),
			Vector2i(cur.x, cur.y - 1),
			Vector2i(cur.x, cur.y + 1),
		]
		for nb in neighbours:
			if not is_in_bounds_v(nb):
				continue
			var nidx: int = nb.y * w + nb.x
			if visited[nidx] != 0:
				continue
			visited[nidx] = 1
			queue.push_back(nb)
	return null


## Equality by value.
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
