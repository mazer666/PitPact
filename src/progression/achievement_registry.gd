# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M14 Bucket 1:
# Achievement Registry.
#
# The M14 closeout ships a
# registry of achievements.
# The registry tracks all
# achievements + their
# unlock state.
#
# The M14 closeout's tests
# verify the registry's
# add / check_all / count
# API.
class_name AchievementRegistry
extends RefCounted

# The canonical M14 version.
# The M14 closeout pins the
# version per ADR-0026.
const VERSION_STRING: String = "0.10.0-m14-engine-perf-content"

# `version()` returns the
# canonical M14 version
# string.
# Internal state.
var _achievements: Array = []


static func version() -> String:
	return VERSION_STRING


# `make()` creates a fresh
# registry.
static func make() -> AchievementRegistry:
	var ar: AchievementRegistry = AchievementRegistry.new()
	ar._achievements = []
	return ar


# `add()` adds an achievement
# to the registry. Returns
# the new total count.
func add(achievement: Achievement) -> int:
	_achievements.append(achievement)
	return _achievements.size()


# `check_all()` evaluates all
# achievements on the given
# state. Returns a list of
# newly-unlocked achievement
# IDs.
func check_all(state: Dictionary) -> Array:
	var newly_unlocked: Array = []
	for a in _achievements:
		if not a.is_unlocked() and a.check(state):
			a.unlock()
			newly_unlocked.append(a.id())
	return newly_unlocked


# `unlocked_count()` returns
# the number of unlocked
# achievements.
func unlocked_count() -> int:
	var n: int = 0
	for a in _achievements:
		if a.is_unlocked():
			n += 1
	return n


# `total_count()` returns
# the total number of
# achievements.
func total_count() -> int:
	return _achievements.size()


# `get()` returns the
# achievement with the given
# ID. Returns null if not
# found.
func get_achievement(id: StringName) -> Achievement:
	for a in _achievements:
		if a.id() == id:
			return a
	return null


# `is_unlocked()` returns
# whether the achievement
# with the given ID is
# unlocked.
func is_unlocked(id: StringName) -> bool:
	var a: Achievement = get_achievement(id)
	if a == null:
		return false
	return a.is_unlocked()
