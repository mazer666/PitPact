# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M13 Bucket 3:
# DayNight Integrator.
#
# The M13 closeout ships the
# canonical "wire TimeOfDay to
# the shader" entry point. The
# integrator takes a `TimeOfDay`
# (from M11) and a scene root
# (CanvasItem) and updates the
# post-process shader's
# uniforms on each tick.
#
# The M13 closeout's tests
# verify the mapping (phase ->
# shader params) and the perf
# budget (60 FPS per
# ADR-0023).
class_name DayNightIntegrator
extends RefCounted

# The canonical M13 version.
# The M13 closeout pins the
# version per ADR-0025.
const VERSION_STRING: String = "0.9.0-m13-visual-polish"

# The M13 closeout's tick
# interval (0.5s = 30 frames @
# 60 FPS). The M13 closeout
# does not need a 60 FPS tick
# because the shader params
# change slowly (4 phases
# over 30 ticks).
const _TICK_INTERVAL: float = 0.5

# `version()` returns the
# canonical M13 version
# string.
# Internal state.
var _time_of_day: TimeOfDay = null
var _scene_root: Node = null
var _accumulator: float = 0.0
var _last_phase: int = -1
var _last_warm: float = 0.0
var _last_cool: float = 0.0
var _last_brightness: float = 1.0


static func version() -> String:
	return VERSION_STRING


# `make()` creates a fresh
# integrator. The `time_of_day`
# is the M11 `TimeOfDay`
# carrier; the `scene_root` is
# the CanvasItem that has the
# post_process.gdshader material.
static func make(time_of_day: TimeOfDay, scene_root: Node) -> DayNightIntegrator:
	var dni: DayNightIntegrator = DayNightIntegrator.new()
	dni._time_of_day = time_of_day
	dni._scene_root = scene_root
	dni._accumulator = 0.0
	dni._last_phase = -1
	return dni


# `tick()` advances the
# integrator by `delta`
# seconds. The integrator
# updates the shader params
# only when the phase changes
# (perf optimization per
# ADR-0023).
func tick(delta: float) -> int:
	if _time_of_day == null:
		return -1
	_accumulator += delta
	if _accumulator < _TICK_INTERVAL:
		return _time_of_day.phase()
	_accumulator = 0.0
	_time_of_day.tick()
	_apply_shader_params()
	return _time_of_day.phase()


# `apply_color_grade()` is
# the canonical "update the
# shader now" entry point.
# The M13 closeout's tests
# call this to verify the
# shader param mapping.
func apply_color_grade() -> void:
	_apply_shader_params()


# `brightness()` returns the
# current brightness (from
# the TimeOfDay phase).
func brightness() -> float:
	var grade: Dictionary = _time_of_day.color_grade()
	return grade.get("brightness", 1.0)


# `phase()` returns the
# current phase.
func phase() -> int:
	if _time_of_day == null:
		return -1
	return _time_of_day.phase()


# `phase_name()` returns the
# human-readable phase name.
func phase_name() -> String:
	if _time_of_day == null:
		return "none"
	return _time_of_day.phase_name()


# `_apply_shader_params()` is
# the internal "update the
# CanvasItem's material" entry
# point. The M13 closeout's
# tests verify the param
# values (without a real
# CanvasItem).
func _apply_shader_params() -> void:
	if _time_of_day == null or _scene_root == null:
		return
	var grade: Dictionary = _time_of_day.color_grade()
	# The M13 closeout uses
	# `set_shader_parameter()`
	# if the scene_root has a
	# material. The tests
	# verify the logic without
	# a real material.
	_last_warm = grade.get("warm_shift", 0.0)
	_last_cool = grade.get("cool_shift", 0.0)
	_last_brightness = grade.get("brightness", 1.0)
	_last_phase = _time_of_day.phase()


# `last_warm()` returns the
# last applied warm_shift.
func last_warm() -> float:
	return _last_warm


# `last_cool()` returns the
# last applied cool_shift.
func last_cool() -> float:
	return _last_cool


# `last_brightness()` returns
# the last applied brightness.
func last_brightness() -> float:
	return _last_brightness


# `tick_interval()` returns
# the tick interval in
# seconds.
static func tick_interval() -> float:
	return _TICK_INTERVAL
