# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — zone data structure and operations (ADR-0004).
#
# A `Zone` is a maximal connected set of tiles of the same
# purpose (ADR-0004). Two tiles are connected iff they
# share an edge (4-connectivity; diagonals do not connect).
# A zone is *maximal*: a fourth tile adjacent to an
# existing three-tile zone is part of the same zone, not a
# new zone.
#
# Per ADR-0004:
#   * Zones are not stored as a list of tiles. They are
#     stored as a single `ZonePurpose` per tile. Connected-
#     component computation is on-demand and cached. The
#     cache is invalidated when a tile's `ZonePurpose`
#     changes.
#   * Zone purpose is stored on the GRID, not on the tile.
#     This keeps the tile data model engine-agnostic and
#     keeps the zone-vs-room separation clean (a room is
#     a promoted zone, layered on top of the grid).
#
# Per ADR-0002, this file does not import from `src/sim`,
# `src/realm`, `src/save`, `src/ui`, or `src/audit`. It
# imports from `src/core` and `src/content` only.
class_name ZoneOps
extends RefCounted

## Zone purposes (ADR-0004). The set is content-driven
## (M2+ extends it); the M1 cycle pins the values the
## `Hearth` room cares about. The enum is `int` for
## stable JSON round-trip; the M1 save format encodes
## the integer and the deserialiser verifies it.
enum ZonePurpose {
	EMPTY = 0,
	FLOORED = 1,
	HEARTH = 2,
	PRODUCTION = 3,
	RESEARCH = 4,
	DEFENCE = 5,
	HABITATION = 6,
}


## The zone-purpose grid. Parallel to the `Grid.tiles`
## array: `zone_grid.purposes[y * w + x]` is the purpose
## of the tile at `(x, y)`. The grid's `w` and `h` are
## the authoritative dimensions; the zone-purpose array
## is rebuilt when the grid dimensions change.
##
## A `ZoneGrid` is the data structure that holds the
## `ZonePurpose` per tile; it is separate from `Grid` so
## that the grid can be a pure tile data model and so
## that the save format can serialise the two
## independently (the grid is content, the zone purposes
## are player input).
##
## Inner class (not `class_name`d): referenced as
## `ZoneOps.ZoneGrid` or via the constructor below.
class ZoneGrid:
	extends RefCounted

	## The width of the grid in tiles. Mirrors `Grid.w`.
	var w: int = 0

	## The height of the grid in tiles. Mirrors `Grid.h`.
	var h: int = 0

	## The flat zone-purpose array. Indexed as
	## `purposes[y * w + x]`. Default `EMPTY`.
	var purposes: Array = []

	## A monotonic counter bumped on every write to
	## `purposes`. Callers that want to cache a
	## connected-component result can compare the counter
	## at write time to the counter at read time; on
	## mismatch the cache is stale and must be
	## recomputed. This is the documented
	## cache-invalidation rule from ADR-0004.
	var version: int = 0

	func _init(p_w: int = 0, p_h: int = 0) -> void:
		w = max(0, p_w)
		h = max(0, p_h)
		purposes.resize(w * h)
		for i in range(purposes.size()):
			purposes[i] = ZoneOps.ZonePurpose.EMPTY
		version = 0

	func purpose_at(x: int, y: int) -> int:
		if not is_in_bounds(x, y):
			return ZoneOps.ZonePurpose.EMPTY
		return purposes[y * w + x]

	func set_purpose(x: int, y: int, purpose: int) -> bool:
		if not is_in_bounds(x, y):
			return false
		purposes[y * w + x] = purpose
		version += 1
		return true

	func is_in_bounds(x: int, y: int) -> bool:
		return x >= 0 and y >= 0 and x < w and y < h

	## Paint a rectangular region's purpose. Returns the
	## number of tiles that were actually painted (clipped
	## to the grid). Bumps `version` exactly once per
	## call regardless of how many tiles were affected,
	## so a caller caching by `version` does not have to
	## worry about per-tile granularity.
	func paint_rect(rect: Rect2i, purpose: int) -> int:
		if not _rect_in_bounds(rect):
			return 0
		var painted: int = 0
		for y in range(rect.position.y, rect.position.y + rect.size.y):
			for x in range(rect.position.x, rect.position.x + rect.size.x):
				purposes[y * w + x] = purpose
				painted += 1
		version += 1
		return painted

	func to_dict() -> Dictionary:
		return {"w": w, "h": h, "purposes": purposes.duplicate(), "version": version}

	static func from_dict(d: Dictionary) -> ZoneGrid:
		var p_w: int = int(d.get("w", 0))
		var p_h: int = int(d.get("h", 0))
		var z: ZoneGrid = ZoneGrid.new(p_w, p_h)
		if d.has("purposes") and d["purposes"] is Array:
			var arr: Array = d["purposes"]
			var n: int = min(arr.size(), z.purposes.size())
			for i in range(n):
				z.purposes[i] = int(arr[i])
		if d.has("version"):
			z.version = int(d["version"])
		return z

	func equals(other) -> bool:
		if other == null:
			return false
		if w != other.w or h != other.h:
			return false
		if purposes.size() != other.purposes.size():
			return false
		for i in range(purposes.size()):
			if purposes[i] != other.purposes[i]:
				return false
		return true

	func _rect_in_bounds(rect: Rect2i) -> bool:
		if rect.size.x <= 0 or rect.size.y <= 0:
			return false
		if rect.position.x < 0 or rect.position.y < 0:
			return false
		if rect.position.x + rect.size.x > w:
			return false
		if rect.position.y + rect.size.y > h:
			return false
		return true


