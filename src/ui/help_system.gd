# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M16 Bucket 5: In-Game-Help.
# F1 opens a context-sensitive
# help dialog. Topics are
# grouped by context (gameplay,
# co_op, settings).
class_name HelpSystem
extends RefCounted

const VERSION_STRING: String = "0.12.0-m16-docs-eol"
const _CONTEXT_GAMEPLAY: StringName = &"gameplay"
const _CONTEXT_COOP: StringName = &"co_op"
const _CONTEXT_SETTINGS: StringName = &"settings"

var _topics: Dictionary = {}


static func version() -> String:
	return VERSION_STRING


static func make() -> HelpSystem:
	var hs: HelpSystem = HelpSystem.new()
	hs._install_default_topics()
	return hs


static func context_gameplay() -> StringName:
	return _CONTEXT_GAMEPLAY


static func context_coop() -> StringName:
	return _CONTEXT_COOP


static func context_settings() -> StringName:
	return _CONTEXT_SETTINGS


func _install_default_topics() -> void:
	add_topic(
		HelpTopic.make(
			&"getting_started",
			"Getting Started",
			"Welcome. Recruit, build, survive.",
			PackedStringArray(["inhabitants", "crises"]),
			_CONTEXT_GAMEPLAY
		)
	)
	add_topic(
		HelpTopic.make(
			&"inhabitants",
			"Inhabitants",
			"Inhabitants join from your origin. Each culture has unique traits.",
			PackedStringArray(["getting_started", "crises"]),
			_CONTEXT_GAMEPLAY
		)
	)
	add_topic(
		HelpTopic.make(
			&"crises",
			"Crises",
			"Crises emerge from scarcity. Use powers: Seal Breach, Pause Crisis, Reveal Tile.",
			PackedStringArray(["getting_started", "inhabitants"]),
			_CONTEXT_GAMEPLAY
		)
	)
	add_topic(
		HelpTopic.make(
			&"co_op",
			"Co-op Mode",
			"Join a lobby and play together. M16 is a stub; M17 adds real STUN/TURN.",
			PackedStringArray(["getting_started", "settings"]),
			_CONTEXT_COOP
		)
	)
	add_topic(
		HelpTopic.make(
			&"settings",
			"Settings",
			"Audio, display, language, gameplay, accessibility (color-blind, reduce-motion).",
			PackedStringArray(["co_op", "getting_started"]),
			_CONTEXT_SETTINGS
		)
	)


func add_topic(topic: HelpTopic) -> int:
	if topic == null or String(topic.id).is_empty():
		return -1
	_topics[topic.id] = topic
	return 0


func get_topic(topic_id: StringName) -> HelpTopic:
	return _topics.get(topic_id, null)


func has_topic(topic_id: StringName) -> bool:
	return _topics.has(topic_id)


func topics_for_context(context: StringName) -> Array:
	var result: Array = []
	for key in _topics:
		var t: HelpTopic = _topics[key]
		if t.context == context:
			result.append(t)
	return result


func topic_count() -> int:
	return _topics.size()


func remove_topic(topic_id: StringName) -> int:
	if not _topics.has(topic_id):
		return -1
	_topics.erase(topic_id)
	return 0


func all_topics() -> Array:
	return _topics.values()
