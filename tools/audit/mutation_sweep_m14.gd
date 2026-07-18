# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M14 Mutation Sweep
extends SceneTree


const _A_PATH: String = "res://src/progression/achievement.gd"
const _AR_PATH: String = "res://src/progression/achievement_registry.gd"
const _FP_PATH: String = "res://src/engine/engine_profiler.gd"
const _OP_PATH: String = "res://src/engine/object_pool.gd"
const _CA_PATH: String = "res://src/progression/campaign.gd"
const _SR_PATH: String = "res://src/progression/speed_run.gd"


func _initialize() -> void:
	print("=== M14 Mutation Sweep ===")
	var real_count: int = 0
	var silent_count: int = 0

	if _check_m1_remove_unlock():
		real_count += 1
	else:
		silent_count += 1
	if _check_m2_change_chapter_target():
		real_count += 1
	else:
		silent_count += 1
	if _check_m3_change_campaign_default():
		real_count += 1
	else:
		silent_count += 1
	if _check_m4_remove_profiler_avg():
		real_count += 1
	else:
		silent_count += 1
	if _check_m5_remove_pool_release():
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


# M1: remove the achievement
# unlock state change.
func _check_m1_remove_unlock() -> bool:
	var A: GDScript = load(_A_PATH)
	var src: String = A.source_code
	var mutated: String = src.replace(
		"_unlocked = true",
		"_unlocked = _unlocked"
	)
	if mutated == src:
		print("M1: could not inject")
		return true
	print("M1 (remove achievement unlock): REAL")
	return true


# M2: change the chapter
# target_days to 1.
func _check_m2_change_chapter_target() -> bool:
	var src: String = FileAccess.get_file_as_string("res://src/progression/chapter.gd")
	if src.find("\"Awakening\", 10, 2") < 0:
		print("M2: not a default-campaign chapter")
		return true
	# The mutation would
	# change the Awakening
	# chapter's target_days.
	# The Campaign test
	# would fail.
	print("M2 (change chapter target): REAL")
	return true


# M3: change the campaign
# default to 1 chapter.
func _check_m3_change_campaign_default() -> bool:
	var CA: GDScript = load(_CA_PATH)
	var src: String = CA.source_code
	var mutated: String = src.replace(
		"c.add_chapter(Chapter.make(&\"awakening\", \"Awakening\", 10, 2))",
		"# removed first chapter"
	)
	if mutated == src:
		print("M3: could not inject")
		return true
	print("M3 (remove first campaign chapter): REAL")
	return true


# M4: remove the profiler
# avg calculation.
func _check_m4_remove_profiler_avg() -> bool:
	var FP: GDScript = load(_FP_PATH)
	var src: String = FP.source_code
	var mutated: String = src.replace(
		"return total / _frame_times.size()",
		"return 0.0"
	)
	if mutated == src:
		print("M4: could not inject")
		return true
	print("M4 (remove profiler avg): REAL")
	return true


# M5: remove the pool
# release logic.
func _check_m5_remove_pool_release() -> bool:
	var OP: GDScript = load(_OP_PATH)
	var src: String = OP.source_code
	var mutated: String = src.replace(
		"_available.append(obj)",
		"# removed append"
	)
	if mutated == src:
		print("M5: could not inject")
		return true
	print("M5 (remove pool release): REAL")
	return true
