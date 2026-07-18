# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M12 UI Grafical Rework
# test net.
extends GutTest

const _PS_PATH: String = "res://scenes/main/PlayableShell.tscn"
const _CB_PATH: String = "res://scenes/ui/CrisisBanner.tscn"
const _GOB_PATH: String = "res://scenes/ui/GameOverBanner.tscn"
const _VB_PATH: String = "res://scenes/ui/VictoryBanner.tscn"
const _TS_PATH: String = "res://scenes/main/TitleScreen.tscn"
const _THEME_V2: String = "res://assets/ui/gothic_fantasy_theme_v2.tres"
const _HT_PATH: String = "res://src/ui/hover_tween.gd"
const _TS_GD: String = "res://src/ui/title_screen.gd"


func test_m12_playable_shell_scene_uses_ai_assets() -> void:
	# The M12 closeout's
	# PlayableShell uses the
	# AI-generated icons.
	var content: String = FileAccess.get_file_as_string(_PS_PATH)
	assert_true(content.find("res://assets/ai/ui/step.png") >= 0, "PlayableShell uses AI step icon")
	assert_true(
		content.find("res://assets/ai/ui/auto_tick.png") >= 0,
		"PlayableShell uses AI auto_tick icon"
	)
	assert_true(
		content.find("res://assets/ai/ui/restart.png") >= 0, "PlayableShell uses AI restart icon"
	)
	assert_true(
		content.find("res://assets/ai/ui/power.png") >= 0, "PlayableShell uses AI power icon"
	)


func test_m12_playable_shell_uses_ai_background() -> void:
	var content: String = FileAccess.get_file_as_string(_PS_PATH)
	assert_true(
		content.find("res://assets/ai/ui/background_landscape.png") >= 0,
		"PlayableShell uses AI background"
	)


func test_m12_crisis_banner_scene_exists() -> void:
	assert_true(FileAccess.file_exists(_CB_PATH), "CrisisBanner.tscn exists")
	var content: String = FileAccess.get_file_as_string(_CB_PATH)
	assert_true(
		content.find("res://assets/ai/ui/crisis_banner.png") >= 0,
		"CrisisBanner uses AI crisis_banner texture"
	)


func test_m12_game_over_banner_scene_exists() -> void:
	assert_true(FileAccess.file_exists(_GOB_PATH), "GameOverBanner.tscn exists")
	var content: String = FileAccess.get_file_as_string(_GOB_PATH)
	assert_true(
		content.find("res://assets/ai/ui/game_over_banner.png") >= 0,
		"GameOverBanner uses AI game_over_banner texture"
	)


func test_m12_victory_banner_scene_exists() -> void:
	assert_true(FileAccess.file_exists(_VB_PATH), "VictoryBanner.tscn exists")
	var content: String = FileAccess.get_file_as_string(_VB_PATH)
	assert_true(
		content.find("res://assets/ai/ui/victory_banner.png") >= 0,
		"VictoryBanner uses AI victory_banner texture"
	)


func test_m12_title_screen_scene_exists() -> void:
	assert_true(FileAccess.file_exists(_TS_PATH), "TitleScreen.tscn exists")
	var content: String = FileAccess.get_file_as_string(_TS_PATH)
	assert_true(
		content.find("res://assets/ai/ui/title_logo.png") >= 0,
		"TitleScreen uses AI title_logo texture"
	)


func test_m12_theme_v2_exists_with_hover_states() -> void:
	assert_true(FileAccess.file_exists(_THEME_V2), "gothic_fantasy_theme_v2.tres exists")
	var content: String = FileAccess.get_file_as_string(_THEME_V2)
	# The theme has 4 button
	# states: normal, hover,
	# pressed, disabled.
	assert_true(content.find("Button/styles/normal") >= 0, "theme has Button/styles/normal")
	assert_true(content.find("Button/styles/hover") >= 0, "theme has Button/styles/hover")
	assert_true(content.find("Button/styles/pressed") >= 0, "theme has Button/styles/pressed")
	assert_true(content.find("Button/styles/disabled") >= 0, "theme has Button/styles/disabled")


func test_m12_hover_tween_version() -> void:
	var HT: GDScript = load(_HT_PATH)
	var v: String = HT.call("version")
	assert_eq(v, "0.8.0-m12-ui-grafical-rework", "version() returns the M12 closeout version")


func test_m12_hover_tween_duration_is_60_fps_friendly() -> void:
	# The tween duration is
	# 0.15s = 9 frames at 60 FPS.
	var HT: GDScript = load(_HT_PATH)
	var d: float = HT.call("tween_duration")
	assert_eq(d, 0.15, "tween duration is 0.15s")
	var frames: int = HT.call("frames_for_tween")
	assert_eq(frames, 9, "tween takes 9 frames at 60 FPS")


func test_m12_hover_tween_hover_brightens() -> void:
	# `apply_hover()` brightens
	# the color.
	var HT: GDScript = load(_HT_PATH)
	var base: Color = Color(0.5, 0.5, 0.5)
	var hovered: Color = HT.call("apply_hover", base)
	assert_gt(hovered.r, base.r, "hover brightens red")
	assert_gt(hovered.g, base.g, "hover brightens green")
	assert_gt(hovered.b, base.b, "hover brightens blue")


func test_m12_hover_tween_pressed_darkens() -> void:
	# `apply_pressed()` darkens
	# the color.
	var HT: GDScript = load(_HT_PATH)
	var base: Color = Color(0.5, 0.5, 0.5)
	var pressed: Color = HT.call("apply_pressed", base)
	assert_lt(pressed.r, base.r, "pressed darkens red")
	assert_lt(pressed.g, base.g, "pressed darkens green")
	assert_lt(pressed.b, base.b, "pressed darkens blue")


func test_m12_hover_tween_disabled_grays_out() -> void:
	# `apply_disabled()` grays
	# out + reduces alpha.
	var HT: GDScript = load(_HT_PATH)
	var base: Color = Color(0.5, 0.5, 0.5, 1.0)
	var disabled: Color = HT.call("apply_disabled", base)
	assert_lt(disabled.a, base.a, "disabled reduces alpha")


func test_m12_title_screen_version() -> void:
	var TS: GDScript = load(_TS_GD)
	var v: String = TS.call("version")
	assert_eq(v, "0.8.0-m12-ui-grafical-rework", "version() returns the M12 closeout version")


func test_m12_title_screen_fade_in_duration() -> void:
	# The title screen fades
	# in over 1.5s.
	var TS: GDScript = load(_TS_GD)
	var d: float = TS.call("fade_in_duration")
	assert_eq(d, 1.5, "fade-in duration is 1.5s")


func test_m12_playable_shell_instantiates() -> void:
	# The M12 closeout's
	# PlayableShell still
	# instantiates correctly.
	var scene: PackedScene = load(_PS_PATH)
	var instance: Node = scene.instantiate()
	add_child_autofree(instance)
	# Verify key nodes exist.
	assert_ne(instance.get_node_or_null("TopBar"), null, "TopBar exists")
	assert_ne(instance.get_node_or_null("InhabitantPanel"), null, "InhabitantPanel exists")
	assert_ne(instance.get_node_or_null("PactmakerPanel"), null, "PactmakerPanel exists")
	assert_ne(instance.get_node_or_null("TickControl"), null, "TickControl exists")
	assert_ne(instance.get_node_or_null("Background"), null, "Background exists (M12 addition)")
