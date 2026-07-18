# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M6 Bucket 1: Performance
# Benchmark.
#
# This script measures the M6
# performance target: 100 sim-ticks
# in under 5 seconds (headless).
extends SceneTree

const _N_TICKS: int = 100
const _TARGET_SECONDS: float = 5.0


func _initialize() -> void:
	var PS: GDScript = load("res://src/ui/playable_shell.gd")
	var built: Dictionary = PS.call("build")
	var sim: Variant = built["sim"]
	var inhabitants: Array = built["inhabitants"]
	var start: int = Time.get_ticks_msec()
	for i in range(_N_TICKS):
		sim.tick(1.0, inhabitants, [])
	var elapsed_ms: int = Time.get_ticks_msec() - start
	var elapsed_s: float = float(elapsed_ms) / 1000.0
	var per_tick: float = float(elapsed_ms) / float(_N_TICKS)
	print("Benchmark: %d sim-ticks in %.3fs (%.2fms/tick)" % [
		_N_TICKS, elapsed_s, per_tick
	])
	print("Target: <%.1fs" % _TARGET_SECONDS)
	if elapsed_s > _TARGET_SECONDS:
		print("FAIL: benchmark exceeds M6 target")
		quit(1)
	else:
		print("PASS: benchmark within M6 target")
		quit(0)
