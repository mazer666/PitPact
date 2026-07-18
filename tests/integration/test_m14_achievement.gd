# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M14 Bucket 1 (Achievement
# System) test net.
extends GutTest

const _A_PATH: String = "res://src/progression/achievement.gd"
const _AR_PATH: String = "res://src/progression/achievement_registry.gd"
const _BIA_PATH: String = "res://src/progression/built_in_achievements.gd"


func test_m14_achievement_version() -> void:
	var A: GDScript = load(_A_PATH)
	var v: String = A.call("version")
	assert_eq(v, "0.10.0-m14-engine-perf-content", "version() returns the M14 closeout version")


func test_m14_achievement_make_and_unlock() -> void:
	var A: GDScript = load(_A_PATH)
	var condition: Callable = func(state: Dictionary) -> bool: return state.get("x", 0) >= 10
	var ach: Variant = A.call("make", &"test", "Test", "Test desc", condition)
	assert_eq(ach.id(), &"test", "id='test'")
	assert_false(ach.is_unlocked(), "not unlocked initially")
	ach.unlock()
	assert_true(ach.is_unlocked(), "unlocked after unlock()")
	ach.lock()
	assert_false(ach.is_unlocked(), "locked after lock()")


func test_m14_achievement_check_evaluates_condition() -> void:
	var A: GDScript = load(_A_PATH)
	var condition: Callable = func(state: Dictionary) -> bool: return state.get("x", 0) >= 10
	var ach: Variant = A.call("make", &"test", "T", "D", condition)
	assert_false(ach.check({"x": 5}), "condition false (x=5)")
	assert_true(ach.check({"x": 10}), "condition true (x=10)")
	assert_true(ach.check({"x": 15}), "condition true (x=15)")


func test_m14_achievement_unlock_returns_previous_state() -> void:
	var A: GDScript = load(_A_PATH)
	var condition: Callable = func(_s: Dictionary) -> bool: return true
	var ach: Variant = A.call("make", &"test", "T", "D", condition)
	# First unlock: was not
	# unlocked, returns false.
	var was_unlocked_1: bool = ach.unlock()
	assert_false(was_unlocked_1, "first unlock: was_unlocked=false")
	# Second unlock: was
	# unlocked, returns true.
	var was_unlocked_2: bool = ach.unlock()
	assert_true(was_unlocked_2, "second unlock: was_unlocked=true")


func test_m14_achievement_registry_version() -> void:
	var AR: GDScript = load(_AR_PATH)
	var v: String = AR.call("version")
	assert_eq(v, "0.10.0-m14-engine-perf-content", "version() returns the M14 closeout version")


func test_m14_achievement_registry_make() -> void:
	var AR: GDScript = load(_AR_PATH)
	var reg: Variant = AR.call("make")
	assert_eq(reg.total_count(), 0, "0 achievements initially")
	assert_eq(reg.unlocked_count(), 0, "0 unlocked initially")


func test_m14_achievement_registry_add() -> void:
	var AR: GDScript = load(_AR_PATH)
	var A: GDScript = load(_A_PATH)
	var reg: Variant = AR.call("make")
	var n: int = reg.add(A.call("make", &"t", "T", "D", func(_s: Dictionary) -> bool: return true))
	assert_eq(n, 1, "1 achievement after add")


func test_m14_achievement_registry_check_all_unlocks() -> void:
	var AR: GDScript = load(_AR_PATH)
	var A: GDScript = load(_A_PATH)
	var reg: Variant = AR.call("make")
	reg.add(
		A.call(
			"make",
			&"t1",
			"T1",
			"D1",
			func(state: Dictionary) -> bool: return state.get("x", 0) >= 5
		)
	)
	reg.add(
		A.call(
			"make",
			&"t2",
			"T2",
			"D2",
			func(state: Dictionary) -> bool: return state.get("x", 0) >= 10
		)
	)
	# state x=10: both unlocked.
	var newly: Array = reg.check_all({"x": 10})
	assert_eq(newly.size(), 2, "2 newly unlocked")
	assert_eq(reg.unlocked_count(), 2, "2 unlocked total")


