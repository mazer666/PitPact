# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M14 Bucket 2:
# Chapter.
#
# The M14 closeout ships a
# chapter carrier for the
# campaign mode. Each chapter
# has a target days + required
# inhabitants. The chapter is
# complete when the state
# meets both.
class_name Chapter
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
var _target_days: int = 0
var _required_inhabitants: int = 0


static func version() -> String:
	return VERSION_STRING


# `make()` creates a fresh
# chapter.
static func make(
	id: StringName, title: String, target_days: int, required_inhabitants: int
) -> Chapter:
	var c: Chapter = Chapter.new()
	c._id = id
	c._title = title
	c._target_days = target_days
	c._required_inhabitants = required_inhabitants
	return c


# `id()` returns the chapter ID.
func id() -> StringName:
	return _id


# `title()` returns the
# chapter title.
func title() -> String:
	return _title


# `target_days()` returns
# the target days for
# completion.
func target_days() -> int:
	return _target_days


# `required_inhabitants()`
# returns the required
# inhabitants for completion.
func required_inhabitants() -> int:
	return _required_inhabitants


# `is_complete()` returns
# whether the chapter's
# goals are met.
func is_complete(state: Dictionary) -> bool:
	return (
		state.get("days_survived", 0) >= _target_days
		and state.get("inhabitant_count", 0) >= _required_inhabitants
	)


# `progress()` returns the
# progress (0.0-1.0) toward
# completion. The M14 closeout
# uses the max of days-progress
# and inhabitants-progress.
func progress(state: Dictionary) -> float:
	var days_progress: float = min(1.0, float(state.get("days_survived", 0)) / float(_target_days))
	var inhab_progress: float = min(
		1.0, float(state.get("inhabitant_count", 0)) / float(_required_inhabitants)
	)
	return max(days_progress, inhab_progress)
