# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M14 Bucket 1:
# Built-in Achievements.
#
# The M14 closeout ships the
# canonical 10 built-in
# achievements. The list
# includes progress + mastery
# + secrets.
class_name BuiltInAchievements
extends RefCounted

# The canonical M14 version.
# The M14 closeout pins the
# version per ADR-0026.
const VERSION_STRING: String = "0.10.0-m14-engine-perf-content"


# `version()` returns the
# canonical M14 version
# string.
static func version() -> String:
	return VERSION_STRING


# `make_registry()` creates
# a registry pre-populated
# with the 10 built-in
# achievements.
static func make_registry() -> AchievementRegistry:
	var reg: AchievementRegistry = AchievementRegistry.make()
	# `first_step` — first day ticked.
	reg.add(
		Achievement.make(
			&"first_step",
			"First Step",
			"Tick the first day.",
			func(state: Dictionary) -> bool: return state.get("days_survived", 0) >= 1
		)
	)
	# `first_inhabitant` — first inhabitant recruited.
	reg.add(
		Achievement.make(
			&"first_inhabitant",
			"First Inhabitant",
			"Recruit your first inhabitant.",
			func(state: Dictionary) -> bool: return state.get("inhabitant_count", 0) >= 1
		)
	)
	# `first_hearth` — first hearth built.
	reg.add(
		Achievement.make(
			&"first_hearth",
			"First Hearth",
			"Build your first hearth.",
			func(state: Dictionary) -> bool: return state.get("hearth_count", 0) >= 1
		)
	)
	# `mid_game` — 20 days survived.
	reg.add(
		Achievement.make(
			&"mid_game",
			"Mid-Game",
			"Survive 20 days.",
			func(state: Dictionary) -> bool: return state.get("days_survived", 0) >= 20
		)
	)
	# `full_house` — 10 inhabitants.
	reg.add(
		Achievement.make(
			&"full_house",
			"Full House",
			"Have 10 inhabitants.",
			func(state: Dictionary) -> bool: return state.get("inhabitant_count", 0) >= 10
		)
	)
	# `survivor` — 45 days (M7 win).
	reg.add(
		Achievement.make(
			&"survivor",
			"Survivor",
			"Survive 45 days (M7 win).",
			func(state: Dictionary) -> bool: return state.get("days_survived", 0) >= 45
		)
	)
	# `pacifist` — no crisis for 30 days.
	reg.add(
		Achievement.make(
			&"pacifist",
			"Pacifist",
			"No crisis for 30 days.",
			func(state: Dictionary) -> bool: return state.get("days_since_last_crisis", 0) >= 30
		)
	)
	# `warlord` — defeat 3 crises.
	reg.add(
		Achievement.make(
			&"warlord",
			"Warlord",
			"Defeat 3 crises.",
			func(state: Dictionary) -> bool: return state.get("crises_defeated", 0) >= 3
		)
	)
	# `builder` — build 5 hearths + 5 shrines.
	reg.add(
		Achievement.make(
			&"builder",
			"Builder",
			"Build 5 hearths and 5 shrines.",
			func(state: Dictionary) -> bool:
				return state.get("hearth_count", 0) >= 5 and state.get("shrine_count", 0) >= 5
		)
	)
	# `completionist` — unlock 9/10.
	reg.add(
		Achievement.make(
			&"completionist",
			"Completionist",
			"Unlock 9 of 10 achievements.",
			func(state: Dictionary) -> bool: return state.get("unlocked_achievements", 0) >= 9
		)
	)
	return reg


# `count()` returns the number
# of built-in achievements.
static func count() -> int:
	return 10
