# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M15 Bucket 3:
# Tutorial Step.
#
# The M15 closeout ships a
# tutorial-step carrier. Each
# step has a title + body +
# trigger-condition. The
# condition is a `Callable`
# that takes a state dict and
# returns true when the
# tutorial should fire.
class_name TutorialStep
extends RefCounted

# The canonical M15 version.
# The M15 closeout pins the
# version per ADR-0027.
const VERSION_STRING: String = "0.11.0-m15-final-polish-coop"

# `version()` returns the
# canonical M15 version
# string.
# Internal state.
var _id: StringName = &""
var _title: String = ""
var _body: String = ""
var _condition: Callable = Callable()
var _completed: bool = false
var _triggered: bool = false


static func version() -> String:
	return VERSION_STRING


# `make()` creates a fresh
# tutorial step.
static func make(
	id: StringName, title: String, body: String, trigger_condition: Callable
) -> TutorialStep:
	var ts: TutorialStep = TutorialStep.new()
	ts._id = id
	ts._title = title
	ts._body = body
	ts._condition = trigger_condition
	ts._completed = false
	ts._triggered = false
	return ts


# `id()` returns the step ID.
func id() -> StringName:
	return _id


# `title()` returns the step
# title.
func title() -> String:
	return _title


# `body()` returns the step
# body.
func body() -> String:
	return _body


# `is_triggered()` returns
# whether the step has been
# triggered.
func is_triggered() -> bool:
	return _triggered


# `is_completed()` returns
# whether the step has been
# completed.
func is_completed() -> bool:
	return _completed


# `check()` evaluates the
# trigger condition on the
# given state. If the
# condition is true AND the
# step has not been triggered
# yet, marks the step as
# triggered and returns true.
# Does NOT mark as completed.
func check(state: Dictionary) -> bool:
	if _triggered:
		return false
	if _condition.is_valid() and _condition.call(state):
		_triggered = true
		return true
	return false


# `mark_completed()` marks
# the step as completed.
func mark_completed() -> void:
	_completed = true


# `reset()` resets the step
# to untriggered + uncompleted.
func reset() -> void:
	_triggered = false
	_completed = false
