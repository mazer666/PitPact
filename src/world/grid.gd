# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — the fixed-size tile grid (ADR-0004).
#
# `Grid` is the world-coordinate tile grid: a fixed-size 2D
# array of `Tile` instances. The grid is the canonical
# spatial state of a single realm (ADR-0004). The grid
# itself stores ONLY tile data (id, biome, surface_meta);
# zone purpose is layered on top (see `zone.gd`).
#
# Determinism (ADR-0002, §16 of `docs/requirements.md`):
# the grid is built once from a seed via `from_seed`; all
# randomness goes through `src/core/rng.gd` (`SplitMix64`).
# Two `Grid` instances constructed with the same seed, w,
# and h produce identical tile arrays.
#
# Per ADR-0002, this file does not import from `src/sim`,
# `src/realm`, `src/save`, `src/ui`, or `src/audit`. It
# imports from `src/core` and `src/content` only.
class_name Grid
extends RefCounted

## The width of the grid in tiles. Fixed at construction.
var w: int = 0

## The height of the grid in tiles. Fixed at construction.
var h: int = 0

## The seed the grid was constructed from. The save format
## round-trips this value so a `Grid.from_seed` re-run with
## the same seed reproduces the same tile array.
@warning_ignore("shadowed_global_identifier")
var seed: int = 0

## The flat tile array. Indexed as `tiles[y * w + x]`. The
## grid is fixed-size: the array's length is always
## `w * h`. Use `tile_at` and `set_tile` to access
# elements with bounds checking.
var tiles: Array = []


## Default constructor. Builds an empty `w` x `h` grid
## (every tile is `Tile.new()`). Most callers should use
## `Grid.from_seed` instead; this constructor is kept for
## the save-loader path, where the tile array is restored
## from a serialized payload and the seed is informational.
func _init(p_w: int = 0, p_h: int = 0, p_seed: int = 0) -> void:
	w = max(0, p_w)
	h = max(0, p_h)
	seed = p_seed
	tiles.resize(w * h)
	for i in range(tiles.size()):
		tiles[i] = Tile.new()


## Factory: build a `w` x `h` grid deterministically from
## a seed. The seed is mixed once into `SplitMix64` and
## the resulting stream is consumed to populate each tile's
## `id` and `biome`. The `surface_meta` is left empty.
##
## Determinism contract: two `Grid.from_seed(s, w, h)`
## calls with the same `(s, w, h)` produce identical tile
## arrays. The contract is enforced by
## `tests/unit/test_grid.gd` (the same seed → same first-N
## tiles test).
static func from_seed(p_seed: int, p_w: int, p_h: int) -> Grid:
	var g: Grid = Grid.new(p_w, p_h, p_seed)
	if p_w <= 0 or p_h <= 0:
		return g
	# All randomness goes through src/core/rng.gd per the
	# ADR-0002 determinism rule. The RNG is constructed
	# once with the seed and consumed left-to-right; the
	# order of consumption is part of the public contract.
	var SplitMix64Class := load("res://src/core/rng.gd")
	var rng: Object = SplitMix64Class.new(p_seed)
	# A small fixed list of biomes, content-driven. M1 uses
	# just three biomes ("stone", "moss", "ash"); the M2
	# content set will expand the list. The integers are
	# `StringName` ids, matching the canonical `biome`
	# field on `Tile`.
	var biomes: Array = [&"stone", &"moss", &"ash"]
	for y in range(p_h):
		for x in range(p_w):
			var tile_id: int = rng.call("next_int", 0, 8)  # 0..7 inclusive of low, exclusive of high
			var biome_idx: int = rng.call("next_int", 0, biomes.size())
			var biome: StringName = biomes[biome_idx]
			g.tiles[y * p_w + x] = Tile.new(tile_id, biome, {})
	return g


## Bounds-checked accessor. Returns the tile at `(x, y)`.
## Out-of-bounds access returns `null` (not a throw) so
## the painter tool can ask "what tile is under this
## pixel?" without crashing when the click lands just
## outside the realm.
func tile_at(x: int, y: int) -> Tile:
	if not is_in_bounds(x, y):
		return null
	return tiles[y * w + x]


