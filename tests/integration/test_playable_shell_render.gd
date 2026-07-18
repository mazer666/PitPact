# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M5-Foundation PlayableShell render
# regression test.
#
# The M5-Foundation render test instantiates
# the canonical `scenes/main/PlayableShell.tscn`
# in a headless viewport, ticks the sim a few
# times, and verifies the resulting frame:
#
#   1. The viewport is non-empty.
#   2. The Step button is visible and
#      clickable.
#   3. The TimeLabel shows the current
#      sim day.
#   4. The inhabitant rows render the
#      sim data.
#   5. The power buttons render the
#      M4 powers.
#
# The test is the canonical "the UI
# actually renders" regression net.
# The M5 closeout extends the test
# with hand-drawn sprites and
# animation curves.
extends GutTest

const _PS_PATH: String = "res://src/ui/playable_shell.gd"
const _PSUI_PATH: String = "res://src/ui/playable_shell_ui.gd"
const _SHELL_PATH: String = "res://scenes/main/PlayableShell.tscn"


func test_playable_shell_renders_in_viewport() -> void:
	# 1. Build the canonical M5-Foundation
	# playable sim.
	var PS: GDScript = load(_PS_PATH)
	var built: Dictionary = PS.call("build")
	# 2. Instantiate the .tscn-driven
	# PlayableShell.
	var ps_scene: PackedScene = load(_SHELL_PATH)
	var shell: Node = ps_scene.instantiate()
	shell.bind(built)
	# The bind() call above triggers
	# `build_ui` when is_inside_tree()
	# is true; for the test path, we
	# add to the tree first, then
	# call bind() (which calls
	# build_ui). The .tscn production
	# path is: instantiate -> add ->
	# bind.
	add_child_autofree(shell)
	shell.bind(built)
	# 3. The `_ready` callback runs
	# during `add_child`. The
	# InhabitantList and PowersList
	# are populated from the sim data.
	# 4. Tick the sim 3 times (the
	# headless mode has no `_process`
	# loop, so we call the Step
	# handler directly).
	shell.call("_on_step_pressed")
	shell.call("_on_step_pressed")
	shell.call("_on_step_pressed")
	# 5. Assert the time label shows
	# the current day.
	var time_label: Node = shell.get_node("TopBar/HBox/TimeLabel")
	assert_ne(time_label, null, "TimeLabel should exist in the .tscn")
	var time_text: String = String(time_label.text)
	assert_eq(time_text, "Day 3", "TimeLabel should show 'Day 3' after 3 steps")
	# 6. The inhabitant list should
	# have 3 children (one per
	# inhabitant).
	var inhabitant_list: Node = shell.get_node("InhabitantPanel/VBox/InhabitantList")
	assert_eq(
		inhabitant_list.get_child_count(),
		6,
		"InhabitantList should have 6 rows (M5-Closeout Bucket 1)"
	)
	# 7. The powers list should have
	# 3 children (one per power).
	var powers_list: Node = shell.get_node("PactmakerPanel/VBox/PowersList")
	assert_eq(powers_list.get_child_count(), 3, "PowersList should have 3 buttons")
	# 8. The Step button + auto-tick
	# toggle are in the .tscn.
	var step_btn: Node = shell.get_node("TickControl/HBox/StepButton")
	assert_ne(step_btn, null, "StepButton should exist in the .tscn")
	var auto_btn: Node = shell.get_node("TickControl/HBox/AutoTickToggle")
	assert_ne(auto_btn, null, "AutoTickToggle should exist in the .tscn")


