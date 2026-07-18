# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M14 Bucket 2
# (Campaign) test net.
extends GutTest

const _CH_PATH: String = "res://src/progression/chapter.gd"
const _CA_PATH: String = "res://src/progression/campaign.gd"


func test_m14_chapter_version() -> void:
	var CH: GDScript = load(_CH_PATH)
	var v: String = CH.call("version")
	assert_eq(v, "0.10.0-m14-engine-perf-content", "version() returns the M14 closeout version")


func test_m14_chapter_make() -> void:
	var CH: GDScript = load(_CH_PATH)
	var ch: Variant = CH.call("make", &"test", "Test", 10, 2)
	assert_eq(ch.id(), &"test", "id='test'")
	assert_eq(ch.title(), "Test", "title='Test'")
	assert_eq(ch.target_days(), 10, "target_days=10")
	assert_eq(ch.required_inhabitants(), 2, "required_inhabitants=2")


func test_m14_chapter_is_complete() -> void:
	var CH: GDScript = load(_CH_PATH)
	var ch: Variant = CH.call("make", &"test", "T", 10, 2)
	assert_false(
		ch.is_complete({"days_survived": 5, "inhabitant_count": 1}),
		"not complete (5 days, 1 inhab)"
	)
	assert_true(
		ch.is_complete({"days_survived": 10, "inhabitant_count": 2}), "complete (10 days, 2 inhab)"
	)
	assert_true(
		ch.is_complete({"days_survived": 15, "inhabitant_count": 5}), "complete (15 days, 5 inhab)"
	)


func test_m14_chapter_progress() -> void:
	var CH: GDScript = load(_CH_PATH)
	var ch: Variant = CH.call("make", &"test", "T", 10, 2)
	# 5 days / 10 = 0.5
	# 1 inhab / 2 = 0.5
	# max = 0.5
	assert_eq(ch.progress({"days_survived": 5, "inhabitant_count": 1}), 0.5, "progress 0.5")
	# 10 days / 10 = 1.0
	# 0 inhab / 2 = 0.0
	# max = 1.0
	assert_eq(
		ch.progress({"days_survived": 10, "inhabitant_count": 0}), 1.0, "progress 1.0 (days met)"
	)


func test_m14_campaign_version() -> void:
	var CA: GDScript = load(_CA_PATH)
	var v: String = CA.call("version")
	assert_eq(v, "0.10.0-m14-engine-perf-content", "version() returns the M14 closeout version")


func test_m14_campaign_make() -> void:
	var CA: GDScript = load(_CA_PATH)
	var c: Variant = CA.call("make")
	assert_eq(c.chapter_count(), 0, "0 chapters initially")
	assert_eq(c.current_index(), 0, "index 0 initially")


func test_m14_campaign_add_chapter() -> void:
	var CA: GDScript = load(_CA_PATH)
	var CH: GDScript = load(_CH_PATH)
	var c: Variant = CA.call("make")
	var n: int = c.add_chapter(CH.call("make", &"c1", "C1", 10, 2))
	assert_eq(n, 1, "1 chapter after add")


func test_m14_campaign_current_chapter() -> void:
	var CA: GDScript = load(_CA_PATH)
	var CH: GDScript = load(_CH_PATH)
	var c: Variant = CA.call("make")
	c.add_chapter(CH.call("make", &"c1", "C1", 10, 2))
	c.add_chapter(CH.call("make", &"c2", "C2", 20, 4))
	var current: Variant = c.current_chapter()
	assert_eq(current.id(), &"c1", "current=c1")


func test_m14_campaign_advance() -> void:
	var CA: GDScript = load(_CA_PATH)
	var CH: GDScript = load(_CH_PATH)
	var c: Variant = CA.call("make")
	c.add_chapter(CH.call("make", &"c1", "C1", 10, 2))
	c.add_chapter(CH.call("make", &"c2", "C2", 20, 4))
	c.advance()
	var current: Variant = c.current_chapter()
	assert_eq(current.id(), &"c2", "current=c2 after advance")


func test_m14_campaign_is_complete() -> void:
	var CA: GDScript = load(_CA_PATH)
	var CH: GDScript = load(_CH_PATH)
	var c: Variant = CA.call("make")
	c.add_chapter(CH.call("make", &"c1", "C1", 10, 2))
	assert_false(c.is_complete(), "not complete (1 chapter left)")
	c.advance()
	assert_true(c.is_complete(), "complete after advance")


func test_m14_campaign_make_default() -> void:
	# The M14 closeout ships a
	# default 5-chapter campaign.
	var CA: GDScript = load(_CA_PATH)
	var c: Variant = CA.call("make_default_campaign")
	assert_eq(c.chapter_count(), 5, "5 chapters in default campaign")
	assert_eq(c.current_chapter().id(), &"awakening", "first chapter=awakening")
