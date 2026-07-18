# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M5-Closeout Bucket 2 (Ten Rooms)
# test net.
#
# The M5-Closeout Bucket 2 deliverable
# (per ADR-0017) is the canonical "ten
# rooms" expansion: 4 new tiles (shrine,
# forge, well, trap) + atlas extension
# from 4x2 to 4x3. The test net exercises:
#
#   1. The 4 new tile PNGs exist
#      (shrine, forge, well, trap).
#   2. The atlas has 12 cells (4x3).
#   3. The WorldGenerator places the
#      4 new rooms in the world
#      (around the hearth).
#   4. The M5GameState counts the
#      4 new rooms (shrine_count,
#      forge_count, well_count,
#      trap_count).
#   5. The tile_id_to_atlas_coord
#      mapping covers 0..11.
extends GutTest

const _PS_PATH: String = "res://src/ui/playable_shell.gd"
const _TILESET_PATH: String = "res://assets/tiles/world_tileset.tres"


func test_ten_rooms_new_tile_pngs_exist() -> void:
	# The M5-Closeout Bucket 2 ships
	# 4 new tile PNGs (shrine, forge,
	# well, trap). The test asserts
	# each file exists.
	for filename in ["shrine.png", "forge.png", "well.png", "trap.png"]:
		var path: String = "res://assets/tiles/" + filename
		assert_true(FileAccess.file_exists(path), "tile PNG %s exists" % path)


func test_ten_rooms_tile_count() -> void:
	# The M5-Closeout Bucket 2
	# expanded the asset folder
	# from 7 to 11 PNGs (4 new
	# tiles + 1 atlas). The test
	# pins the canonical count.
	var d: DirAccess = DirAccess.open("res://assets/tiles/")
	assert_ne(d, null, "assets/tiles/ exists")
	var n: int = 0
	d.list_dir_begin()
	var name: String = d.get_next()
	while name != "":
		if not d.current_is_dir() and name.ends_with(".png"):
			n += 1
		name = d.get_next()
	d.list_dir_end()
	assert_eq(n, 11, "assets/tiles/ has 11 PNGs (7 + 4 new rooms)")


func test_ten_rooms_atlas_twelve_cells() -> void:
	# The atlas is 4x3 = 12 cells
	# (was 4x2 = 8). The TileSet
	# resource has 12 atlas
	# cells. The test pins the
	# count.
	var ts: TileSet = load(_TILESET_PATH)
	assert_ne(ts, null, "world_tileset.tres loads")
	var src: TileSetAtlasSource = ts.get_source(0)
	assert_eq(src.get_tiles_count(), 12, "M5-Closeout atlas has 12 cells (4x3)")


func test_ten_rooms_atlas_mapping_ids_8_through_11() -> void:
	# The M5-Closeout atlas exposes
	# tile ids 0..11. The mapping
	# `(id % 4, id / 4)` covers
	# the new room tiles in row 2:
	# 8 -> (0, 2) shrine,
	# 9 -> (1, 2) forge,
	# 10 -> (2, 2) well,
	# 11 -> (3, 2) trap.
	var TML: GDScript = load("res://src/world/tile_map.gd")
	var inst: Node = TML.new()
	assert_eq(inst.tile_id_to_atlas_coord(8), Vector2i(0, 2), "tile id 8 (shrine) -> atlas (0, 2)")
	assert_eq(inst.tile_id_to_atlas_coord(9), Vector2i(1, 2), "tile id 9 (forge) -> atlas (1, 2)")
	assert_eq(inst.tile_id_to_atlas_coord(10), Vector2i(2, 2), "tile id 10 (well) -> atlas (2, 2)")
	assert_eq(inst.tile_id_to_atlas_coord(11), Vector2i(3, 2), "tile id 11 (trap) -> atlas (3, 2)")


func test_ten_rooms_world_has_shrine_forge_well_trap() -> void:
	# The M5-Closeout WorldGenerator
	# places 1 shrine + 1 forge +
	# 1 well + 1 trap around the
	# hearth. The test asserts the
	# counts are >= 1 each.
	var PS: GDScript = load(_PS_PATH)
	var built: Dictionary = PS.call("build")
	var gs: M5GameState = built["game_state"]
	gs.tick_day_with_world(built["sim"], built["world"])
	assert_gte(gs.shrine_count, 1, "shrine_count >= 1")
	assert_gte(gs.forge_count, 1, "forge_count >= 1")
	assert_gte(gs.well_count, 1, "well_count >= 1")
	assert_gte(gs.trap_count, 1, "trap_count >= 1")


func test_ten_rooms_win_requires_all_four_new_rooms() -> void:
	# The M5-Closeout win condition
	# (M5-Closeout Bucket 4) requires
	# at least 1 hearth + 1 shrine +
	# 1 forge + 1 well + 1 trap +
	# 4 inhabitants + 30 days. The
	# Bucket 2 ships the room-side
	# of the win condition. The test
	# pins the multi-constraint.
	var GS: GDScript = load("res://src/sim/m5_game_state.gd")
	var gs: M5GameState = GS.make()
	gs.days_survived = 30
	gs.inhabitant_count = 4
	gs.hearth_count = 1
	gs.shrine_count = 0  # missing
	gs.forge_count = 1
	gs.well_count = 1
	gs.trap_count = 1
	gs.evaluate(null)
	assert_eq(gs.outcome, "playing", "missing shrine = still playing")
	# Add shrine.
	gs.shrine_count = 1
	gs.evaluate(null)
	assert_eq(gs.outcome, "win", "all rooms + 30 days + 4 inhabitants = win")
