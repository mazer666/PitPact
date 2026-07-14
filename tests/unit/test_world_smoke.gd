# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — smoke test for the Track A world data model.
#
# This test exists to prove the M1 spatial track compiles
# end-to-end: Grid, ZoneGrid, ZoneOps.find_zones, and
# WorldState round-trip cleanly. It is intentionally
# minimal; the real coverage is in
# `tests/unit/test_grid.gd`, `tests/unit/test_zone.gd`,
# and `tests/integration/test_hearth_lifecycle.gd`.
extends GutTest

## Cached class references. `gdlint` flags repeated
## `load(...)` calls as `duplicated-load`; cache once at
## module load.
const GRID_CLASS: Script = preload("res://src/world/grid.gd")
const ZONE_OPS_CLASS: Script = preload("res://src/world/zone.gd")


func test_grid_from_seed_is_deterministic() -> void:
	var g_a: Object = GRID_CLASS.call("from_seed", 0xDEADBEEF, 8, 8)
	var g_b: Object = GRID_CLASS.call("from_seed", 0xDEADBEEF, 8, 8)
	for i in range(64):
		var ta: Object = g_a.tiles[i]
		var tb: Object = g_b.tiles[i]
		assert_eq(ta.id, tb.id, "Grid.from_seed tile %d id mismatch" % i)
		assert_eq(String(ta.biome), String(tb.biome), "Grid.from_seed tile %d biome mismatch" % i)


func test_grid_bounds_checking() -> void:
	var g: Object = GRID_CLASS.new(4, 4, 0)
	assert_true(g.is_in_bounds(0, 0), "(0, 0) is in bounds")
	assert_true(g.is_in_bounds(3, 3), "(3, 3) is in bounds")
	assert_false(g.is_in_bounds(4, 0), "(4, 0) is out of bounds")
	assert_false(g.is_in_bounds(-1, 0), "(-1, 0) is out of bounds")
	assert_null(g.tile_at(4, 0), "out-of-bounds tile_at returns null")


func test_zone_paint_and_find_zones() -> void:
	var zone_grid_script: Script = ZONE_OPS_CLASS.ZoneGrid
	var zg: Object = zone_grid_script.new(8, 8)
	var rect: Rect2i = Rect2i(Vector2i(2, 2), Vector2i(3, 3))
	var zones: Array = ZONE_OPS_CLASS.call("paint", zg, rect, ZONE_OPS_CLASS.ZonePurpose.HEARTH)
	assert_eq(zones.size(), 1, "One zone for a single rectangle")
	var z = zones[0]
	assert_eq(z.purpose, ZONE_OPS_CLASS.ZonePurpose.HEARTH, "Zone purpose is HEARTH")
	assert_eq(z.tiles.size(), 9, "3x3 rect = 9 tiles")


func test_world_state_create_and_paint() -> void:
	var ws: Object = WorldState.create(0xC0FFEE, 6, 6)
	assert_eq(ws.grid.w, 6, "WorldState grid width")
	assert_eq(ws.grid.h, 6, "WorldState grid height")
	assert_eq(ws.zone_grid.purpose_at(0, 0), 0, "default purpose is EMPTY")
	var rect: Rect2i = Rect2i(Vector2i(1, 1), Vector2i(2, 2))
	ws.paint_zone(rect, 2)  # 2 = HEARTH
	assert_eq(ws.zone_at(1, 1), 2, "painted tile has HEARTH purpose")
	var zones: Array = ws.find_zones(2)
	assert_eq(zones.size(), 1, "One HEARTH zone after paint")
