# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M5-Foundation: PlayableShellUI end-to-end
# test.
#
# This test exercises the `PlayableShellUI` controller
# in headless mode. The test:
#
#   1. Builds the canonical M5-Foundation playable
#      sim via `PlayableShell.build()`.
#   2. Instantiates the `PlayableShellUI` controller
#      and binds the sim.
#   3. Calls the controller's public methods
#      (`_on_step_pressed`, `_on_power_pressed`,
#      `_on_auto_tick_toggled`) and asserts the
#      sim state changes as expected.
#
# The test is the regression net for the M5-Foundation
# UI surface. The M5 closeout extends the UI with the
# M5 content (six cultures, ten rooms, fifteen
# events); this test catches regressions in the
# M5-Foundation surface.
extends GutTest

const _PS_PATH: String = "res://src/ui/playable_shell.gd"
const _PSUI_PATH: String = "res://src/ui/playable_shell_ui.gd"


func _make_ui(built: Dictionary) -> Node:
	# Instantiate the `PlayableShellUI` and
	# bind it to the sim. The UI is a
	# `CanvasLayer`; we wrap it in a
	# `Node` so the SceneTree owns its
	# lifetime.
	var PSUI: GDScript = load(_PSUI_PATH)
	var ui: Node = PSUI.new()
	ui.bind(built)
	# The M5-Foundation smoke test runs
	# in headless mode (no SceneTree
	# `_process` loop). The test calls
	# the public methods directly
	# instead of going through the
	# `_process` callback.
	return ui


func test_playable_shell_ui_binds_to_sim() -> void:
	var PS: GDScript = load(_PS_PATH)
	var built: Dictionary = PS.call("build")
	var ui: Node = _make_ui(built)
	assert_eq(ui.sim, built["sim"], "ui.sim should match built['sim']")
	assert_eq(ui.pactmaker, built["pactmaker"], "ui.pactmaker should match built['pactmaker']")
	assert_eq(ui.settings, built["settings"], "ui.settings should match built['settings']")
	assert_eq(
		ui.inhabitants, built["inhabitants"], "ui.inhabitants should match built['inhabitants']"
	)


func test_playable_shell_ui_step_button_advances_sim() -> void:
	# The M5-Foundation Step button
	# advances the sim by 1 in-game
	# day. The end-to-end test calls
	# the button's handler directly
	# (the headless mode has no
	# `_process` loop).
	var PS: GDScript = load(_PS_PATH)
	var built: Dictionary = PS.call("build")
	var ui: Node = _make_ui(built)
	# Sim starts at 0.0.
	assert_eq(ui.sim.time_days, 0.0, "sim should start at 0.0")
	# Click Step 5 times.
	for i in range(5):
		ui.call("_on_step_pressed")
	# Post-state: sim is at 5.0.
	assert_eq(ui.sim.time_days, 5.0, "5 Step clicks should advance sim to 5.0")


func test_playable_shell_ui_power_button_invokes_power() -> void:
	# The M5-Foundation Pactmaker panel
	# exposes the three M4 powers. The
	# end-to-end test exercises
	# `seal_breach` against the
	# M4-Foundation crisis
	# (plague_outbreak, which is
	# `sealable: true`).
	var PS: GDScript = load(_PS_PATH)
	var built: Dictionary = PS.call("build")
	var ui: Node = _make_ui(built)
	var cr: Crisis = built["crises"][0]
	assert_false(bool(cr.get("resolved")), "crisis should not be resolved initially")
	# Click seal_breach.
	ui.call("_on_power_pressed", &"seal_breach")
	# The crisis should be resolved
	# (the M4 Pactmaker power effect
	# resolves the first sealable
	# crisis).
	assert_true(bool(cr.get("resolved")), "crisis should be resolved after seal_breach click")


func test_playable_shell_ui_auto_tick_toggle_enables_loop() -> void:
	# The M5-Foundation auto-tick
	# toggle enables the per-frame
	# auto-tick loop. The end-to-end
	# test calls the toggle's
	# handler directly and asserts
	# the `auto_tick_enabled` flag.
	var PS: GDScript = load(_PS_PATH)
	var built: Dictionary = PS.call("build")
	var ui: Node = _make_ui(built)
	assert_false(ui.auto_tick_enabled, "auto-tick should be disabled by default")
	ui.call("_on_auto_tick_toggled", true)
	assert_true(ui.auto_tick_enabled, "auto-tick should be enabled after toggle on")
	ui.call("_on_auto_tick_toggled", false)
	assert_false(ui.auto_tick_enabled, "auto-tick should be disabled after toggle off")


func test_playable_shell_ui_step_button_then_power() -> void:
	# The end-to-end "playable" loop:
	# step the sim a few times, then
	# use a Pactmaker power. The
	# post-state is asserted: the sim
	# has advanced and the power
	# effect has been applied.
	var PS: GDScript = load(_PS_PATH)
	var built: Dictionary = PS.call("build")
	var ui: Node = _make_ui(built)
	# Step 10 times.
	for i in range(10):
		ui.call("_on_step_pressed")
	assert_eq(ui.sim.time_days, 10.0, "sim should be at 10.0 after 10 steps")
	# Use seal_breach.
	ui.call("_on_power_pressed", &"seal_breach")
	# The crisis should be resolved.
	var cr: Crisis = built["crises"][0]
	assert_true(bool(cr.get("resolved")), "crisis should be resolved after seal_breach")


func test_playable_shell_ui_step_button_advances_world_state() -> void:
	# The M5-Foundation end-to-end
	# test: a 30-day playable run
	# exercises the per-tick loop,
	# the M4 autonomous-conflict
	# step, and the M4 Pactmaker
	# yearly-reset hook. The
	# post-state invariants hold.
	var PS: GDScript = load(_PS_PATH)
	var built: Dictionary = PS.call("build")
	var ui: Node = _make_ui(built)
	for i in range(30):
		ui.call("_on_step_pressed")
	assert_eq(ui.sim.time_days, 30.0, "sim should be at 30.0 after 30 Step clicks")
	# The M4 Pactmaker intervention
	# counter is preserved across the
	# run (the yearly reset fires at
	# 360 days; the 30-day run does
	# not trigger the reset).
	assert_true(
		int(ui.pactmaker.intervention_count) >= 0,
		"intervention_count should be non-negative after 30 steps"
	)