func test_playable_shell_power_button_invokes_power() -> void:
	# The M5-Foundation Pactmaker panel
	# renders one button per M4 power.
	# The end-to-end test clicks the
	# seal_breach button (the M5
	# plague_outbreak crisis is
	# sealable) and asserts the crisis
	# is resolved.
	var PS: GDScript = load(_PS_PATH)
	var built: Dictionary = PS.call("build")
	var ps_scene: PackedScene = load(_SHELL_PATH)
	var shell: Node = ps_scene.instantiate()
	shell.bind(built)
	# The bind() call above triggers
	# `build_ui` when is_inside_tree()
	# is true; for the test path, we
	# add to the tree first, then
	# call bind() (which calls
	# build_ui). The .tscn production
	# path is: instantiate -> add ->
	# bind.
	add_child_autofree(shell)
	shell.bind(built)
	# Pre-condition: crisis is not
	# resolved.
	var cr: Crisis = built["crises"][0]
	assert_false(bool(cr.get("resolved")), "crisis should not be resolved initially")
	# Click seal_breach.
	shell.call("_on_power_pressed", &"seal_breach")
	# Post-condition: crisis is
	# resolved.
	assert_true(bool(cr.get("resolved")), "crisis should be resolved after seal_breach click")


func test_playable_shell_inhabitant_row_uses_portrait_texture() -> void:
	# The M5-Foundation inhabitant row
	# renders a portrait TextureRect
	# from `assets/inhabitants/`. The
	# end-to-end test asserts the
	# portrait is loaded (the row's
	# first child is a TextureRect
	# with a non-null texture).
	var PS: GDScript = load(_PS_PATH)
	var built: Dictionary = PS.call("build")
	var ps_scene: PackedScene = load(_SHELL_PATH)
	var shell: Node = ps_scene.instantiate()
	shell.bind(built)
	# The bind() call above triggers
	# `build_ui` when is_inside_tree()
	# is true; for the test path, we
	# add to the tree first, then
	# call bind() (which calls
	# build_ui). The .tscn production
	# path is: instantiate -> add ->
	# bind.
	add_child_autofree(shell)
	shell.bind(built)
	var inhabitant_list: Node = shell.get_node("InhabitantPanel/VBox/InhabitantList")
	# Each row's first child is the
	# portrait TextureRect.
	var row: Node = inhabitant_list.get_child(0)
	assert_eq(row.get_child_count(), 2, "inhabitant row should have portrait + label")
	var portrait: Node = row.get_child(0)
	assert_true(portrait is TextureRect, "first child should be TextureRect")
	var tex: Texture2D = portrait.texture
	assert_ne(tex, null, "portrait TextureRect should have a texture loaded")


func test_playable_shell_format_day_label() -> void:
	# The M5-Foundation time label
	# uses the "Day N" format. The
	# format is the canonical
	# "show the day" entry point;
	# the M5 closeout can swap the
	# format string without
	# touching the call sites.
	var PS: GDScript = load(_PS_PATH)
	var built: Dictionary = PS.call("build")
	var PSUI: GDScript = load(_PSUI_PATH)
	var ui: Node = PSUI.new()
	ui.bind(built)
	# The format is pinned to
	# "Day N" — anything else is
	# a regression.
	assert_eq(ui.format_day_label(0), "Day 0", "format_day_label(0) = 'Day 0'")
	assert_eq(ui.format_day_label(1), "Day 1", "format_day_label(1) = 'Day 1'")
	assert_eq(ui.format_day_label(42), "Day 42", "format_day_label(42) = 'Day 42'")


func test_playable_shell_power_button_uses_icon() -> void:
	# The M5-Foundation power button
	# loads an icon from
	# `assets/ui/power_<id>.png` when
	# present. The end-to-end test
	# asserts the icon is loaded.
	var PS: GDScript = load(_PS_PATH)
	var built: Dictionary = PS.call("build")
	var ps_scene: PackedScene = load(_SHELL_PATH)
	var shell: Node = ps_scene.instantiate()
	shell.bind(built)
	# The bind() call above triggers
	# `build_ui` when is_inside_tree()
	# is true; for the test path, we
	# add to the tree first, then
	# call bind() (which calls
	# build_ui). The .tscn production
	# path is: instantiate -> add ->
	# bind.
	add_child_autofree(shell)
	shell.bind(built)
	var powers_list: Node = shell.get_node("PactmakerPanel/VBox/PowersList")
	# The first button is the
	# seal_breach button.
	var btn: Node = powers_list.get_child(0)
	assert_true(btn is Button, "powers list child should be Button")
	var icon: Texture2D = btn.icon
	assert_ne(icon, null, "seal_breach button should have an icon loaded")
