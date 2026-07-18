# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M14 Side-Quest K
# (Speed Run) test net.
extends GutTest

const _SR_PATH: String = "res://src/progression/speed_run.gd"


func test_m14_speed_run_version() -> void:
	var SR: GDScript = load(_SR_PATH)
	var v: String = SR.call("version")
	assert_eq(v, "0.10.0-m14-engine-perf-content", "version() returns the M14 closeout version")


func test_m14_speed_run_make() -> void:
	var SR: GDScript = load(_SR_PATH)
	var sr: Variant = SR.call("make", &"45_days")
	assert_eq(sr.target(), &"45_days", "target=45_days")
	assert_false(sr.is_running(), "not running initially")
	assert_eq(sr.elapsed_seconds(), 0, "0 elapsed initially")


func test_m14_speed_run_start() -> void:
	# `start()` marks the
	# timer as running.
	var SR: GDScript = load(_SR_PATH)
	var sr: Variant = SR.call("make", &"45_days")
	sr.start()
	assert_true(sr.is_running(), "running after start()")


func test_m14_speed_run_stop() -> void:
	# `stop()` returns the
	# elapsed time (in seconds).
	var SR: GDScript = load(_SR_PATH)
	var sr: Variant = SR.call("make", &"45_days")
	sr.start()
	var elapsed: int = sr.stop()
	assert_gte(elapsed, 0, "elapsed >= 0")
	assert_false(sr.is_running(), "not running after stop()")


func test_m14_speed_run_stop_when_not_running() -> void:
	# `stop()` when not running
	# returns the stored
	# elapsed (no change).
	var SR: GDScript = load(_SR_PATH)
	var sr: Variant = SR.call("make", &"45_days")
	var elapsed: int = sr.stop()
	assert_eq(elapsed, 0, "elapsed=0 when not started")


func test_m14_speed_run_reset() -> void:
	# `reset()` clears the
	# elapsed time.
	var SR: GDScript = load(_SR_PATH)
	var sr: Variant = SR.call("make", &"45_days")
	sr.start()
	sr.stop()
	sr.reset()
	assert_eq(sr.elapsed_seconds(), 0, "0 elapsed after reset")
	assert_false(sr.is_running(), "not running after reset")
