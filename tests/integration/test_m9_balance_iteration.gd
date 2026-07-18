# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M9 Bucket 4 (Balance
# Iteration) test net.
extends GutTest

const _BC_PATH: String = "res://src/sim/m7_balance.gd"
const _PL_PATH: String = "res://src/sim/balance_patch_log.gd"


func test_m9_balance_patch_log_version() -> void:
	# The M9 closeout's
	# `BalancePatchLog.version()`
	# returns the M9 version
	# string.
	var PL: GDScript = load(_PL_PATH)
	var v: String = PL.call("version")
	assert_eq(v, "0.5.0-m9-coop-foundation", "version() returns the M9 closeout version")


func test_m9_balance_patch_log_record_and_history() -> void:
	# `record()` adds a patch;
	# `history()` returns the
	# list.
	var PL: GDScript = load(_PL_PATH)
	var log: Variant = PL.call("make")
	log.record({"win_days_survived": 5}, 10)
	log.record({"lose_min_inhabitants": 1}, 20)
	assert_eq(log.count(), 2, "2 patches recorded")
	var history: Array = log.history()
	assert_eq(history.size(), 2, "history returns 2 entries")
	assert_eq(history[0]["tick"], 10, "first entry tick=10")
	assert_eq(history[1]["tick"], 20, "second entry tick=20")


func test_m9_balance_patch_log_revert_to() -> void:
	# `revert_to()` returns a
	# rollback patch.
	var PL: GDScript = load(_PL_PATH)
	var log: Variant = PL.call("make")
	log.record({"win_days_survived": 5}, 10)
	log.record({"lose_min_inhabitants": 1}, 20)
	# Revert to tick 20
	# (invert patch at tick 20).
	var rollback: Dictionary = log.revert_to(20)
	assert_eq(rollback.get("lose_min_inhabitants", 0), -1, "rollback inverts tick 20 patch")


func test_m9_balance_patch_log_revert_to_empty() -> void:
	# Reverting to a tick that
	# has no patches returns an
	# empty dict.
	var PL: GDScript = load(_PL_PATH)
	var log: Variant = PL.call("make")
	log.record({"win_days_survived": 5}, 10)
	var rollback: Dictionary = log.revert_to(20)
	assert_eq(rollback.size(), 0, "rollback to tick 20 (after only tick 10) is empty")


func test_m9_balance_patch_log_clear() -> void:
	# `clear()` removes all
	# patches.
	var PL: GDScript = load(_PL_PATH)
	var log: Variant = PL.call("make")
	log.record({"a": 1}, 1)
	log.clear()
	assert_eq(log.count(), 0, "clear() resets count to 0")


func test_m9_balance_config_apply_patch() -> void:
	# `M7BalanceConfig.apply_patch()`
	# applies a numeric patch
	# and returns a new config.
	var BC: GDScript = load(_BC_PATH)
	var original: Variant = BC.m7_balanced()
	var patched: Variant = original.apply_patch({"win_days_survived": 10})
	assert_eq(
		patched.win_days_survived,
		original.win_days_survived + 10,
		"patched win_days_survived is original + 10"
	)


func test_m9_balance_config_apply_patch_immutable() -> void:
	# `apply_patch()` does not
	# modify the original.
	var BC: GDScript = load(_BC_PATH)
	var original: Variant = BC.m7_balanced()
	var original_days: int = original.win_days_survived
	original.apply_patch({"win_days_survived": 100})
	assert_eq(original.win_days_survived, original_days, "original is unchanged after apply_patch")


func test_m9_balance_config_apply_patch_negative() -> void:
	# A negative patch value
	# subtracts.
	var BC: GDScript = load(_BC_PATH)
	var original: Variant = BC.m7_balanced()
	var patched: Variant = original.apply_patch({"win_days_survived": -5})
	assert_eq(patched.win_days_survived, original.win_days_survived - 5, "negative patch subtracts")


func test_m9_balance_config_apply_patch_unknown_key() -> void:
	# An unknown key in the
	# patch is silently ignored.
	var BC: GDScript = load(_BC_PATH)
	var original: Variant = BC.m7_balanced()
	var patched: Variant = original.apply_patch({"unknown_key": 999})
	assert_eq(patched.win_days_survived, original.win_days_survived, "unknown patch key is ignored")
