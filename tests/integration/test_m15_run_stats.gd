# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M15 Bucket 4
# (Run Stats) test net.
extends GutTest

const _RS_PATH: String = "res://src/stats/run_stats.gd"


func test_m15_run_stats_version() -> void:
	var RS: GDScript = load(_RS_PATH)
	var v: String = RS.call("version")
	assert_eq(v, "0.11.0-m15-final-polish-coop", "version() returns the M15 closeout version")


func test_m15_run_stats_make() -> void:
	var RS: GDScript = load(_RS_PATH)
	var rs: Variant = RS.call("make")
	assert_eq(rs.total_runs(), 0, "0 runs initially")


func test_m15_run_stats_record_run() -> void:
	var RS: GDScript = load(_RS_PATH)
	var rs: Variant = RS.call("make")
	var n: int = rs.record_run({"days_survived": 45}, "win", 100)
	assert_eq(n, 1, "1 run after record")
	assert_eq(rs.wins(), 1, "1 win")
	assert_eq(rs.losses(), 0, "0 losses")


func test_m15_run_stats_outcome_counts() -> void:
	# Record 3 runs (1 win,
	# 1 loss, 1 abandoned).
	var RS: GDScript = load(_RS_PATH)
	var rs: Variant = RS.call("make")
	rs.record_run({"days_survived": 45}, "win", 100)
	rs.record_run({"days_survived": 10}, "loss", 50)
	rs.record_run({"days_survived": 5}, "abandoned", 25)
	assert_eq(rs.total_runs(), 3, "3 total runs")
	assert_eq(rs.wins(), 1, "1 win")
	assert_eq(rs.losses(), 1, "1 loss")
	assert_eq(rs.abandoned(), 1, "1 abandoned")


func test_m15_run_stats_win_rate() -> void:
	# Win rate = wins / total.
	var RS: GDScript = load(_RS_PATH)
	var rs: Variant = RS.call("make")
	rs.record_run({"days_survived": 45}, "win", 100)
	rs.record_run({"days_survived": 10}, "loss", 50)
	assert_almost_eq(rs.win_rate(), 0.5, 0.001, "win_rate=0.5")


func test_m15_run_stats_avg_days_survived() -> void:
	# Avg = (45 + 10) / 2 = 27.5.
	var RS: GDScript = load(_RS_PATH)
	var rs: Variant = RS.call("make")
	rs.record_run({"days_survived": 45}, "win", 100)
	rs.record_run({"days_survived": 10}, "loss", 50)
	assert_almost_eq(rs.avg_days_survived(), 27.5, 0.001, "avg days=27.5")


func test_m15_run_stats_best_time() -> void:
	# Best time is the minimum
	# tick_count for a winning
	# run.
	var RS: GDScript = load(_RS_PATH)
	var rs: Variant = RS.call("make")
	rs.record_run({"days_survived": 45}, "win", 100)
	rs.record_run({"days_survived": 50}, "win", 80)
	rs.record_run({"days_survived": 10}, "loss", 50)
	assert_eq(rs.best_time(), 80, "best time=80 ticks (50-day win)")


func test_m15_run_stats_best_time_no_wins() -> void:
	# `best_time()` returns 0
	# when there are no wins.
	var RS: GDScript = load(_RS_PATH)
	var rs: Variant = RS.call("make")
	rs.record_run({"days_survived": 10}, "loss", 50)
	assert_eq(rs.best_time(), 0, "best_time=0 when no wins")


func test_m15_run_stats_clear() -> void:
	var RS: GDScript = load(_RS_PATH)
	var rs: Variant = RS.call("make")
	rs.record_run({"days_survived": 45}, "win", 100)
	rs.clear()
	assert_eq(rs.total_runs(), 0, "0 runs after clear")
