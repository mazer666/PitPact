# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — GUT 9 headless test entry point.
#
# This script is invoked by tools/run_quality.sh (and by
# CI) with:
#
#   godot --headless --path . --script res://tests/_smoke/test_runner.gd
#
# It boots GUT 9 against the project's test directory,
# streams the GUT log to stdout, and exits with GUT's exit
# code (0 = all green, 1 = at least one failure).
#
# Why a custom entry point rather than GUT's own
# `gut_cmdln.gd`?
#   - GUT 9's command-line shim hardcodes `res://addons/gut/`
#     paths throughout (see tests/gut/gut_cmdln.gd and 75+
#     other vendored files). Per the spec, the vendored copy
#     lives at `tests/gut/`. Rather than patch every hardcoded
#     path, we expose the vendored copy at the conventional
#     `res://addons/gut/` location via a single symlink
#     created on demand by this script. The vendored source
#     is unmodified; the symlink is not committed (see
#     .gitignore).
#   - GUT 9's CLI shim launches a UI runner scene
#     (`gut_cmdln.gd` does `load('res://addons/gut/gui/GutRunner.tscn')`).
#     A headless run does not need the UI; instantiating
#     the `.tscn` is wasted work and prints UI noise.
#
# This script performs three jobs:
#   1. Ensure `addons/gut` is a valid loadable path (creates
#      the symlink if missing; the symlink is a no-op on
#      Windows where GUT must live at `addons/gut/` directly,
#      so on Windows we *copy* the directory instead).
#   2. Pre-instantiate the GUT test runner so we can drive
#      it without a `GutRunner.tscn` scene (which is wired
#      for the editor UI).
#   3. Walk the test directory, run every `test_*.gd` script,
#      and report.
#
# The script never modifies the source tree; the only side
# effect on disk is the `addons/gut` symlink (or copy on
# Windows), which is ignored by .gitignore.
extends SceneTree

const _GUT_VENDORED_PATH := "res://tests/gut"
const _GUT_RES_PATH := "res://addons/gut"
const _GUT_RES_DIR := "res://addons"
const _TEST_DIR := "res://tests"
const _TEST_PREFIX := "test_"
const _TEST_SUFFIX := ".gd"

# `OS.execute` is unavailable from a SceneTree script, so we
# delegate the symlink-or-copy step to a small OS shim. The
# shim is a one-liner Bash file written next to this script
# so the runner is self-contained and reproducible from a
# fresh clone.
const _SHIM_PATH := "res://tests/_smoke/_ensure_gut_path.sh"


func _initialize() -> void:
	# 1. Make `res://addons/gut` resolvable.
	_ensure_gut_loadable()

	# 2. Load GUT's test runner directly. GUT 9's `Gut` class
	#    is a Node that runs tests; we instantiate it,
	#    configure it for headless output, and add it to
	#    the root before running.
	#
	#    Important: GUT's classes (e.g. `GutUtils`,
	#    `GutHookScript`) are resolved through Godot's
	#    global class registry, which is populated by
	#    `godot --import`. We cannot run `godot --import`
	#    from inside a SceneTree script (it requires editor
	#    mode), so the parent suite (`tools/run_quality.sh`)
	#    is responsible for running `--import` after the
	#    symlink is created. The dependency is documented
	#    in tools/README.md and tests/README.md.
	var GutClass: Script = load(_GUT_RES_PATH + "/gut.gd")
	if GutClass == null:
		printerr(
			"[test_runner] FATAL: could not load ",
			_GUT_RES_PATH + "/gut.gd",
			"; did `godot --headless --import` run after creating the symlink?"
		)
		quit(2)
		return

	var gut: Node = GutClass.new()
	gut.set("ran_from_editor", false)
	gut.set("log_level", 1)  # LOG_LEVEL_TEST_AND_FAILURES
	gut.set("disable_strict_datatype_checks", true)
	gut.set("include_subdirectories", true)
	root.add_child(gut)

	# 3. Hand every test_*.gd under res://tests to GUT.
	#    GUT's API is `add_directory(path, prefix, suffix)`;
	#    the `dirs` property on the GUT config object is
	#    what the CLI shim reads, but the GUT instance
	#    itself does not have a `dirs` property — calling
	#    `add_directory` is the supported programmatic
	#    entry point.
	gut.call("add_directory", _TEST_DIR, _TEST_PREFIX, _TEST_SUFFIX)

	# 4. Hook the end-run signal so we can quit with the
	#    right exit code.
	var on_end := Callable(self, "_on_gut_end_run")
	# GUT emits `end_run` with no args; we bind the
	# signature explicitly so the call matches.
	gut.connect("end_run", on_end)

	# 5. Kick off the test run.
	gut.call("run_tests")

	# Process one frame so `end_run` can fire; if no tests
	# were found, GUT will call `end_run` synchronously.
	await process_frame


func _on_gut_end_run() -> void:
	# Translate GUT's "any failures?" into the exit code
	# the local quality suite expects. GUT's API for
	# counting failures has been stable across the
	# 9.x line; if a future GUT version changes the
	# accessor, this is the one place to fix.
	var gut: Node = root.get_node_or_null("Gut")
	if gut == null:
		# Fallback: scan the tree by name pattern.
		for c in root.get_children():
			if c.name == "Gut" or (c.get("get_gut") != null):
				gut = c
				break

	var exit_code: int = 0
	if gut != null:
		var fail_count: int = 0
		# GUT 9 exposes a Summary object via `get_summary()`;
		# older 9.x exposed `get_fail_count()` directly.
		if gut.has_method("get_fail_count"):
			fail_count = int(gut.call("get_fail_count"))
		elif gut.has_method("get_summary"):
			var summary: Object = gut.call("get_summary")
			if summary != null and summary.has_method("get_totals"):
				var totals: Dictionary = summary.call("get_totals")
				fail_count = int(totals.get("failed", 0))
		if fail_count > 0:
			exit_code = 1

	quit(exit_code)


# --- helpers -------------------------------------------------------------


func _ensure_gut_loadable() -> void:
	# Fast path: the symlink/copy already exists, GUT loads.
	if ResourceLoader.exists(_GUT_RES_PATH + "/gut.gd"):
		return

	# Slow path: create the symlink (POSIX) or copy the
	# directory (Windows). The shim script handles the
	# platform branch; the GDScript side just runs it and
	# propagates the exit code.
	var shim_abs := ProjectSettings.globalize_path(_SHIM_PATH)
	var os_name: String = OS.get_name()
	print(
		"[test_runner] addons/gut not present; bootstrapping via ", shim_abs, " (OS=", os_name, ")"
	)
	var rc: int = OS.execute("sh", [shim_abs])
	if rc != 0:
		printerr("[test_runner] FATAL: gut bootstrap shim exited with code ", rc)
		quit(2)
		return

	if not ResourceLoader.exists(_GUT_RES_PATH + "/gut.gd"):
		printerr("[test_runner] FATAL: addons/gut still not loadable after bootstrap")
		quit(2)
