# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
# PitPact — M5-Foundation PlayableShell-Scene mutation sweep.
#
# This script runs the M5-Foundation
# PlayableShell-Scene integration tests
# against mutations. Each mutation flips a
# canonical "production" value to a "bad"
# value, runs the test, and asserts the
# test fails (REAL mutation = the test
# catches the bug).
#
# Run with:
#   godot --headless --path . \
#     -s res://tools/audit/mutation_sweep_m5_scene.gd
extends SceneTree


const _GUT_CMDLN: String = "res://addons/gut/gut_cmdln.gd"
const _TEST_PATH: String = "res://tests/integration"
const _TEST_FILTERS: Array[String] = [
	"test_playable_shell_scene",
	"test_playable_shell_render",
]
const _LOG_PATH: String = "/tmp/mutation_sweep_m5_scene.log"


var _mutations: Array[Dictionary] = []


func _init() -> void:
	_mutations = [
		{
			"id": "tileset-path-typo",
			"desc": "WorldTileMapLayer._TILE_ATLAS_PATH typo (res://...)",
			"file": "res://src/world/tile_map.gd",
			"find": "res://assets/tiles/world_tileset.tres",
			"replace": "res://assets/tiles/WRONG_tileset.tres",
		},
		{
			"id": "atlas-coord-mapping-flip",
			"desc": "WorldTileMapLayer.tile_id_to_atlas_coord (row/col swap)",
			"file": "res://src/world/tile_map.gd",
			"find": "return Vector2i(tile_id % 4, tile_id / 4)",
			"replace": "return Vector2i(tile_id / 4, tile_id % 4)",
		},
		{
			"id": "ui-portrait-path-typo",
			"desc": "PlayableShellUI portrait path typo",
			"file": "res://src/ui/playable_shell_ui.gd",
			"find": "res://assets/inhabitants/lanternbearer_scribe.png",
			"replace": "res://assets/inhabitants/WRONG_portrait.png",
		},
		{
			"id": "ui-power-icon-path-typo",
			"desc": "PlayableShellUI power icon path typo",
			"file": "res://src/ui/playable_shell_ui.gd",
			"find": "res://assets/ui/power_%s.png",
			"replace": "res://assets/ui/WRONG_%s.png",
		},
		{
			"id": "ui-built-guard-removed",
			"desc": "PlayableShellUI._built guard removed (build runs twice)",
			"file": "res://src/ui/playable_shell_ui.gd",
			"find": "\tif _built:\n\t\treturn\n\t_built = true\n",
			"replace": "",
		},
		{
			"id": "ui-format-day-label-broken",
			"desc": "PlayableShellUI.format_day_label broken (case)",
			"file": "res://src/ui/playable_shell_ui.gd",
			"find": "return \"Day %d\" % int(day)",
			"replace": "return \"DAY %d\" % int(day)",
		},
	]


func _run_gut() -> String:
	# Run GUT with the M5-Foundation
	# PlayableShell-Scene test filter.
	var gut_args: PackedStringArray = PackedStringArray()
	gut_args.append("-gdir=" + _TEST_PATH)
	for filter in _TEST_FILTERS:
		gut_args.append("-gtest=res://tests/integration/" + filter + ".gd")
	gut_args.append("-gexit")
	var output: Array = []
	var exit_code: int = OS.execute(
		"godot", ["--headless", "--path", ".",
		"-s", _GUT_CMDLN] + Array(gut_args), output, true, false
	)
	var stdout: String = ""
	for line in output:
		stdout += String(line) + "\n"
	return stdout


func _read_file(path: String) -> String:
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return ""
	return f.get_as_text()


func _write_file(path: String, content: String) -> void:
	var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	f.store_string(content)


func _restore_file(path: String, original: String) -> void:
	_write_file(path, original)


func _apply_mutation(m: Dictionary) -> bool:
	# Returns true if the mutation
	# is REAL (the test fails).
	var path: String = String(m["file"])
	var original: String = _read_file(path)
	var content: String = original
	content = content.replace(String(m["find"]), String(m["replace"]))
	if content == original:
		# Mutation couldn't be applied.
		push_error("Mutation %s: could not find pattern" % m["id"])
		return false
	_write_file(path, content)
	# Re-import.
	OS.execute(
		"godot", ["--headless", "--path", ".",
		"--quit-after", "1"], [], true, false
	)
	# Run the test.
	var stdout: String = _run_gut()
	# Restore the file.
	_restore_file(path, original)
	# The mutation is REAL if the test
	# fails (i.e. tests_failed > 0).
	var failed: bool = stdout.find("Failing") != -1
	var failed_count: int = 0
	var lines: PackedStringArray = stdout.split("\n")
	for line in lines:
		if line.strip_edges().begins_with("Failing"):
			var parts: PackedStringArray = line.strip_edges().split(" ", false)
			if parts.size() >= 2:
				failed_count = int(parts[1])
	# We restore and re-import
	OS.execute(
		"godot", ["--headless", "--path", ".",
		"--quit-after", "1"], [], true, false
	)
	# Print result
	print("[%d] %s: %s" % [failed_count, m["id"], "REAL" if failed_count > 0 else "SILENT"])
	return failed_count > 0


func _initialize() -> void:
	# The mutation sweep runs the
	# M5-Foundation PlayableShell-Scene
	# tests against each mutation. The
	# output is the REAL/SILENT count.
	print("=== M5-Foundation PlayableShell-Scene Mutation-Sweep ===")
	var real: int = 0
	var silent: int = 0
	for m in _mutations:
		var is_real: bool = _apply_mutation(m)
		if is_real:
			real += 1
		else:
			silent += 1
	print("Real: %d  Silent: %d  Skipped: %d" % [real, silent, 0])
	quit(0)
