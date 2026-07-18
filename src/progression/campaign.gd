# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M14 Bucket 2:
# Campaign.
#
# The M14 closeout ships a
# campaign carrier. The
# campaign is a sequence of
# chapters (1 to N). The
# player advances through
# the chapters; the campaign
# is complete when all
# chapters are complete.
class_name Campaign
extends RefCounted

# The canonical M14 version.
# The M14 closeout pins the
# version per ADR-0026.
const VERSION_STRING: String = "0.10.0-m14-engine-perf-content"

# `version()` returns the
# canonical M14 version
# string.
# Internal state.
var _chapters: Array = []
var _current_index: int = 0


static func version() -> String:
	return VERSION_STRING


# `make()` creates a fresh
# campaign.
static func make() -> Campaign:
	var c: Campaign = Campaign.new()
	c._chapters = []
	c._current_index = 0
	return c


# `add_chapter()` adds a
# chapter to the campaign.
# Returns the new total.
func add_chapter(chapter: Chapter) -> int:
	_chapters.append(chapter)
	return _chapters.size()


# `chapter_count()` returns
# the number of chapters.
func chapter_count() -> int:
	return _chapters.size()


# `current_chapter()` returns
# the current chapter, or
# null if the campaign is
# complete.
func current_chapter() -> Chapter:
	if _current_index >= _chapters.size():
		return null
	return _chapters[_current_index]


# `advance()` advances to the
# next chapter. Returns the
# new current chapter, or
# null if the campaign is
# complete.
func advance() -> Chapter:
	if _current_index < _chapters.size():
		_current_index += 1
	return current_chapter()


# `is_complete()` returns
# whether the campaign is
# complete (all chapters
# done).
func is_complete() -> bool:
	return _current_index >= _chapters.size()


# `current_index()` returns
# the current chapter index
# (0-based).
func current_index() -> int:
	return _current_index


# `make_default_campaign()`
# creates the canonical 5-chapter
# campaign (per ADR-0026).
static func make_default_campaign() -> Campaign:
	var c: Campaign = Campaign.make()
	c.add_chapter(Chapter.make(&"awakening", "Awakening", 10, 2))
	c.add_chapter(Chapter.make(&"settlement", "Settlement", 20, 4))
	c.add_chapter(Chapter.make(&"expansion", "Expansion", 30, 6))
	c.add_chapter(Chapter.make(&"crisis", "Crisis", 40, 8))
	c.add_chapter(Chapter.make(&"mastery", "Mastery", 45, 10))
	return c
