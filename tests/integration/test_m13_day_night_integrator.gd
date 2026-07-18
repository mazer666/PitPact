# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M13 Bucket 3 (DayNight
# Integrator) test net.
extends GutTest

const _DNI_PATH: String = "res://src/world/day_night_integrator.gd"
const _TOD_PATH: String = "res://src/world/time_of_day.gd"


func test_m13_day_night_integrator_version() -> void:
	var DNI: GDScript = load(_DNI_PATH)
	var v: String = DNI.call("version")
	assert_eq(v, "0.9.0-m13-visual-polish", "version() returns the M13 closeout version")


func test_m13_day_night_integrator_make() -> void:
	var DNI: GDScript = load(_DNI_PATH)
	var TOD: GDScript = load(_TOD_PATH)
	var tod: Variant = TOD.call("make", TOD.PHASE_DAWN)
	var scene_root: Node = Node.new()
	var dni: Variant = DNI.call("make", tod, scene_root)
	assert_eq(dni.phase(), 0, "phase=0 (dawn) initially")


func test_m13_day_night_integrator_tick_advances_phase() -> void:
	var DNI: GDScript = load(_DNI_PATH)
	var TOD: GDScript = load(_TOD_PATH)
	var tod: Variant = TOD.call("make", TOD.PHASE_DAWN)
	tod.set_ticks_per_phase(1)
	var scene_root: Node = Node.new()
	var dni: Variant = DNI.call("make", tod, scene_root)
	# Tick with 0.5s (full
	# interval) — phase should
	# advance.
	dni.tick(0.5)
	assert_eq(dni.phase(), 1, "phase=1 (noon) after 1 tick")


func test_m13_day_night_integrator_tick_partial_no_advance() -> void:
	# A partial tick (<
	# _TICK_INTERVAL) should
	# not advance the phase.
	var DNI: GDScript = load(_DNI_PATH)
	var TOD: GDScript = load(_TOD_PATH)
	var tod: Variant = TOD.call("make", TOD.PHASE_DAWN)
	tod.set_ticks_per_phase(1)
	var scene_root: Node = Node.new()
	var dni: Variant = DNI.call("make", tod, scene_root)
	# 0.2s < 0.5s interval
	# — phase should NOT advance.
	dni.tick(0.2)
	assert_eq(dni.phase(), 0, "phase=0 after partial tick")


func test_m13_day_night_integrator_brightness_matches_phase() -> void:
	# `brightness()` returns
	# the phase's brightness.
	var DNI: GDScript = load(_DNI_PATH)
	var TOD: GDScript = load(_TOD_PATH)
	var tod: Variant = TOD.call("make", TOD.PHASE_NIGHT)
	var scene_root: Node = Node.new()
	var dni: Variant = DNI.call("make", tod, scene_root)
	dni.apply_color_grade()
	assert_eq(dni.brightness(), 0.6, "night brightness=0.6")


func test_m13_day_night_integrator_phase_name() -> void:
	var DNI: GDScript = load(_DNI_PATH)
	var TOD: GDScript = load(_TOD_PATH)
	var tod: Variant = TOD.call("make", TOD.PHASE_DUSK)
	var scene_root: Node = Node.new()
	var dni: Variant = DNI.call("make", tod, scene_root)
	assert_eq(dni.phase_name(), "dusk", "phase_name='dusk'")


func test_m13_day_night_integrator_last_params_updated() -> void:
	# After `apply_color_grade()`,
	# the last_* values are
	# updated.
	var DNI: GDScript = load(_DNI_PATH)
	var TOD: GDScript = load(_TOD_PATH)
	var tod: Variant = TOD.call("make", TOD.PHASE_DAWN)
	var scene_root: Node = Node.new()
	var dni: Variant = DNI.call("make", tod, scene_root)
	dni.apply_color_grade()
	assert_eq(dni.last_warm(), 0.3, "dawn warm_shift=0.3")
	assert_eq(dni.last_brightness(), 1.1, "dawn brightness=1.1")


func test_m13_day_night_integrator_tick_interval() -> void:
	# The tick interval is
	# 0.5s (= 30 frames @ 60 FPS).
	var DNI: GDScript = load(_DNI_PATH)
	var interval: float = DNI.call("tick_interval")
	assert_eq(interval, 0.5, "tick interval is 0.5s")
