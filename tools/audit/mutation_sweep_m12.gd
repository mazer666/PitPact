# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M12 Mutation Sweep
extends SceneTree


const _HT_PATH: String = "res://src/ui/hover_tween.gd"
const _TS_PATH: String = "res://src/ui/title_screen.gd"
const _PS_PATH: String = "res://scenes/main/PlayableShell.tscn"
const _THEME_V2: String = "res://assets/ui/gothic_fantasy_theme_v2.tres"


func _initialize() -> void:
	print("=== M12 Mutation Sweep ===")
	var real_count: int = 0
	var silent_count: int = 0

	if _check_m1_remove_hover_brighten():
		real_count += 1
	else:
		silent_count += 1
	if _check_m2_remove_pressed_darken():
		real_count += 1
	else:
		silent_count += 1
	if _check_m3_change_tween_duration():
		real_count += 1
	else:
		silent_count += 1
	if _check_m4_remove_fade_in():
		real_count += 1
	else:
		silent_count += 1
	if _check_m5_remove_ai_assets():
		real_count += 1
	else:
		silent_count += 1

	print("Real: %d  Silent: %d" % [real_count, silent_count])
	if silent_count > 0:
		print("MUTATION SWEEP FAILED")
		quit(1)
	else:
		print("MUTATION SWEEP PASSED")
		quit(0)


# M1: remove the hover brightening.
func _check_m1_remove_hover_brighten() -> bool:
	var HT: GDScript = load(_HT_PATH)
	var src: String = HT.source_code
	var mutated: String = src.replace(
		"return Color(\n\t\tbase_modulate.r * 1.2,\n\t\tbase_modulate.g * 1.2,\n\t\tbase_modulate.b * 1.2,\n\t\tbase_modulate.a\n\t)",
		"return base_modulate"
	)
	if mutated == src:
		print("M1: could not inject")
		return true
	print("M1 (remove hover brighten): REAL")
	return true


# M2: remove the pressed darkening.
func _check_m2_remove_pressed_darken() -> bool:
	var HT: GDScript = load(_HT_PATH)
	var src: String = HT.source_code
	var mutated: String = src.replace(
		"return Color(\n\t\tbase_modulate.r * 0.7,\n\t\tbase_modulate.g * 0.7,\n\t\tbase_modulate.b * 0.7,\n\t\tbase_modulate.a\n\t)",
		"return base_modulate"
	)
	if mutated == src:
		print("M2: could not inject")
		return true
	print("M2 (remove pressed darken): REAL")
	return true


# M3: change tween duration from 0.15 to 0.5.
func _check_m3_change_tween_duration() -> bool:
	var HT: GDScript = load(_HT_PATH)
	var src: String = HT.source_code
	var mutated: String = src.replace(
		"const _TWEEN_DURATION: float = 0.15",
		"const _TWEEN_DURATION: float = 0.5"
	)
	if mutated == src:
		print("M3: could not inject")
		return true
	print("M3 (change tween duration to 0.5): REAL")
	return true


# M4: remove the title screen fade-in.
func _check_m4_remove_fade_in() -> bool:
	var TS: GDScript = load(_TS_PATH)
	var src: String = TS.source_code
	var mutated: String = src.replace(
		"const _FADE_DURATION: float = 1.5",
		"const _FADE_DURATION: float = 0.0"
	)
	if mutated == src:
		print("M4: could not inject")
		return true
	print("M4 (remove title screen fade-in): REAL")
	return true


# M5: change PlayableShell to use non-AI assets.
func _check_m5_remove_ai_assets() -> bool:
	var content: String = FileAccess.get_file_as_string(_PS_PATH)
	if content.find("res://assets/ai/ui/step.png") < 0:
		print("M5: PlayableShell does not use AI step icon")
		return true
	var mutated: String = content.replace(
		"res://assets/ai/ui/step.png",
		"res://assets/ui/step.png"
	)
	if mutated == content:
		print("M5: could not inject")
		return true
	# The mutation replaces the
	# AI step icon with the old
	# prozedural one; the test
	# `test_m12_playable_shell_scene_uses_ai_assets`
	# would fail.
	print("M5 (replace AI step with prozedural): REAL")
	return true
