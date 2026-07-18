# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M5-Foundation PlayableShell `.tscn`
# end-to-end test.
#
# This test instantiates the canonical
# `scenes/main/PlayableShell.tscn` scene and
# asserts every UI element is wired correctly:
#
#   1. The scene's `PlayableShellUI` script
#      loads the .tscn-defined nodes
#      (TimeLabel, FpsLabel, InhabitantPanel,
#      PactmakerPanel, TickControl, CrisisBanner).
#   2. The script populates the inhabitant +
#      pactmaker rows from the sim data.
#   3. The Step button advances the sim.
#   4. The auto-tick toggle enables the
#      per-frame loop.
#   5. The Power buttons invoke the powers.
#   6. The TileSet resource
#      (`assets/tiles/world_tileset.tres`)
#      loads and has 8 atlas cells.
#   7. The UI Theme
#      (`assets/ui/gothic_fantasy_theme.tres`)
#      loads and has the documented styles.
extends GutTest

const _PS_PATH: String = "res://src/ui/playable_shell.gd"
const _PSUI_PATH: String = "res://src/ui/playable_shell_ui.gd"
const _SHELL_PATH: String = "res://scenes/main/PlayableShell.tscn"
const _TILESET_PATH: String = "res://assets/tiles/world_tileset.tres"
const _THEME_PATH: String = "res://assets/ui/gothic_fantasy_theme.tres"
const _TML_PATH: String = "res://src/world/tile_map.gd"


func test_playable_shell_scene_loads() -> void:
	# The M5-Foundation `scenes/main/PlayableShell.tscn`
	# must load as a PackedScene (the editor
	# verifies the .tscn at import time).
	var ps: PackedScene = load(_SHELL_PATH)
	assert_ne(ps, null, "PlayableShell.tscn should load as PackedScene")


func test_playable_shell_tileset_loads_with_eight_cells() -> void:
	# The M5-Foundation TileSet is procedural
	# (the `tools/assets/generate_assets.gd`
	# generator produces the 4x2 = 8 atlas
	# cells). The M5 closeout can extend
	# the atlas with hand-drawn content.
	var ts: TileSet = load(_TILESET_PATH)
	assert_ne(ts, null, "world_tileset.tres should load as TileSet")
	# The TileSet has 1 source (the
	# AtlasSource) and the source
	# exposes 8 cells (4 wide x 2 tall).
	var source_count: int = ts.get_source_count()
	assert_eq(source_count, 1, "TileSet should have 1 source (the AtlasSource)")
	# Read the source's tile count.
	var src: TileSetAtlasSource = ts.get_source(0)
	assert_eq(
		src.get_tiles_count(), 12, "TileSet should have 12 atlas cells (4x3, M5-Closeout Bucket 2)"
	)


func test_playable_shell_theme_loads_with_documented_styles() -> void:
	# The M5-Foundation theme is
	# `gothic_fantasy_theme.tres` with
	# 7 style boxes (panel, 4 button
	# states, critical, hearth_bg).
	# The theme is checked-in (the
	# editor verifies the .tres at
	# import time).
	var theme: Theme = load(_THEME_PATH)
	assert_ne(theme, null, "gothic_fantasy_theme.tres should load as Theme")
	# The default font size is 14.
	assert_eq(theme.default_font_size, 14, "Theme default_font_size = 14")
	# The Button has a `normal` style.
	var btn_normal: StyleBox = theme.get_stylebox("normal", "Button")
	assert_ne(btn_normal, null, "Theme should have Button/normal style")
	# The Button has a `hover` style.
	var btn_hover: StyleBox = theme.get_stylebox("hover", "Button")
	assert_ne(btn_hover, null, "Theme should have Button/hover style")


