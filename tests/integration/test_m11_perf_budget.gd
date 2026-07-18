# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M11 Side-Quest H
# (Performance Budget) test
# net.
extends GutTest

const _PERF_PATH: String = "res://tools/benchmarks/run_perf_v2.gd"


func test_m11_perf_benchmark_script_exists() -> void:
	assert_true(FileAccess.file_exists(_PERF_PATH), "run_perf_v2.gd exists")


func test_m11_perf_benchmark_has_budget_constants() -> void:
	# The M11 closeout's perf
	# benchmark defines budget
	# constants.
	var content: String = FileAccess.get_file_as_string(_PERF_PATH)
	assert_true(content.find("_BUDGET_AVG_MS") >= 0, "benchmark has _BUDGET_AVG_MS")
	assert_true(content.find("_BUDGET_1PCT_MS") >= 0, "benchmark has _BUDGET_1PCT_MS")
	assert_true(content.find("_BUDGET_01PCT_MS") >= 0, "benchmark has _BUDGET_01PCT_MS")


func test_m11_perf_benchmark_budget_is_60_fps() -> void:
	# The M11 closeout's budget
	# is 60 FPS (16.67ms/frame).
	var content: String = FileAccess.get_file_as_string(_PERF_PATH)
	assert_true(content.find("16.67") >= 0, "budget is 16.67ms (60 FPS)")
