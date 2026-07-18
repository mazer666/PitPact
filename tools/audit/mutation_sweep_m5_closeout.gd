# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
# PitPact — M5-Closeout (Bucket 4) mutation sweep.
extends SceneTree


const _GUT_CMDLN: String = "res://addons/gut/gut_cmdln.gd"
const _TEST_PATH: String = "res://tests/integration"
const _TEST_NAME: String = "test_m5_game_state"
const _LOG_PATH: String = "/tmp/mutation_sweep_m5_closeout.log"


var _mutations: Array[Dictionary] = []


func _init() -> void:
	_mutations = [
		{
			"id": "gs-version-typo",
			"desc": "M5GameState version typo (0.2.0-m5-closeout -> 9.9.9)",
			"file": "res://src/sim/m5_game_state.gd",
			"find": "0.2.0-m5-closeout",
			"replace": "9.9.9-bad",
		},
		{
			"id": "gs-win-days-typo",
			"desc": "M5GameState WIN_DAYS_SURVIVED (30 -> 0)",
			"file": "res://src/sim/m5_game_state.gd",
			"find": "const WIN_DAYS_SURVIVED: int = 30",
			"replace": "const WIN_DAYS_SURVIVED: int = 0",
		},
		{
			"id": "gs-lose-reason-typo",
			"desc": "M5GameState lose reason typo (lose_no_inhabitants -> win)",
			"file": "res://src/sim/m5_game_state.gd",
			"find": '"lose_no_inhabitants"',
			"replace": '"win_survived"',
		},
		{
			"id": "gs-evaluate-skip",
			"desc": "M5GameState.evaluate is a no-op",
			"file": "res://src/sim/m5_game_state.gd",
			"find": "func evaluate(sim: Variant) -> void:",
			"replace": "func evaluate(sim: Variant) -> void:\n\treturn",
		},
		{
			"id": "ps-build-with-seed-no-override",
			"desc": "PlayableShell.build_with_seed does not override",
			"file": "res://src/ui/playable_shell.gd",
			"find": "_current_seed_override = p_seed\n\tvar result: Dictionary = build()",
			"replace": "var result: Dictionary = build()",
		},
		{
			"id": "ps-effective-seed-typo",
			"desc": "PlayableShell._effective_seed returns wrong seed",
			"file": "res://src/ui/playable_shell.gd",
			"find": "if _current_seed_override >= 0:\n\t\treturn _current_seed_override\n\treturn SEED",
			"replace": "if _current_seed_override >= 0:\n\t\treturn _current_seed_override\n\treturn 0",
		},
		{
			"id": "ui-show-game-over-typo",
			"desc": "PlayableShellUI._show_game_over does not set visible",
			"file": "res://src/ui/playable_shell_ui.gd",
			"find": "_game_over_banner.visible = true",
			"replace": "_game_over_banner.visible = false",
		},
		{
			"id": "ui-restart-no-bump",
			"desc": "PlayableShellUI._on_restart_pressed does not bump seed",
			"file": "res://src/ui/playable_shell_ui.gd",
			"find": "_current_seed += 1",
			"replace": "_current_seed += 0",
		},
		{
			"id": "ui-tick-no-game-state",
			"desc": "PlayableShellUI._on_step_pressed does not tick game_state",
			"file": "res://src/ui/playable_shell_ui.gd",
			"find": "if game_state != null:\n\t\tgame_state.tick_day_with_world(sim, world)",
			"replace": "if game_state != null:\n\t\tpass  # mutation: skip tick",
		},
	]


func _run_gut() -> String:
	var output: Array = []
	OS.execute(
		"godot", ["--headless", "--path", ".",
		"-s", _GUT_CMDLN,
		"-gdir=" + _TEST_PATH,
		"-gtest=res://tests/integration/" + _TEST_NAME + ".gd",
		"-gexit"], output, true, false
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


func _apply_mutation(m: Dictionary) -> bool:
	var path: String = String(m["file"])
	var original: String = _read_file(path)
	var content: String = original
	content = content.replace(String(m["find"]), String(m["replace"]))
	if content == original:
		push_error("Mutation %s: could not find pattern" % m["id"])
		return false
	_write_file(path, content)
	OS.execute(
		"godot", ["--headless", "--path", ".",
		"--quit-after", "1"], [], true, false
	)
	var stdout: String = _run_gut()
	_write_file(path, original)
	OS.execute(
		"godot", ["--headless", "--path", ".",
		"--quit-after", "1"], [], true, false
	)
	var failed_count: int = 0
	for line in stdout.split("\n"):
		if line.strip_edges().begins_with("Failing"):
			var parts: PackedStringArray = line.strip_edges().split(" ", false)
			if parts.size() >= 2:
				failed_count = int(parts[1])
	print("[%d] %s: %s" % [failed_count, m["id"], "REAL" if failed_count > 0 else "SILENT"])
	return failed_count > 0


func _initialize() -> void:
	print("=== M5-Closeout Bucket 4 Mutation-Sweep ===")
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
