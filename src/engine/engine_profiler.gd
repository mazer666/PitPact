# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M14 Bucket 3:
# Engine Profiler.
#
# The M14 closeout ships a
# simple profiler for tracking
# frame times. The profiler
# records frame deltas and
# computes avg + p99 frame
# times.
#
# The M14 closeout's tests
# verify the recording logic
# and the budget check.
class_name FrameProfiler
extends RefCounted

# The canonical M14 version.
# The M14 closeout pins the
# version per ADR-0026.
const VERSION_STRING: String = "0.10.0-m14-engine-perf-content"

# The M14 closeout's rolling
# window size (1000 frames
# = 16.7s @ 60 FPS).
const _WINDOW_SIZE: int = 1000

# `version()` returns the
# canonical M14 version
# string.
# Internal state.
var _frame_times: Array = []
var _rolling: Array = []


static func version() -> String:
	return VERSION_STRING


# `make()` creates a fresh
# profiler.
static func make() -> FrameProfiler:
	var fp: FrameProfiler = FrameProfiler.new()
	fp._frame_times = []
	fp._rolling = []
	return fp


# `record_frame()` records
# a frame's delta time (in
# ms). The M14 closeout uses
# a rolling window to limit
# memory.
func record_frame(delta_ms: float) -> void:
	_frame_times.append(delta_ms)
	if _frame_times.size() > _WINDOW_SIZE:
		_frame_times.pop_front()
	_rolling.append(delta_ms)
	if _rolling.size() > _WINDOW_SIZE:
		_rolling.pop_front()


# `frame_count()` returns the
# total number of recorded
# frames.
func frame_count() -> int:
	return _frame_times.size()


# `avg_frame_ms()` returns
# the average frame time
# (ms).
func avg_frame_ms() -> float:
	if _frame_times.is_empty():
		return 0.0
	var total: float = 0.0
	for t in _frame_times:
		total += t
	return total / _frame_times.size()


# `p99_frame_ms()` returns
# the 99th-percentile frame
# time (ms). The M14 closeout
# uses this for the 1% low
# metric (per ADR-0023).
func p99_frame_ms() -> float:
	if _frame_times.is_empty():
		return 0.0
	var sorted: Array = _frame_times.duplicate()
	sorted.sort()
	var idx: int = int(sorted.size() * 0.99) - 1
	if idx < 0:
		idx = 0
	return sorted[idx]


# `is_within_budget()` returns
# whether the average frame
# time is within the budget.
func is_within_budget(budget_ms: float) -> bool:
	return avg_frame_ms() < budget_ms


# `reset()` clears all
# recorded frames.
func reset() -> void:
	_frame_times.clear()
	_rolling.clear()


# `window_size()` returns
# the rolling window size.
static func window_size() -> int:
	return _WINDOW_SIZE
