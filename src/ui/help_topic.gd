# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M16 Bucket 5: In-Game-Help.
# A single help topic: id, title,
# body, related topics, context.
class_name HelpTopic
extends RefCounted

const VERSION_STRING: String = "0.12.0-m16-docs-eol"

var id: StringName = &""
var title: String = ""
var body: String = ""
var related: PackedStringArray = PackedStringArray()
var context: StringName = &"general"


static func version() -> String:
	return VERSION_STRING


static func make(
	topic_id: StringName,
	topic_title: String,
	topic_body: String,
	related_topics: PackedStringArray,
	topic_context: StringName
) -> HelpTopic:
	var t: HelpTopic = HelpTopic.new()
	t.id = topic_id
	t.title = topic_title
	t.body = topic_body
	t.related = related_topics
	t.context = topic_context
	return t


func has_related() -> bool:
	return related.size() > 0


func related_count() -> int:
	return related.size()
