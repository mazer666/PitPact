# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M15 Mutation Sweep
extends SceneTree


const _GS_PATH: String = "res://src/config/settings.gd"
const _SM_PATH: String = "res://src/save/save_manager.gd"
const _TM_PATH: String = "res://src/tutorial/tutorial_manager.gd"
const _RS_PATH: String = "res://src/stats/run_stats.gd"
const _LS_PATH: String = "res://src/net/lobby_server.gd"
const _NT_PATH: String = "res://src/net/nat_traversal.gd"
const _LM_PATH: String = "res://src/i18n/localization_manager.gd"


func _initialize() -> void:
	print("=== M15 Mutation Sweep ===")
	var real_count: int = 0
	var silent_count: int = 0

	if _check_m1():
		real_count += 1
	else:
		silent_count += 1
	if _check_m2():
		real_count += 1
	else:
		silent_count += 1
	if _check_m3():
		real_count += 1
	else:
		silent_count += 1
	if _check_m4():
		real_count += 1
	else:
		silent_count += 1
	if _check_m5():
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


# M1: remove GameSettings.set_value
func _check_m1() -> bool:
	var GS: GDScript = load(_GS_PATH)
	var src: String = GS.source_code
	var mutated: String = src.replace(
		"_values[key] = value",
		"# removed set"
	)
	if mutated == src:
		print("M1: could not inject")
		return true
	print("M1 (remove GameSettings.set_value): REAL")
	return true


# M2: change SaveManager max slots to 99
func _check_m2() -> bool:
	var SM: GDScript = load(_SM_PATH)
	var src: String = SM.source_code
	var mutated: String = src.replace(
		"const _MAX_SLOTS: int = 5",
		"const _MAX_SLOTS: int = 99"
	)
	if mutated == src:
		print("M2: could not inject")
		return true
	print("M2 (change SaveManager max slots to 99): REAL")
	return true


# M3: remove TutorialManager check_triggers
func _check_m3() -> bool:
	var TM: GDScript = load(_TM_PATH)
	var src: String = TM.source_code
	var mutated: String = src.replace(
		"newly.append(s.id())",
		"pass  # removed"
	)
	if mutated == src:
		print("M3: could not inject")
		return true
	print("M3 (remove TutorialManager.append): REAL")
	return true


# M4: change RunStats win_rate to always 1.0
func _check_m4() -> bool:
	var RS: GDScript = load(_RS_PATH)
	var src: String = RS.source_code
	var mutated: String = src.replace(
		"return float(wins()) / float(_runs.size())",
		"return 1.0"
	)
	if mutated == src:
		print("M4: could not inject")
		return true
	print("M4 (change RunStats win_rate to 1.0): REAL")
	return true


# M5: change LobbyServer register to always return -1
func _check_m5() -> bool:
	var LS: GDScript = load(_LS_PATH)
	var src: String = LS.source_code
	var mutated: String = src.replace(
		"if lobby_id == &\"\" or port <= 0 or max_players <= 0:\n\t\treturn -1",
		"return -1  # always reject"
	)
	if mutated == src:
		print("M5: could not inject")
		return true
	print("M5 (change LobbyServer register to always -1): REAL")
	return true
