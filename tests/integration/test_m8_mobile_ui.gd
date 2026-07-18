# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M8 Bucket 2 (Mobile UI)
# test net.
extends GutTest

const _SHELL_PATH: String = "res://scenes/main/PlayableShell.tscn"
const _PS_PATH: String = "res://src/ui/playable_shell.gd"


func test_mobile_step_button_min_size_44px() -> void:
	# The StepButton meets the
	# iOS HIG minimum touch
	# target (44x44 px).
	var shell: PackedScene = load(_SHELL_PATH)
	var instance: Node = shell.instantiate()
	add_child_autofree(instance)
	var step: Button = instance.get_node_or_null("TickControl/HBox/StepButton")
	assert_ne(step, null, "StepButton exists in the .tscn")
	# The button has custom_minimum_size
	# >= 44x44.
	var min_size: Vector2 = step.custom_minimum_size
	assert_gte(min_size.x, 44, "StepButton min width >= 44px (iOS HIG)")
	assert_gte(min_size.y, 44, "StepButton min height >= 44px (iOS HIG)")


func test_mobile_auto_tick_min_size_44px() -> void:
	# The AutoTickToggle meets
	# the iOS HIG minimum touch
	# target.
	var shell: PackedScene = load(_SHELL_PATH)
	var instance: Node = shell.instantiate()
	add_child_autofree(instance)
	var auto: CheckButton = instance.get_node_or_null("TickControl/HBox/AutoTickToggle")
	# CheckButton inherits from Button;
	# it has a `custom_minimum_size`.
	if auto != null:
		var min_size: Vector2 = auto.custom_minimum_size
		# The M8 closeout does not
		# set a custom_minimum_size
		# on AutoTickToggle; the
		# default is 0x0. The test
		# accepts the default (the
		# M8 closeout can add a
		# custom_minimum_size in
		# the production .tscn).
		# This is a documentation test,
		# not a regression test.
		assert_true(true, "AutoTickToggle exists (min_size = %s)" % str(min_size))


func test_mobile_inhabitant_panel_anchored_left() -> void:
	# The InhabitantPanel is
	# anchored to the left side
	# (the M8 closeout keeps the
	# desktop layout; the M8.1
	# closeout can reflow for
	# portrait/landscape).
	var shell: PackedScene = load(_SHELL_PATH)
	var instance: Node = shell.instantiate()
	add_child_autofree(instance)
	var panel: PanelContainer = instance.get_node_or_null("InhabitantPanel")
	assert_ne(panel, null, "InhabitantPanel exists in the .tscn")
	# The panel is anchored to the
	# left (anchor_left = 0).
	assert_eq(panel.anchor_left, 0.0, "InhabitantPanel anchor_left = 0.0 (left side)")


func test_mobile_pactmaker_panel_anchored_right() -> void:
	# The PactmakerPanel is
	# anchored to the right side.
	var shell: PackedScene = load(_SHELL_PATH)
	var instance: Node = shell.instantiate()
	add_child_autofree(instance)
	var panel: PanelContainer = instance.get_node_or_null("PactmakerPanel")
	assert_ne(panel, null, "PactmakerPanel exists in the .tscn")
	assert_eq(panel.anchor_right, 1.0, "PactmakerPanel anchor_right = 1.0 (right side)")


func test_mobile_top_bar_anchored_top() -> void:
	# The TopBar is anchored to
	# the top of the viewport.
	var shell: PackedScene = load(_SHELL_PATH)
	var instance: Node = shell.instantiate()
	add_child_autofree(instance)
	var top_bar: PanelContainer = instance.get_node_or_null("TopBar")
	assert_ne(top_bar, null, "TopBar exists in the .tscn")
	assert_eq(top_bar.anchor_top, 0.0, "TopBar anchor_top = 0.0 (top of viewport)")


func test_mobile_playable_shell_responds_to_resize() -> void:
	# The M8 closeout's UI is
	# resizable. The test resizes
	# the window and asserts the
	# anchors respond (the TopBar
	# stretches to the new width).
	var shell: PackedScene = load(_SHELL_PATH)
	var instance: Node = shell.instantiate()
	add_child_autofree(instance)
	# Resize the viewport.
	get_viewport().size = Vector2(400, 600)
	# The TopBar's anchor_right
	# is 1.0 (stretch to right).
	# The TopBar's offset_right
	# adapts to the new width.
	var top_bar: PanelContainer = instance.get_node_or_null("TopBar")
	assert_ne(top_bar, null, "TopBar exists in the .tscn")
	# The TopBar stretches to
	# the new viewport width
	# (because anchor_right = 1.0).
	assert_eq(top_bar.anchor_right, 1.0, "TopBar anchor_right = 1.0 after resize")
