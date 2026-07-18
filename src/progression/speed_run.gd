# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M14 Side-Quest K:
# Speed Run.
#
# The M14 closeout ships a
# speed-run carrier. The
# carrier tracks elapsed
# time (in seconds) for a
# given target.
class_name SpeedRun
extends RefCounted

# The canonical M14 version.
# The M14 closeout pins the
# version per ADR-0026.
const VERSION_STRING: String = "0.10.0-m14-engine-perf-content"

# `version()` returns the
# canonical M14 version
# string.
# Internal state.
var _target: StringName = &""
var _running: bool = false
var _start_time: int = 0
var _elapsed: int = 0


static func version() -> String:
	return VERSION_STRING


# `make()` creates a fresh
# speed-run. The `target`
# is the goal id (e.g.,
# `45_days`, `survivor`).
static func make(target: StringName) -> SpeedRun:
	var sr: SpeedRun = SpeedRun.new()
	sr._target = target
	sr._running = false
	sr._start_time = 0
	sr._elapsed = 0
	return sr


# `target()` returns the
# target id.
func target() -> StringName:
	return _target


# `start()` starts the
# timer. Records the start
# time.
func start() -> void:
	_running = true
	_start_time = Time.get_ticks_msec()


# `stop()` stops the timer
# and returns the elapsed
# time in seconds.
func stop() -> int:
	if not _running:
		return _elapsed
	_running = false
	var now: int = Time.get_ticks_msec()
	_elapsed = int((now - _start_time) / 1000)
	return _elapsed


# `elapsed_seconds()` returns
# the elapsed time in seconds.
func elapsed_seconds() -> int:
	return _elapsed


# `is_running()` returns
# whether the timer is
# running.
func is_running() -> bool:
	return _running


# `reset()` resets the timer
# to 0.
func reset() -> void:
	_elapsed = 0
	_start_time = 0
	_running = false
