# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M15 Bucket 3:
# Tutorial Manager.
#
# The M15 closeout ships a
# tutorial manager that
# tracks multiple tutorial
# steps. The manager checks
# all steps' conditions on
# each tick + returns the
# newly-triggered ones.
class_name TutorialManager
extends RefCounted

# The canonical M15 version.
# The M15 closeout pins the
# version per ADR-0027.
const VERSION_STRING: String = "0.11.0-m15-final-polish-coop"

# `version()` returns the
# canonical M15 version
# string.
# Internal state.
var _steps: Array = []


static func version() -> String:
	return VERSION_STRING


# `make()` creates a fresh
# tutorial manager.
static func make() -> TutorialManager:
	var tm: TutorialManager = TutorialManager.new()
	tm._steps = []
	return tm


# `add_step()` adds a step
# to the manager. Returns
# the new total count.
func add_step(step: TutorialStep) -> int:
	_steps.append(step)
	return _steps.size()


# `check_triggers()` evaluates
# all steps' conditions on
# the given state. Returns
# the list of newly-triggered
# step IDs.
func check_triggers(state: Dictionary) -> Array:
	var newly: Array = []
	for s in _steps:
		if s.check(state):
			newly.append(s.id())
	return newly


# `skip_all()` marks all
# steps as completed (the
# user dismissed the tutorial).
func skip_all() -> void:
	for s in _steps:
		s.mark_completed()


# `completed_count()` returns
# the number of completed
# steps.
func completed_count() -> int:
	var n: int = 0
	for s in _steps:
		if s.is_completed():
			n += 1
	return n


# `triggered_count()` returns
# the number of triggered
# (but not necessarily
# completed) steps.
func triggered_count() -> int:
	var n: int = 0
	for s in _steps:
		if s.is_triggered():
			n += 1
	return n


# `step_count()` returns the
# total number of steps.
func step_count() -> int:
	return _steps.size()


# `get_step()` returns the
# step with the given ID.
# Returns null if not found.
func get_step(id: StringName) -> TutorialStep:
	for s in _steps:
		if s.id() == id:
			return s
	return null


# `mark_completed()` marks
# the step with the given ID
# as completed.
func mark_completed(id: StringName) -> bool:
	var s: TutorialStep = get_step(id)
	if s == null:
		return false
	s.mark_completed()
	return true


# `make_default_tutorial()`
# creates the canonical 5-step
# tutorial.
static func make_default_tutorial() -> TutorialManager:
	var tm: TutorialManager = TutorialManager.make()
	tm.add_step(
		TutorialStep.make(
			&"welcome",
			"Welcome to PitPact",
			"Tick the day to begin.",
			func(state: Dictionary) -> bool: return state.get("days_survived", 0) >= 1
		)
	)
	tm.add_step(
		TutorialStep.make(
			&"recruit",
			"Recruit an Inhabitant",
			"Build a hearth to attract your first inhabitant.",
			func(state: Dictionary) -> bool: return state.get("inhabitant_count", 0) >= 1
		)
	)
	tm.add_step(
		TutorialStep.make(
			&"build_hearth",
			"Build a Hearth",
			"Place a hearth on the world map.",
			func(state: Dictionary) -> bool: return state.get("hearth_count", 0) >= 1
		)
	)
	tm.add_step(
		TutorialStep.make(
			&"survive_crisis",
			"Survive a Crisis",
			"Resolve your first crisis.",
			func(state: Dictionary) -> bool: return state.get("crises_resolved", 0) >= 1
		)
	)
	tm.add_step(
		TutorialStep.make(
			&"win",
			"Win the Game",
			"Survive 45 days to win.",
			func(state: Dictionary) -> bool: return state.get("days_survived", 0) >= 45
		)
	)
	return tm