## A single zone's data. The list of tile coordinates
## belonging to the zone and the bounding box of the
## zone (used by the renderer to draw an overlay and by
## the save format to record the zone compactly).
class Zone:
	extends RefCounted

	var purpose: int = 0
	var tiles: Array = []  # Array[Vector2i]
	var bounds: Rect2i = Rect2i(0, 0, 0, 0)

	func _init(p_purpose: int = 0) -> void:
		purpose = p_purpose


## Find all maximal connected components of the given
## purpose in the zone grid. Returns an `Array[Zone]`. The
## algorithm is iterative flood-fill with an explicit
## stack so it works on grids of any size without
## recursion-depth concerns.
##
## Determinism: the walk order is `(y, x)` ascending, so
## two grids with the same `purposes` array produce the
## same list of zones in the same order. The order is
## stable across architectures and Godot versions.
static func find_zones(grid: ZoneGrid, purpose: int) -> Array:
	var zones: Array = []
	if grid == null or grid.w <= 0 or grid.h <= 0:
		return zones
	# Visited is a `PackedByteArray` of the same size as
	# `purposes`. We pack it as bytes because the
	# alternative (a `Dictionary[Vector2i, bool]`) is two
	# orders of magnitude slower on the M5 reference
	# 256x256 grid.
	var visited: PackedByteArray = PackedByteArray()
	visited.resize(grid.purposes.size())
	for i in range(visited.size()):
		visited[i] = 0
	for y in range(grid.h):
		for x in range(grid.w):
			var idx: int = y * grid.w + x
			if visited[idx] != 0:
				continue
			if grid.purposes[idx] != purpose:
				continue
			# New zone: flood-fill from (x, y).
			var zone: Zone = Zone.new(purpose)
			var stack: Array = [Vector2i(x, y)]
			var min_x: int = x
			var min_y: int = y
			var max_x: int = x
			var max_y: int = y
			while stack.size() > 0:
				var cur: Vector2i = stack.pop_back()
				var cy: int = cur.y
				var cx: int = cur.x
				var cidx: int = cy * grid.w + cx
				if visited[cidx] != 0:
					continue
				if grid.purposes[cidx] != purpose:
					continue
				visited[cidx] = 1
				zone.tiles.append(cur)
				if cx < min_x:
					min_x = cx
				if cx > max_x:
					max_x = cx
				if cy < min_y:
					min_y = cy
				if cy > max_y:
					max_y = cy
				# 4-connectivity: push the four
				# cardinal neighbours.
				if cx > 0:
					stack.push_back(Vector2i(cx - 1, cy))
				if cx < grid.w - 1:
					stack.push_back(Vector2i(cx + 1, cy))
				if cy > 0:
					stack.push_back(Vector2i(cx, cy - 1))
				if cy < grid.h - 1:
					stack.push_back(Vector2i(cx, cy + 1))
			zone.bounds = Rect2i(
				Vector2i(min_x, min_y), Vector2i(max_x - min_x + 1, max_y - min_y + 1)
			)
			zones.append(zone)
	return zones


## Convenience: paint a rectangular region's purpose and
## return the list of zones that intersect the rect
## after the paint. The two-step (paint + find_zones) is
## the public entry point the M1 painter tool uses; the
## full grid can be re-scanned via
## `find_zones(grid, purpose)` instead.
static func paint(grid: ZoneGrid, rect: Rect2i, purpose: int) -> Array:
	grid.paint_rect(rect, purpose)
	return find_zones(grid, purpose)
