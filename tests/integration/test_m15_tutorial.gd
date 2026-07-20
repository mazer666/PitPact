# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M15 Bucket 3
# (Tutorial) test net.
extends GutTest

const _TS_PATH: String = "res://src/tutorial/tutorial_step.gd"
const _TM_PATH: String = "res://src/tutorial/tutorial_manager.gd"


func test_m15_tutorial_step_version() -> void:
	var TS: GDScript = load(_TS_PATH)
	var v: String = TS.call("version")
	assert_eq(v, "0.11.0-m15-final-polish-coop", "version() returns the M15 closeout version")


func test_m15_tutorial_step_make() -> void:
	var TS: GDScript = load(_TS_PATH)
	var condition: Callable = func(_s: Dictionary) -> bool: return true
	var step: Variant = TS.call("make", &"t", "T", "B", condition)
	assert_eq(step.id(), &"t", "id='t'")
	assert_false(step.is_triggered(), "not triggered initially")
	assert_false(step.is_completed(), "not completed initially")


func test_m15_tutorial_step_check_triggers() -> void:
	var TS: GDScript = load(_TS_PATH)
	var condition: Callable = func(state: Dictionary) -> bool: return state.get("x", 0) >= 5
	var step: Variant = TS.call("make", &"t", "T", "B", condition)
	assert_false(step.check({"x": 1}), "no trigger (x=1)")
	assert_true(step.check({"x": 10}), "trigger (x=10)")
	assert_true(step.is_triggered(), "is_triggered=true after check()")
	# Second check does not
	# re-trigger.
	assert_false(step.check({"x": 10}), "no re-trigger")


func test_m15_tutorial_step_mark_completed() -> void:
	var TS: GDScript = load(_TS_PATH)
	var condition: Callable = func(_s: Dictionary) -> bool: return true
	var step: Variant = TS.call("make", &"t", "T", "B", condition)
	step.mark_completed()
	assert_true(step.is_completed(), "completed after mark_completed()")


func test_m15_tutorial_manager_version() -> void:
	var TM: GDScript = load(_TM_PATH)
	var v: String = TM.call("version")
	assert_eq(v, "0.11.0-m15-final-polish-coop", "version() returns the M15 closeout version")


func test_m15_tutorial_manager_make() -> void:
	var TM: GDScript = load(_TM_PATH)
	var tm: Variant = TM.call("make")
	assert_eq(tm.step_count(), 0, "0 steps initially")


func test_m15_tutorial_manager_add_step() -> void:
	var TM: GDScript = load(_TM_PATH)
	var TS: GDScript = load(_TS_PATH)
	var tm: Variant = TM.call("make")
	var n: int = tm.add_step(
		TS.call("make", &"t", "T", "B", func(_s: Dictionary) -> bool: return false)
	)
	assert_eq(n, 1, "1 step after add")


func test_m15_tutorial_manager_check_triggers() -> void:
	# `check_triggers()` returns
	# newly-triggered IDs.
	var TM: GDScript = load(_TM_PATH)
	var TS: GDScript = load(_TS_PATH)
	var tm: Variant = TM.call("make")
	tm.add_step(
		TS.call(
			"make",
			&"t1",
			"T1",
			"B1",
			func(state: Dictionary) -> bool: return state.get("x", 0) >= 5
		)
	)
	tm.add_step(
		TS.call(
			"make",
			&"t2",
			"T2",
			"B2",
			func(state: Dictionary) -> bool: return state.get("x", 0) >= 10
		)
	)
	var newly: Array = tm.check_triggers({"x": 10})
	assert_eq(newly.size(), 2, "2 newly triggered (both)")


func test_m15_tutorial_manager_skip_all() -> void:
	# `skip_all()` marks all
	# steps as completed.
	var TM: GDScript = load(_TM_PATH)
	var TS: GDScript = load(_TS_PATH)
	var tm: Variant = TM.call("make")
	tm.add_step(TS.call("make", &"t1", "T1", "B1", func(_s: Dictionary) -> bool: return false))
	tm.add_step(TS.call("make", &"t2", "T2", "B2", func(_s: Dictionary) -> bool: return false))
	tm.skip_all()
	assert_eq(tm.completed_count(), 2, "2 completed after skip_all()")


func test_m15_tutorial_manager_default_tutorial() -> void:
	# The M15 closeout ships a
	# default 5-step tutorial.
	var TM: GDScript = load(_TM_PATH)
	var tm: Variant = TM.call("make_default_tutorial")
	assert_eq(tm.step_count(), 5, "5 default steps")


func test_m15_tutorial_manager_default_welcome_triggers() -> void:
	# `welcome` triggers when
	# days_survived >= 1.
	var TM: GDScript = load(_TM_PATH)
	var tm: Variant = TM.call("make_default_tutorial")
	var newly: Array = tm.check_triggers({"days_survived": 1})
	assert_true(&"welcome" in newly, "welcome triggered")


func test_m15_tutorial_manager_default_win_triggers() -> void:
	# `win` triggers when
	# days_survived >= 45.
	var TM: GDScript = load(_TM_PATH)
	var tm: Variant = TM.call("make_default_tutorial")
	var newly: Array = tm.check_triggers({"days_survived": 45})
	assert_true(&"win" in newly, "win triggered")


func test_m15_tutorial_manager_mark_completed() -> void:
	# `mark_completed()` marks
	# a single step.
	var TM: GDScript = load(_TM_PATH)
	var TS: GDScript = load(_TS_PATH)
	var tm: Variant = TM.call("make")
	tm.add_step(TS.call("make", &"t1", "T1", "B1", func(_s: Dictionary) -> bool: return false))
	var ok: bool = tm.mark_completed(&"t1")
	assert_true(ok, "mark_completed returns true")
	assert_eq(tm.completed_count(), 1, "1 completed")


func test_m15_tutorial_manager_mark_completed_unknown() -> void:
	# `mark_completed()` for an
	# unknown ID returns false.
	var TM: GDScript = load(_TM_PATH)
	var tm: Variant = TM.call("make")
	var ok: bool = tm.mark_completed(&"unknown")
	assert_false(ok, "mark_completed returns false for unknown")
