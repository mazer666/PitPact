# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M8 Bucket 1 (Touch Input)
# test net.
extends GutTest

const _PSUI_PATH: String = "res://src/ui/playable_shell_ui.gd"
const _PS_PATH: String = "res://src/ui/playable_shell.gd"
const _SHELL_PATH: String = "res://scenes/main/PlayableShell.tscn"


func test_input_map_has_step_action() -> void:
	# The M8 closeout registers
	# the `step` action in
	# InputMap. The test asserts
	# the action exists.
	var PSUI: GDScript = load(_PSUI_PATH)
	var ui: Node = PSUI.new()
	ui._setup_input_map()
	assert_true(InputMap.has_action("step"), "InputMap has 'step' action after _setup_input_map()")


func test_input_map_has_auto_tick_action() -> void:
	# The M8 closeout registers
	# the `auto_tick` action in
	# InputMap.
	var PSUI: GDScript = load(_PSUI_PATH)
	var ui: Node = PSUI.new()
	ui._setup_input_map()
	assert_true(InputMap.has_action("auto_tick"), "InputMap has 'auto_tick' action")


func test_input_map_has_restart_action() -> void:
	# The M8 closeout registers
	# the `restart` action in
	# InputMap.
	var PSUI: GDScript = load(_PSUI_PATH)
	var ui: Node = PSUI.new()
	ui._setup_input_map()
	assert_true(InputMap.has_action("restart"), "InputMap has 'restart' action")


func test_input_map_setup_is_idempotent() -> void:
	# Calling `_setup_input_map()`
	# twice does not duplicate
	# the action's events.
	var PSUI: GDScript = load(_PSUI_PATH)
	var ui: Node = PSUI.new()
	ui._setup_input_map()
	var first_count: int = InputMap.action_get_events("step").size()
	ui._setup_input_map()
	var second_count: int = InputMap.action_get_events("step").size()
	assert_eq(second_count, first_count, "second call is a no-op (idempotent)")


func test_touch_event_triggers_step() -> void:
	# The M8 closeout handles
	# `InputEventScreenTouch` events.
	# A tap in the bottom-center
	# (the step-button zone)
	# triggers `_on_step_pressed()`.
	var PS: GDScript = load(_PS_PATH)
	var built: Dictionary = PS.call("build")
	var ps_scene: PackedScene = load(_SHELL_PATH)
	var shell: Node = ps_scene.instantiate()
	add_child_autofree(shell)
	shell.bind(built)
	# Reset days to 0.
	shell.game_state.days_survived = 0
	# Create a tap event at the
	# bottom-center of the viewport.
	var viewport_size: Vector2 = Vector2(800, 600)
	var tap: InputEventScreenTouch = InputEventScreenTouch.new()
	tap.pressed = true
	tap.position = Vector2(viewport_size.x * 0.5, viewport_size.y * 0.85)
	# Dispatch the event.
	shell._input(tap)
	# The day count should be 1.
	assert_eq(shell.game_state.days_survived, 1, "tap in step zone advances days_survived by 1")


func test_touch_event_outside_step_zone_noop() -> void:
	# A tap outside the step zone
	# is a no-op.
	var PS: GDScript = load(_PS_PATH)
	var built: Dictionary = PS.call("build")
	var ps_scene: PackedScene = load(_SHELL_PATH)
	var shell: Node = ps_scene.instantiate()
	add_child_autofree(shell)
	shell.bind(built)
	shell.game_state.days_survived = 0
	# Tap at top-left (outside step zone).
	var tap: InputEventScreenTouch = InputEventScreenTouch.new()
	tap.pressed = true
	tap.position = Vector2(10, 10)
	shell._input(tap)
	# Day count should be 0.
	assert_eq(shell.game_state.days_survived, 0, "tap outside step zone is a no-op")


func test_touch_release_noop() -> void:
	# A `pressed = false` event
	# (touch release) is a no-op.
	var PS: GDScript = load(_PS_PATH)
	var built: Dictionary = PS.call("build")
	var ps_scene: PackedScene = load(_SHELL_PATH)
	var shell: Node = ps_scene.instantiate()
	add_child_autofree(shell)
	shell.bind(built)
	shell.game_state.days_survived = 0
	var tap: InputEventScreenTouch = InputEventScreenTouch.new()
	tap.pressed = false
	tap.position = Vector2(400, 510)
	shell._input(tap)
	assert_eq(shell.game_state.days_survived, 0, "touch release is a no-op")
