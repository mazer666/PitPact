# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M14 Bucket 1:
# Built-in Achievements.
class_name BuiltInAchievements
extends RefCounted

const VERSION_STRING: String = "0.10.0-m14-engine-perf-content"


static func version() -> String:
	return VERSION_STRING


static func _cond_first_step(state: Dictionary) -> bool:
	return state.get("days_survived", 0) >= 1


static func _cond_first_inhabitant(state: Dictionary) -> bool:
	return state.get("inhabitant_count", 0) >= 1


static func _cond_first_hearth(state: Dictionary) -> bool:
	return state.get("hearth_count", 0) >= 1


static func _cond_mid_game(state: Dictionary) -> bool:
	return state.get("days_survived", 0) >= 20


static func _cond_full_house(state: Dictionary) -> bool:
	return state.get("inhabitant_count", 0) >= 10


static func _cond_survivor(state: Dictionary) -> bool:
	return state.get("days_survived", 0) >= 45


static func _cond_pacifist(state: Dictionary) -> bool:
	return state.get("days_since_last_crisis", 0) >= 30


static func _cond_warlord(state: Dictionary) -> bool:
	return state.get("crises_defeated", 0) >= 3


static func _cond_builder(state: Dictionary) -> bool:
	return state.get("hearth_count", 0) >= 5 and state.get("shrine_count", 0) >= 5


static func _cond_completionist(state: Dictionary) -> bool:
	return state.get("unlocked_achievements", 0) >= 9


static func make_registry() -> AchievementRegistry:
	var reg: AchievementRegistry = AchievementRegistry.make()
	reg.add(Achievement.make(&"first_step", "First Step", "Tick the first day.", _cond_first_step))
	reg.add(
		Achievement.make(
			&"first_inhabitant",
			"First Inhabitant",
			"Recruit your first inhabitant.",
			_cond_first_inhabitant
		)
	)
	reg.add(
		Achievement.make(
			&"first_hearth", "First Hearth", "Build your first hearth.", _cond_first_hearth
		)
	)
	reg.add(Achievement.make(&"mid_game", "Mid-Game", "Survive 20 days.", _cond_mid_game))
	reg.add(Achievement.make(&"full_house", "Full House", "Have 10 inhabitants.", _cond_full_house))
	reg.add(Achievement.make(&"survivor", "Survivor", "Survive 45 days (M7 win).", _cond_survivor))
	reg.add(Achievement.make(&"pacifist", "Pacifist", "No crisis for 30 days.", _cond_pacifist))
	reg.add(Achievement.make(&"warlord", "Warlord", "Defeat 3 crises.", _cond_warlord))
	reg.add(
		Achievement.make(&"builder", "Builder", "Build 5 hearths and 5 shrines.", _cond_builder)
	)
	reg.add(
		Achievement.make(
			&"completionist", "Completionist", "Unlock 9 of 10 achievements.", _cond_completionist
		)
	)
	return reg


static func count() -> int:
	return 10