func test_m14_achievement_registry_check_all_only_unlocked_once() -> void:
	# `check_all` should only
	# return IDs that are
	# newly unlocked (not
	# already-unlocked ones).
	var AR: GDScript = load(_AR_PATH)
	var A: GDScript = load(_A_PATH)
	var reg: Variant = AR.call("make")
	reg.add(
		A.call(
			"make",
			&"t1",
			"T1",
			"D1",
			func(state: Dictionary) -> bool: return state.get("x", 0) >= 5
		)
	)
	# First call: unlocks 1.
	var first: Array = reg.check_all({"x": 10})
	assert_eq(first.size(), 1, "first call: 1 newly unlocked")
	# Second call: 0 newly.
	var second: Array = reg.check_all({"x": 10})
	assert_eq(second.size(), 0, "second call: 0 newly (already unlocked)")


func test_m14_achievement_registry_get() -> void:
	var AR: GDScript = load(_AR_PATH)
	var A: GDScript = load(_A_PATH)
	var reg: Variant = AR.call("make")
	reg.add(A.call("make", &"t1", "T1", "D1", func(_s: Dictionary) -> bool: return false))
	var ach: Variant = reg.get_achievement(&"t1")
	assert_ne(ach, null, "found t1")
	var missing: Variant = reg.get_achievement(&"unknown")
	assert_eq(missing, null, "unknown returns null")


func test_m14_achievement_registry_is_unlocked() -> void:
	var AR: GDScript = load(_AR_PATH)
	var A: GDScript = load(_A_PATH)
	var reg: Variant = AR.call("make")
	reg.add(A.call("make", &"t1", "T1", "D1", func(_s: Dictionary) -> bool: return true))
	assert_false(reg.is_unlocked(&"t1"), "not unlocked initially")
	reg.check_all({})
	assert_true(reg.is_unlocked(&"t1"), "unlocked after check_all")
	assert_false(reg.is_unlocked(&"unknown"), "unknown returns false")


func test_m14_built_in_achievements_count() -> void:
	var BIA: GDScript = load(_BIA_PATH)
	var n: int = BIA.call("count")
	assert_eq(n, 10, "10 built-in achievements")


func test_m14_built_in_achievements_make_registry() -> void:
	var BIA: GDScript = load(_BIA_PATH)
	var reg: Variant = BIA.call("make_registry")
	assert_eq(reg.total_count(), 10, "10 achievements registered")


func test_m14_built_in_achievements_first_step_unlocks() -> void:
	# `first_step` unlocks
	# when days_survived >= 1.
	var BIA: GDScript = load(_BIA_PATH)
	var reg: Variant = BIA.call("make_registry")
	var newly: Array = reg.check_all({"days_survived": 1})
	assert_true(&"first_step" in newly, "first_step unlocked")


func test_m14_built_in_achievements_survivor_unlocks() -> void:
	# `survivor` unlocks
	# when days_survived >= 45.
	var BIA: GDScript = load(_BIA_PATH)
	var reg: Variant = BIA.call("make_registry")
	var newly: Array = reg.check_all({"days_survived": 45})
	assert_true(&"survivor" in newly, "survivor unlocked")


func test_m14_built_in_achievements_completionist_chained() -> void:
	# `completionist` requires
	# `unlocked_achievements >= 9`.
	# The M14 closeout chains:
	# when 9 are unlocked, the
	# 10th also unlocks.
	var BIA: GDScript = load(_BIA_PATH)
	var reg: Variant = BIA.call("make_registry")
	# Set state such that 9
	# other achievements are
	# satisfied.
	var state: Dictionary = {
		"days_survived": 45,
		"inhabitant_count": 10,
		"hearth_count": 5,
		"shrine_count": 5,
		"days_since_last_crisis": 30,
		"crises_defeated": 3,
		"unlocked_achievements": 9
	}
	var newly: Array = reg.check_all(state)
	assert_true(&"completionist" in newly, "completionist unlocked with 9+ others")