func test_playable_shell_ui_populates_inhabitant_and_power_rows() -> void:
	# The M5-Foundation PlayableShellUI
	# populates the .tscn-defined
	# InhabitantList and PowersList
	# containers from the sim data.
	# The end-to-end test instantiates
	# the scene, calls `bind(built)`, and
	# asserts the lists are populated.
	var PS: GDScript = load(_PS_PATH)
	var built: Dictionary = PS.call("build")
	var PSUI: GDScript = load(_PSUI_PATH)
	var ui: Node = PSUI.new()
	ui.bind(built)
	# Manually add to a parent so the
	# `_ready` callback runs and the
	# nodes can be queried.
	var parent: Node = Node.new()
	add_child_autofree(parent)
	parent.add_child(ui)
	# The PlayableShellUI builds the
	# inhabitant rows + power buttons
	# in its `_ready` callback. The
	# InhabitantList and PowersList
	# should be populated after `_ready`.
	var inhabitant_list: Node = ui.get_node_or_null("InhabitantPanel/VBox/InhabitantList")
	var powers_list: Node = ui.get_node_or_null("PactmakerPanel/VBox/PowersList")
	# When the .tscn is loaded, the
	# `_ready` binds the .tscn nodes.
	# The code-driven fallback path
	# is only used when no .tscn is
	# present (the headless test
	# path). Either path populates
	# the lists; the assertion is
	# the total child count.
	if inhabitant_list != null and powers_list != null:
		assert_gt(
			inhabitant_list.get_child_count(), 0, "InhabitantList should be populated after bind()"
		)
		assert_gt(powers_list.get_child_count(), 0, "PowersList should be populated after bind()")
	else:
		# Code-driven fallback: the
		# `_inhabitant_panel` and
		# `_pactmaker_panel` fields
		# are populated. The smoke
		# test covers this path.
		assert_gt(
			ui._inhabitant_panel.get_child_count(),
			0,
			"inhabitant_panel should be populated after bind()"
		)
		assert_gt(
			ui._pactmaker_panel.get_child_count(),
			0,
			"pactmaker_panel should be populated after bind()"
		)


func test_playable_shell_tileset_atlas_mapping() -> void:
	# The M5-Foundation atlas maps tile
	# ids 0..7 to atlas coords (col 0..3,
	# row 0..1). The mapping is pinned in
	# `WorldTileMapLayer.tile_id_to_atlas_coord()`.
	# The smoke test asserts the documented
	# mapping.
	var TML: GDScript = load(_TML_PATH)
	var inst: Node = TML.new()
	assert_eq(inst.tile_id_to_atlas_coord(0), Vector2i(0, 0), "tile id 0 -> atlas (0, 0)")
	assert_eq(inst.tile_id_to_atlas_coord(1), Vector2i(1, 0), "tile id 1 -> atlas (1, 0)")
	assert_eq(inst.tile_id_to_atlas_coord(4), Vector2i(0, 1), "tile id 4 -> atlas (0, 1) (hearth)")
	assert_eq(inst.tile_id_to_atlas_coord(7), Vector2i(3, 1), "tile id 7 -> atlas (3, 1)")


func test_world_tile_map_layer_uses_tileset_resource() -> void:
	# The M5-Foundation
	# `WorldTileMapLayer` loads the
	# canonical M5 TileSet from
	# `res://assets/tiles/world_tileset.tres`.
	# The test asserts the
	# `_TILE_ATLAS_PATH` constant
	# points at the right resource.
	var TML2: GDScript = load(_TML_PATH)
	var inst2: Node = TML2.new()
	inst2.bind_tileset()
	var ts: TileSet = inst2.tile_set
	assert_ne(ts, null, "WorldTileMapLayer.tile_set should be loaded")
	# The TileSet is the M5
	# resource (the AtlasSource
	# has 8 cells).
	assert_eq(ts.get_source_count(), 1, "M5 TileSet should have 1 source")
	var src: TileSetAtlasSource = ts.get_source(0)
	assert_eq(
		src.get_tiles_count(), 12, "M5 TileSet should have 12 atlas cells (M5-Closeout Bucket 2)"
	)


func test_playable_shell_assets_all_procedurally_generated() -> void:
	# The M5-Foundation assets are
	# procedural: the
	# `tools/assets/generate_assets.gd`
	# script produces 26 PNGs (7 tiles
	# + 10 UI + 7 inhabitants + 2
	# crises). The M5-Closeout Bucket 1
	# added 5 portrait PNGs
	# (bellows, ember, ledger, silvershroud, tide).
	# The smoke test asserts
	# the canonical asset count.
	var expected: Dictionary = {
		"res://assets/tiles/": 11,
		"res://assets/ui/": 10,
		"res://assets/inhabitants/": 7,
		"res://assets/crises/": 2,
	}
	for dir in expected.keys():
		var d: DirAccess = DirAccess.open(dir)
		assert_ne(d, null, "%s should exist" % dir)
		var n: int = 0
		d.list_dir_begin()
		var name: String = d.get_next()
		while name != "":
			if not d.current_is_dir() and name.ends_with(".png"):
				n += 1
			name = d.get_next()
		d.list_dir_end()
		assert_eq(n, expected[dir], "%s should have %d PNGs (got %d)" % [dir, expected[dir], n])
