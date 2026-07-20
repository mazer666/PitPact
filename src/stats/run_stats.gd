# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M15 Bucket 4:
# Run Stats.
#
# The M15 closeout ships a
# run-stats carrier. The
# carrier tracks run results
# (win, loss, abandoned) +
# computes aggregate stats
# (win-rate, avg days, best
# time).
class_name RunStats
extends RefCounted

# The canonical M15 version.
# The M15 closeout pins the
# version per ADR-0027.
const VERSION_STRING: String = "0.11.0-m15-final-polish-coop"

# The M15 closeout's outcome
# constants. Used as keys
# for `outcome` in
# `record_run()`.
const OUTCOME_WIN: String = "win"
const OUTCOME_LOSS: String = "loss"
const OUTCOME_ABANDONED: String = "abandoned"

# `version()` returns the
# canonical M15 version
# string.
# Internal state.
var _runs: Array = []


static func version() -> String:
	return VERSION_STRING


# `make()` creates a fresh
# run-stats carrier.
static func make() -> RunStats:
	var rs: RunStats = RunStats.new()
	rs._runs = []
	return rs


# `record_run()` records a
# run result. The `state`
# is the final state; the
# `outcome` is "win", "loss",
# or "abandoned". The
# `tick_count` is the number
# of ticks (for "best time").
func record_run(state: Dictionary, outcome: String, tick_count: int = 0) -> int:
	_runs.append(
		{
			"outcome": outcome,
			"days_survived": state.get("days_survived", 0),
			"tick_count": tick_count,
			"timestamp": Time.get_unix_time_from_system()
		}
	)
	return _runs.size()


# `total_runs()` returns the
# total number of recorded
# runs.
func total_runs() -> int:
	return _runs.size()


# `wins()` returns the number
# of wins.
func wins() -> int:
	var n: int = 0
	for r in _runs:
		if r.get("outcome", "") == OUTCOME_WIN:
			n += 1
	return n


# `losses()` returns the
# number of losses.
func losses() -> int:
	var n: int = 0
	for r in _runs:
		if r.get("outcome", "") == OUTCOME_LOSS:
			n += 1
	return n


# `abandoned()` returns the
# number of abandoned runs.
func abandoned() -> int:
	var n: int = 0
	for r in _runs:
		if r.get("outcome", "") == OUTCOME_ABANDONED:
			n += 1
	return n


# `win_rate()` returns the
# win rate (0.0-1.0).
func win_rate() -> float:
	if _runs.is_empty():
		return 0.0
	return float(wins()) / float(_runs.size())


# `avg_days_survived()` returns
# the average days survived
# across all runs.
func avg_days_survived() -> float:
	if _runs.is_empty():
		return 0.0
	var total: int = 0
	for r in _runs:
		total += r.get("days_survived", 0)
	return float(total) / float(_runs.size())


# `best_time()` returns the
# best time (in ticks) for a
# winning run. Returns 0 if
# no wins.
func best_time() -> int:
	var best: int = -1
	for r in _runs:
		if r.get("outcome", "") == OUTCOME_WIN:
			var t: int = r.get("tick_count", 0)
			if best < 0 or t < best:
				best = t
	return best if best >= 0 else 0


# `clear()` removes all
# recorded runs.
func clear() -> void:
	_runs.clear()
