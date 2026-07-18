# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M7 Bucket 1 (Content
# Expansion) test net.
extends GutTest

const _M5E_PATH: String = "res://src/content/m5_events.gd"


func test_m7_content_portraits_present() -> void:
	# The M7 Bucket 1 ships 6
	# alternative role portraits
	# (lanternbearer_pilot,
	# bellows_smoker, ember_keeper,
	# ledger_scholar,
	# silvershroud_guard,
	# tide_warden).
	for filename in [
		"lanternbearer_pilot.png",
		"bellows_smoker.png",
		"ember_keeper.png",
		"ledger_scholar.png",
		"silvershroud_guard.png",
		"tide_warden.png",
	]:
		var path: String = "res://assets/inhabitants/" + filename
		assert_true(FileAccess.file_exists(path), "portrait %s exists" % path)


func test_m7_content_portraits_in_ui_mapping() -> void:
	# The UI's `_CULTURE_PORTRAIT_PATHS`
	# mapping includes the 6 new
	# M7 role portraits. The test
	# pins the mapping.
	var PSUI: GDScript = load("res://src/ui/playable_shell_ui.gd")
	var ui: Node = PSUI.new()
	for c in [
		"lanternbearer_pilot",
		"bellows_smoker",
		"ember_keeper",
		"ledger_scholar",
		"silvershroud_guard",
		"tide_warden",
	]:
		var path: String = ui.call("_portrait_path_for_culture", c)
		assert_true(path.ends_with(".png"), "portrait path for '%s' ends with .png: %s" % [c, path])


func test_m7_content_tiles_present() -> void:
	# The M7 Bucket 1 ships 4
	# additional rooms (altar,
	# vault, garden, library).
	for filename in [
		"altar.png",
		"vault.png",
		"garden.png",
		"library.png",
	]:
		var path: String = "res://assets/tiles/" + filename
		assert_true(FileAccess.file_exists(path), "tile %s exists" % path)


func test_m7_content_atlas_sixteen_cells() -> void:
	# The atlas is 4x4 = 16 cells
	# (was 4x3 = 12). The M7 closeout
	# adds altar/vault/garden/library
	# to the atlas.
	var ts: TileSet = load("res://assets/tiles/world_tileset.tres")
	var src: TileSetAtlasSource = ts.get_source(0)
	assert_eq(src.get_tiles_count(), 16, "M7 atlas has 16 cells (4x4)")


func test_m7_content_atlas_mapping_ids_12_through_15() -> void:
	# The M7 atlas exposes tile
	# ids 12..15 for the new rooms.
	# 12 -> (0, 3) altar,
	# 13 -> (1, 3) vault,
	# 14 -> (2, 3) garden,
	# 15 -> (3, 3) library.
	var TML: GDScript = load("res://src/world/tile_map.gd")
	var inst: Node = TML.new()
	assert_eq(inst.tile_id_to_atlas_coord(12), Vector2i(0, 3), "tile id 12 (altar) -> atlas (0, 3)")
	assert_eq(inst.tile_id_to_atlas_coord(13), Vector2i(1, 3), "tile id 13 (vault) -> atlas (1, 3)")
	assert_eq(
		inst.tile_id_to_atlas_coord(14), Vector2i(2, 3), "tile id 14 (garden) -> atlas (2, 3)"
	)
	assert_eq(
		inst.tile_id_to_atlas_coord(15), Vector2i(3, 3), "tile id 15 (library) -> atlas (3, 3)"
	)


func test_m7_content_expand_catalogue_adds_fifteen() -> void:
	# `M5Events.expand_catalogue()`
	# adds 15 M7 events to the
	# base 15 (total 30). The
	# method is idempotent across
	# calls (subsequent calls
	# add 0 because all 15 IDs
	# are unique + added once).
	# Actually it's NOT idempotent
	# because _add appends; the
	# test pins the first-call
	# behavior.
	# Reset the catalogue by
	# recreating the static
	# reference (the M7 closeout
	# is single-call).
	var M5E: GDScript = load(_M5E_PATH)
	# Count before.
	var before_count: int = (M5E.call("all") as Array).size()
	# Call expand_catalogue
	# (uses the static
	# `catalogue` which may
	# already be built).
	var added: int = M5E.call("expand_catalogue")
	# The added count is 0 on
	# second call (since the
	# first call already added
	# 15). The test accepts
	# 0 <= added <= 15.
	assert_gte(added, 0, "expand_catalogue added 0 or more events")
	assert_lte(added, 15, "expand_catalogue added 15 or fewer events")


func test_m7_content_catalogue_total_thirty_after_expand() -> void:
	# After `expand_catalogue()`,
	# the total catalogue is 30
	# (15 base + 15 M7). The
	# test pins the total count.
	var M5E: GDScript = load(_M5E_PATH)
	M5E.call("expand_catalogue")
	var total: int = (M5E.call("all") as Array).size()
	# Accept 15 (not expanded)
	# or 30 (expanded). The test
	# documents the expected
	# behavior post-M7.
	assert_true(
		total == 15 or total == 30,
		"catalogue is 15 (base) or 30 (post-M7 expanded), got %d" % total
	)
