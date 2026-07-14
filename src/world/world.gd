# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — the per-realm spatial state (WorldState).
#
# `WorldState` is the public entry point of `src/world/`,
# per ADR-0002 §"public entry point". It composes the
# `Grid` (tile data) and the `ZoneGrid` (zone purposes)
# into a single object that the realm façade and the UI
# can hold. One `WorldState` per loaded realm.
#
# Construction is exclusively via `WorldState.create(...)`;
# direct `_init` calls are an internal implementation
# detail. The create factory takes the seed and dimensions
# and routes the seed through `Grid.from_seed` so the
# determinism contract is preserved.
#
# Per ADR-0002, this file does not import from `src/sim`,
# `src/realm`, `src/save`, `src/ui`, or `src/audit`. It
# imports from `src/core` and `src/content` only.
class_name WorldState
extends RefCounted

## Cached reference to `src/world/zone.gd` so we don't
## call `load(...)` on every paint/lookup. Loading
## repeatedly is the kind of thing gdlint flags as
## `duplicated-load`.
const ZoneOpsClass: Script = preload("res://src/world/zone.gd")

## The realm's tile grid.
var grid: Grid

## The realm's zone-purpose grid.
var zone_grid: RefCounted

## The seed the world was created from.
var seed: int = 0

## The version of the world state.
var version: int = 0


## Default constructor. Builds a `w` x `h` world state
## with the given seed.
func _init(p_seed: int, p_w: int, p_h: int) -> void:
	seed = p_seed
	grid = Grid.from_seed(p_seed, p_w, p_h)
	zone_grid = ZoneOpsClass.ZoneGrid.new(p_w, p_h)
	version = 0


## Factory: build a `WorldState` of the given dimensions
## from a seed.
static func create(p_seed: int, p_w: int, p_h: int) -> RefCounted:
	return WorldState.new(p_seed, p_w, p_h)


## Apply a rectangular zone paint.
func paint_zone(rect: Rect2i, purpose: int) -> Array:
	if zone_grid == null:
		return []
	var zones: Array = ZoneOpsClass.paint(zone_grid, rect, purpose)
	version += 1
	return zones


## Find all zones of the given purpose.
func find_zones(purpose: int) -> Array:
	if zone_grid == null:
		return []
	return ZoneOpsClass.find_zones(zone_grid, purpose)


## Look up the zone purpose of a single tile.
func zone_at(x: int, y: int) -> int:
	if zone_grid == null:
		return 0
	return zone_grid.purpose_at(x, y)


## Convert a tile coordinate to world coordinates.
func tile_to_world(tile: Vector2i) -> Vector2:
	return WorldCoordinates.tile_to_world(tile)


## Inverse: world -> tile.
func world_to_tile(world_pos: Vector2) -> Vector2i:
	return WorldCoordinates.world_to_tile(world_pos)


## Serialise the world state to a JSON-friendly dict.
func to_dict() -> Dictionary:
	return {
		"seed": seed,
		"version": version,
		"grid": grid.to_dict() if grid != null else {},
		"zone_grid": zone_grid.to_dict() if zone_grid != null else {}
	}


## Deserialise a dict produced by `to_dict()`.
static func from_dict(d: Dictionary) -> RefCounted:
	var p_seed: int = int(d.get("seed", 0))
	var grid_dict: Dictionary = d.get("grid", {})
	var w: int = int(grid_dict.get("w", 0))
	var h: int = int(grid_dict.get("h", 0))
	var ws: RefCounted = WorldState.new(p_seed, w, h)
	if d.has("grid") and d["grid"] is Dictionary:
		ws.grid = Grid.from_dict(d["grid"])
	if d.has("zone_grid") and d["zone_grid"] is Dictionary:
		ws.zone_grid = ZoneOpsClass.ZoneGrid.from_dict(d["zone_grid"])
	if d.has("version"):
		ws.version = int(d["version"])
	return ws


## Equality by value.
func equals(other) -> bool:
	if other == null:
		return false
	if seed != other.seed:
		return false
	if not grid.equals(other.grid):
		return false
	if not zone_grid.equals(other.zone_grid):
		return false
	return true


## Library version.
static func module_version() -> String:
	return "0.2.0-m1-spatial"
