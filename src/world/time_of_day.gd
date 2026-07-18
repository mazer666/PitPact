# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M11 Bucket 3:
# Time of Day.
#
# The M11 closeout ships a
# `TimeOfDay` carrier that
# cycles through 4 phases
# (dawn, noon, dusk, night)
# and provides the canonical
# "what time is it?" entry
# point for the post-processing
# shader.
#
# The M11 closeout's tests
# verify the cycle progression
# and the parameter values for
# each phase.
class_name TimeOfDay
extends RefCounted

# The canonical M11 version.
# The M11 closeout pins the
# version per ADR-0023.
const VERSION_STRING: String = "0.7.0-m11-art-rework"

# The M11 closeout's phase
# constants. Each phase has
# a name and a color-grade
# parameter set.
const PHASE_DAWN: int = 0
const PHASE_NOON: int = 1
const PHASE_DUSK: int = 2
const PHASE_NIGHT: int = 3

const _PHASE_NAMES: Array = ["dawn", "noon", "dusk", "night"]

# `version()` returns the
# canonical M11 version
# string.
# Internal state.
var _phase: int = 0
var _tick_in_phase: int = 0
var _ticks_per_phase: int = 30


static func version() -> String:
	return VERSION_STRING


# `make()` creates a fresh
# `TimeOfDay` instance. The
# optional `start_phase`
# parameter sets the initial
# phase (default: noon).
static func make(start_phase: int = PHASE_NOON) -> TimeOfDay:
	var t: TimeOfDay = TimeOfDay.new()
	t._phase = start_phase
	t._tick_in_phase = 0
	t._ticks_per_phase = 30
	return t


# `phase()` returns the
# current phase (0-3).
func phase() -> int:
	return _phase


# `phase_name()` returns the
# human-readable name of the
# current phase.
func phase_name() -> String:
	return _PHASE_NAMES[_phase]


# `tick()` advances the time
# by one tick. The M11
# closeout cycles through
# the 4 phases; each phase
# lasts `_ticks_per_phase`
# ticks.
func tick() -> int:
	# The M11 closeout's tick
	# advances the time. Each
	# phase lasts
	# _ticks_per_phase ticks.
	# With ticks_per_phase=1,
	# phase changes on every
	# tick.
	_tick_in_phase += 1
	if _tick_in_phase >= _ticks_per_phase:
		_tick_in_phase = 0
		_phase = (_phase + 1) % 4
	return _phase


# `color_grade()` returns a
# 3-tuple (warm_shift, cool_shift,
# brightness) for the current
# phase. The M11 closeout's
# shader uses these parameters
# to color-grade the scene.
func color_grade() -> Dictionary:
	if _phase == PHASE_DAWN:
		return {"warm_shift": 0.3, "cool_shift": 0.0, "brightness": 1.1}
	if _phase == PHASE_NOON:
		return {"warm_shift": 0.0, "cool_shift": 0.0, "brightness": 1.0}
	if _phase == PHASE_DUSK:
		return {"warm_shift": 0.4, "cool_shift": 0.1, "brightness": 0.9}
	# PHASE_NIGHT
	return {"warm_shift": 0.0, "cool_shift": 0.4, "brightness": 0.6}


# `ticks_per_phase()` returns
# the number of ticks per
# phase.
func ticks_per_phase() -> int:
	return _ticks_per_phase


# `tick_in_phase()` returns
# the current tick within the
# phase (0 to _ticks_per_phase
# - 1).
func tick_in_phase() -> int:
	return _tick_in_phase


# `set_ticks_per_phase()`
# sets the phase length. Used
# for testing (the M11 closeout
# uses 30 ticks/phase; tests
# can override).
func set_ticks_per_phase(n: int) -> void:
	_ticks_per_phase = n
