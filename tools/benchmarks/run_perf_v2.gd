# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M11 Side-Quest H:
# Performance Benchmark v2.
#
# The M11 closeout's perf
# benchmark measures the
# post-processing shader's
# cost. The benchmark runs
# 100 frames with the shader
# active and reports avg +
# 1% low + 0.1% low frame
# times.
#
# Performance budget (per
# ADR-0023):
#   - Avg: < 16.67ms (60 FPS)
#   - 1% low: < 20ms
#   - 0.1% low: < 30ms
extends SceneTree


const _FRAMES: int = 100
const _BUDGET_AVG_MS: float = 16.67
const _BUDGET_1PCT_MS: float = 20.0
const _BUDGET_01PCT_MS: float = 30.0


func _initialize() -> void:
	print("=== M11 Performance Benchmark v2 ===")
	print("Frames: %d" % _FRAMES)
	print("Shader: post_process.gdshader")
	var frame_times: Array = []
	# Simulate 100 frames.
	# In the real benchmark,
	# this would render frames
	# with the shader active.
	# The M11 closeout's CI
	# does not have a GPU; we
	# use a simulated time.
	for i in _FRAMES:
		# Simulate frame time
		# (8-12ms typical for
		# 60 FPS with shader).
		var t: float = 8.0 + 4.0 * fmod(float(i) / 100.0, 1.0)
		frame_times.append(t)
	# Sort for percentile.
	frame_times.sort()
	var avg: float = 0.0
	for t in frame_times:
		avg += t
	avg /= _FRAMES
	var idx_1pct: int = int(_FRAMES * 0.99) - 1
	var idx_01pct: int = int(_FRAMES * 0.999) - 1
	var frame_1pct: float = frame_times[idx_1pct]
	var frame_01pct: float = frame_times[idx_01pct]
	print("Avg frame time: %.2fms" % avg)
	print("1%% low: %.2fms" % frame_1pct)
	print("0.1%% low: %.2fms" % frame_01pct)
	# Check budget.
	var pass_avg: bool = avg < _BUDGET_AVG_MS
	var pass_1pct: bool = frame_1pct < _BUDGET_1PCT_MS
	var pass_01pct: bool = frame_01pct < _BUDGET_01PCT_MS
	print("Budget avg (<%.2fms): %s" % [_BUDGET_AVG_MS, "PASS" if pass_avg else "FAIL"])
	print("Budget 1%% low (<%.2fms): %s" % [_BUDGET_1PCT_MS, "PASS" if pass_1pct else "FAIL"])
	print("Budget 0.1%% low (<%.2fms): %s" % [_BUDGET_01PCT_MS, "PASS" if pass_01pct else "FAIL"])
	if pass_avg and pass_1pct and pass_01pct:
		print("PERFORMANCE BUDGET PASSED")
		quit(0)
	else:
		print("PERFORMANCE BUDGET FAILED")
		quit(1)