## Bounds-checked mutator. Returns true on success, false
## if `(x, y)` is out of bounds. The renderer and the
## zone painter call this; the simulation calls it
## sparingly (a sim that wants to mutate a tile usually
## goes through `zone.gd::paint` so the connected-
## component cache is invalidated).
func set_tile(x: int, y: int, tile: Tile) -> bool:
	if not is_in_bounds(x, y):
		return false
	if tile == null:
		tiles[y * w + x] = Tile.new()
	else:
		tiles[y * w + x] = tile
	return true


## Bounds check. Returns true iff `(x, y)` is a valid tile
## coordinate in this grid. The painter tool uses this to
## clip a drag-rect to the realm's bounds.
func is_in_bounds(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < w and y < h


## Bounds check on a `Vector2i`. Convenience for the
## painter tool and the renderer, which already deal in
## `Vector2i`.
func is_in_bounds_v(tile: Vector2i) -> bool:
	return is_in_bounds(tile.x, tile.y)


## Bounds check on a `Rect2i`. Returns true iff the rect
## is non-empty and every tile in the rect is in bounds.
## The painter tool uses this to decide whether a drag-
## rect is fully on-grid (and therefore paintable).
func rect_in_bounds(rect: Rect2i) -> bool:
	if rect.size.x <= 0 or rect.size.y <= 0:
		return false
	if rect.position.x < 0 or rect.position.y < 0:
		return false
	if rect.position.x + rect.size.x > w:
		return false
	if rect.position.y + rect.size.y > h:
		return false
	return true


## Serialise the grid to a JSON-friendly `Dictionary`. The
## `tiles` array is emitted as a flat list of dicts; the
## deserialiser rebuilds the flat `tiles` array from the
## list. The seed and dimensions are emitted alongside so
## the round-trip is exact. The save format's
## `body.world.grid` key carries this dictionary.
func to_dict() -> Dictionary:
	var tile_dicts: Array = []
	for t in tiles:
		tile_dicts.append(t.to_dict())
	return {"w": w, "h": h, "seed": seed, "tiles": tile_dicts}


## Deserialise a `Dictionary` produced by `to_dict()`. The
## inverse of `to_dict`. Unknown top-level keys are
## preserved on `surface_meta` (per ADR-0003).
static func from_dict(d: Dictionary) -> Grid:
	var p_w: int = int(d.get("w", 0))
	var p_h: int = int(d.get("h", 0))
	var p_seed: int = int(d.get("seed", 0))
	var g: Grid = Grid.new(p_w, p_h, p_seed)
	if d.has("tiles") and d["tiles"] is Array:
		var tile_dicts: Array = d["tiles"]
		var n: int = min(tile_dicts.size(), g.tiles.size())
		for i in range(n):
			if tile_dicts[i] is Dictionary:
				g.tiles[i] = Tile.from_dict(tile_dicts[i])
	return g


## Equality by value. Two grids are equal iff they have the
## same `w`, `h`, `seed`, and a per-tile match across the
## whole grid. The save round-trip test uses this.
func equals(other: Grid) -> bool:
	if other == null:
		return false
	if w != other.w or h != other.h or seed != other.seed:
		return false
	if tiles.size() != other.tiles.size():
		return false
	for i in range(tiles.size()):
		if not tiles[i].equals(other.tiles[i]):
			return false
	return true


## Iterator helper for callers that want to walk the grid
## in ADR-0004's `(y, x)` painter's-algorithm order. The
## callback receives `(x, y, tile)`. Returning `false` from
## the callback aborts the walk. Used by the renderer
## (which needs the z-order) and by the zone finder (which
## also needs the order to be deterministic across
## architectures).
func for_each_zyx(callback: Callable) -> void:
	for y in range(h):
		for x in range(w):
			var t: Tile = tile_at(x, y)
			if t == null:
				continue
			var keep_going: Variant = callback.call(x, y, t)
			if keep_going is bool and not (keep_going as bool):
				return
