# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — GUT integration test for the diagnostics overlay
# and the minimap toggle behaviour.
#
# The contract:
#   - calling `toggle()` twice on either controller returns
#     the visibility to its original state,
#   - the toggle methods are exposed on both controllers
#     and are callable.
extends GutTest

const _DIAG_PATH := "res://src/ui/diagnostics_overlay.gd"
const _MINIMAP_PATH := "res://src/ui/minimap.gd"
const _MAIN_PATH := "res://src/ui/main.gd"


## Test 1: `DiagnosticsOverlayController.toggle()` is
## symmetric — two calls return the visibility to its
## initial state. The M1 default is hidden. The toggle
## method is exercised in isolation, without adding the
## overlay to the scene tree (the overlay is a
## CanvasLayer; its `_ready()` calls `_find_label(...)`
## which requires a real scene tree).
func test_diagnostics_toggle_round_trip() -> void:
	var DiagClass: Script = load(_DIAG_PATH)
	var diag = DiagClass.new()
	var initial: bool = diag.visible
	diag.toggle()
	assert_ne(diag.visible, initial, "first toggle() must flip visibility")
	diag.toggle()
	assert_eq(diag.visible, initial, "second toggle() must restore visibility")
	diag.free()


## Test 2: `MinimapController.toggle()` is symmetric.
func test_minimap_toggle_round_trip() -> void:
	var MinimapClass: Script = load(_MINIMAP_PATH)
	var minimap = MinimapClass.new()
	var initial: bool = minimap.visible
	minimap.toggle()
	assert_ne(minimap.visible, initial, "first toggle() must flip visibility")
	minimap.toggle()
	assert_eq(minimap.visible, initial, "second toggle() must restore visibility")
	minimap.free()


## Test 3: the main controller's reduced-motion setter
## is exposed. The propagation to the camera is a
## runtime concern (the camera is a child of the
## main); M1 just plumbs the flag.
func test_main_set_reduced_motion_exposed() -> void:
	# The MainSceneController class is registered in
	# the global class table at import time. We check
	# the source code for the `set_reduced_motion`
	# entry point; GDScript class_name methods are not
	# exposed via ClassDB.
	var main_script: GDScript = load("res://src/ui/main.gd")
	assert_not_null(main_script, "main.gd must load")
	var source: String = main_script.source_code
	assert_true(
		source.find("func set_reduced_motion(") >= 0,
		"MainSceneController must expose set_reduced_motion(bool)"
	)
	# Reduced-motion is a stub for M1; the test asserts
	# the surface is callable and that the field exists
	# on the class (so the M5 wiring is a no-op). We
	# instantiate via the class_name (registered at
	# import time) rather than `load(...)` to keep the
	# test readable.
	var main: MainSceneController = MainSceneController.new()
	main.set_reduced_motion(true)
	assert_eq(main.reduced_motion, true, "set_reduced_motion(true) sets the flag")
	main.set_reduced_motion(false)
	assert_eq(main.reduced_motion, false, "set_reduced_motion(false) clears the flag")
	main.free()
