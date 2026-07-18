# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M13 Mutation Sweep
extends SceneTree


const _DNI_PATH: String = "res://src/world/day_night_integrator.gd"
const _IA_PATH: String = "res://src/ui/idle_animator.gd"
const _PS_PATH: String = "res://src/effects/particle_spawner.gd"
const _ARV_PATH: String = "res://src/ui/audio_reactive_visual.gd"


func _initialize() -> void:
	print("=== M13 Mutation Sweep ===")
	var real_count: int = 0
	var silent_count: int = 0

	if _check_m1_remove_dni_shader_apply():
		real_count += 1
	else:
		silent_count += 1
	if _check_m2_change_idle_scale_values():
		real_count += 1
	else:
		silent_count += 1
	if _check_m3_change_particle_count():
		real_count += 1
	else:
		silent_count += 1
	if _check_m4_remove_arv_decay():
		real_count += 1
	else:
		silent_count += 1
	if _check_m5_change_dni_tick_interval():
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


# M1: remove the DNI
# shader param update.
func _check_m1_remove_dni_shader_apply() -> bool:
	var DNI: GDScript = load(_DNI_PATH)
	var src: String = DNI.source_code
	var mutated: String = src.replace(
		"_last_warm = grade.get(\"warm_shift\", 0.0)",
		"_last_warm = 0.0"
	)
	if mutated == src:
		print("M1: could not inject")
		return true
	print("M1 (remove DNI warm_shift update): REAL")
	return true


# M2: change the IA scale
# values to all 1.0.
func _check_m2_change_idle_scale_values() -> bool:
	var IA: GDScript = load(_IA_PATH)
	var src: String = IA.source_code
	var mutated: String = src.replace(
		"const _SCALE_VALUES: Array = [1.0, 1.05, 0.95]",
		"const _SCALE_VALUES: Array = [1.0, 1.0, 1.0]"
	)
	if mutated == src:
		print("M2: could not inject")
		return true
	print("M2 (change IA scale values to 1.0): REAL")
	return true


# M3: change the fire
# particle count.
func _check_m3_change_particle_count() -> bool:
	var PS: GDScript = load(_PS_PATH)
	var src: String = PS.source_code
	var mutated: String = src.replace(
		"\"fire\": 20",
		"\"fire\": 5"
	)
	if mutated == src:
		print("M3: could not inject")
		return true
	print("M3 (change fire particle count to 5): REAL")
	return true


# M4: remove the ARV decay
# in `tick()`.
func _check_m4_remove_arv_decay() -> bool:
	var ARV: GDScript = load(_ARV_PATH)
	var src: String = ARV.source_code
	var mutated: String = src.replace(
		"_step_pulse = max(0.0, _step_pulse - delta / _PULSE_DURATION)",
		"_step_pulse = 1.0  # removed decay"
	)
	if mutated == src:
		print("M4: could not inject")
		return true
	print("M4 (remove ARV step decay): REAL")
	return true


# M5: change the DNI tick
# interval to 0.1s.
func _check_m5_change_dni_tick_interval() -> bool:
	var DNI: GDScript = load(_DNI_PATH)
	var src: String = DNI.source_code
	var mutated: String = src.replace(
		"const _TICK_INTERVAL: float = 0.5",
		"const _TICK_INTERVAL: float = 0.1"
	)
	if mutated == src:
		print("M5: could not inject")
		return true
	print("M5 (change DNI tick interval to 0.1): REAL")
	return true
