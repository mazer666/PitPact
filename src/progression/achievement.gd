# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M14 Bucket 1:
# Achievement.
#
# The M14 closeout ships the
# canonical "did the player
# achieve X?" entry point.
# The achievement is unlocked
# when its `condition`
# callable returns true on
# the current state.
#
# The M14 closeout's tests
# verify the unlock logic
# and the condition
# evaluation.
class_name Achievement
extends RefCounted

# The canonical M14 version.
# The M14 closeout pins the
# version per ADR-0026.
const VERSION_STRING: String = "0.10.0-m14-engine-perf-content"

# `version()` returns the
# canonical M14 version
# string.
# Internal state.
var _id: StringName = &""
var _title: String = ""
var _description: String = ""
var _condition: Callable = Callable()
var _unlocked: bool = false


static func version() -> String:
	return VERSION_STRING


# `make()` creates a fresh
# achievement. The `id`
# is unique; the `title`
# is human-readable; the
# `description` is a longer
# explanation; the `condition`
# is a `Callable` that takes
# a state Dictionary and
# returns a bool.
static func make(
	id: StringName, title: String, description: String, condition: Callable
) -> Achievement:
	var a: Achievement = Achievement.new()
	a._id = id
	a._title = title
	a._description = description
	a._condition = condition
	a._unlocked = false
	return a


# `id()` returns the
# achievement ID.
func id() -> StringName:
	return _id


# `title()` returns the
# achievement title.
func title() -> String:
	return _title


# `description()` returns
# the achievement description.
func description() -> String:
	return _description


# `is_unlocked()` returns
# whether the achievement is
# unlocked.
func is_unlocked() -> bool:
	return _unlocked


# `check()` evaluates the
# condition on the given
# state. Returns true if the
# condition is met. Does NOT
# unlock — use `unlock()` for
# that.
func check(state: Dictionary) -> bool:
	if _condition.is_valid():
		return _condition.call(state)
	return false


# `unlock()` marks the
# achievement as unlocked.
# Returns the previous state
# (true if it was already
# unlocked, false if newly
# unlocked).
func unlock() -> bool:
	var was_unlocked: bool = _unlocked
	_unlocked = true
	return was_unlocked


# `lock()` marks the
# achievement as locked
# (used for tests).
func lock() -> void:
	_unlocked = false
