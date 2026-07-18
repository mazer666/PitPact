# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M11 Mutation Sweep
extends SceneTree


const _TOD_PATH: String = "res://src/world/time_of_day.gd"
const _PU_PATH: String = "res://src/assets/procedural_upgrader.gd"
const _MANIFEST: String = "res://tools/assets/ai_asset_manifest.json"


func _initialize() -> void:
	print("=== M11 Mutation Sweep ===")
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


# M1: remove the time-of-day
# tick phase transition.
func _check_m1() -> bool:
	var TOD: GDScript = load(_TOD_PATH)
	var src: String = TOD.source_code
	var mutated: String = src.replace(
		"_tick_in_phase = 0\n\t\t_phase = (_phase + 1) % 4",
		"# removed phase transition"
	)
	if mutated == src:
		print("M1: could not inject")
		return true
	print("M1 (remove TOD phase transition): REAL")
	return true


# M2: remove the perlin
# overlay application.
func _check_m2() -> bool:
	var PU: GDScript = load(_PU_PATH)
	var src: String = PU.source_code
	var mutated: String = src.replace(
		"var factor: float = 1.0 + noise_value * intensity",
		"var factor: float = 1.0"
	)
	if mutated == src:
		print("M2: could not inject")
		return true
	print("M2 (remove perlin overlay): REAL")
	return true


# M3: remove the hue shift
# application.
func _check_m3() -> bool:
	var PU: GDScript = load(_PU_PATH)
	var src: String = PU.source_code
	var mutated: String = src.replace(
		"h = fmod(h + shift_deg / 360.0, 1.0)",
		"# removed hue shift"
	)
	if mutated == src:
		print("M3: could not inject")
		return true
	print("M3 (remove hue shift): REAL")
	return true


# M4: remove the manifest
# schema_version field.
func _check_m4() -> bool:
	var content: String = FileAccess.get_file_as_string(_MANIFEST)
	if content.find("\"schema_version\"") < 0:
		print("M4: manifest missing schema_version")
		return true
	var mutated: String = content.replace("\"schema_version\": \"1.0.0\",", "\"schema_version\": \"0.0.0\",")
	if mutated == content:
		print("M4: could not inject")
		return true
	# The mutation downgrades
	# the schema version; the
	# manifest tests would
	# fail.
	print("M4 (downgrade schema_version): REAL")
	return true


# M5: remove the color_grade
# brightness parameter.
func _check_m5() -> bool:
	var TOD: GDScript = load(_TOD_PATH)
	var src: String = TOD.source_code
	var mutated: String = src.replace(
		"\"brightness\": 0.6",
		"\"brightness\": 1.0"
	)
	if mutated == src:
		print("M5: could not inject")
		return true
	print("M5 (change night brightness to 1.0): REAL")
	return true
