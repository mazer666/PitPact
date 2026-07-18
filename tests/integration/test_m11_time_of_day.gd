# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M11 Bucket 3
# (Time of Day + Shader) test
# net.
extends GutTest

const _TOD_PATH: String = "res://src/world/time_of_day.gd"
const _SHADER_PATH: String = "res://shaders/post_process.gdshader"


func test_m11_time_of_day_version() -> void:
	var TOD: GDScript = load(_TOD_PATH)
	var v: String = TOD.call("version")
	assert_eq(v, "0.7.0-m11-art-rework", "version() returns the M11 closeout version")


func test_m11_time_of_day_make() -> void:
	var TOD: GDScript = load(_TOD_PATH)
	var t: Variant = TOD.call("make", TOD.PHASE_DAWN)
	assert_eq(t.phase(), 0, "phase=0 (dawn)")
	assert_eq(t.phase_name(), "dawn", "phase_name='dawn'")


func test_m11_time_of_day_phase_names() -> void:
	# All 4 phases have names.
	var TOD: GDScript = load(_TOD_PATH)
	var names: Array = ["dawn", "noon", "dusk", "night"]
	for i in 4:
		var t: Variant = TOD.call("make", i)
		assert_eq(t.phase_name(), names[i], "phase %d name = %s" % [i, names[i]])


func test_m11_time_of_day_tick_advances() -> void:
	var TOD: GDScript = load(_TOD_PATH)
	var t: Variant = TOD.call("make", TOD.PHASE_DAWN)
	assert_eq(t.phase(), 0, "phase=0 initially")
	t.tick()
	assert_eq(t.phase(), 0, "phase=0 after 1 tick (within phase)")
	t.set_ticks_per_phase(2)
	t.tick()
	t.tick()
	assert_eq(t.phase(), 1, "phase=1 after 2 ticks at 2 ticks/phase")


func test_m11_time_of_day_cycles_through_all_phases() -> void:
	# 4 phases, each 1 tick.
	var TOD: GDScript = load(_TOD_PATH)
	var t: Variant = TOD.call("make", TOD.PHASE_DAWN)
	t.set_ticks_per_phase(1)
	var phases_seen: Array = []
	for i in 8:
		phases_seen.append(t.phase())
		t.tick()
	# With ticks_per_phase=1,
	# phase changes on every
	# tick: 0, 1, 2, 3, 0, 1, 2, 3
	assert_eq(phases_seen, [0, 1, 2, 3, 0, 1, 2, 3], "cycles through 4 phases")


func test_m11_time_of_day_color_grade_dawn() -> void:
	var TOD: GDScript = load(_TOD_PATH)
	var t: Variant = TOD.call("make", TOD.PHASE_DAWN)
	var grade: Dictionary = t.color_grade()
	assert_eq(grade.get("warm_shift", 0), 0.3, "dawn has warm_shift=0.3")


func test_m11_time_of_day_color_grade_night() -> void:
	var TOD: GDScript = load(_TOD_PATH)
	var t: Variant = TOD.call("make", TOD.PHASE_NIGHT)
	var grade: Dictionary = t.color_grade()
	assert_eq(grade.get("brightness", 1), 0.6, "night has brightness=0.6")


func test_m11_shader_exists() -> void:
	assert_true(FileAccess.file_exists(_SHADER_PATH), "post_process.gdshader exists")


func test_m11_shader_has_required_uniforms() -> void:
	# The M11 closeout's shader
	# has the canonical
	# uniforms: bloom_strength,
	# vignette_strength,
	# vignette_radius, warm_shift,
	# cool_shift, brightness.
	var content: String = FileAccess.get_file_as_string(_SHADER_PATH)
	var required: Array = [
		"bloom_strength",
		"vignette_strength",
		"vignette_radius",
		"warm_shift",
		"cool_shift",
		"brightness"
	]
	for u in required:
		assert_true(content.find(u) >= 0, "shader has uniform '%s'" % u)
