# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
extends GutTest

## M3 cycle 2 (Track B) — narrative-anchor tests.
## Pins the public surface of `NarrativeAnchor`
## (M3 §8 "fixed narrative anchors" requirement)
## and the sim's per-tick step 7b trigger rule.


func test_anchor_default_state() -> void:
	var a: NarrativeAnchor = NarrativeAnchor.new()
	assert_eq(String(a.id), "", "default id is empty")
	assert_eq(a.trigger_at_day, 0.0, "default trigger_at_day is 0.0")
	assert_false(a.triggered, "default triggered is false")
	assert_false(a.resolved, "default resolved is false")


func test_anchor_from_content() -> void:
	var a: NarrativeAnchor = NarrativeAnchor.from_content(
		&"first_morning", 1.0, &"ANCHOR_FIRST_MORNING_NAME", &"ANCHOR_FIRST_MORNING_SUMMARY"
	)
	assert_eq(String(a.id), "first_morning", "id set")
	assert_eq(a.trigger_at_day, 1.0, "trigger_at_day set")
	assert_eq(String(a.display_name), "ANCHOR_FIRST_MORNING_NAME", "display_name set")
	assert_false(a.triggered, "fresh anchor is not triggered")
	assert_false(a.resolved, "fresh anchor is not resolved")


func test_anchor_trigger_idempotent() -> void:
	var a: NarrativeAnchor = NarrativeAnchor.from_content(&"x", 0.0, &"x_name", &"x_sum")
	a.trigger()
	assert_true(a.triggered, "triggered after trigger()")
	a.trigger()
	assert_true(a.triggered, "still triggered after second trigger()")


func test_anchor_resolve_implies_triggered() -> void:
	var a: NarrativeAnchor = NarrativeAnchor.from_content(&"x", 0.0, &"x", &"x")
	a.resolve()
	assert_true(a.triggered, "resolve() implies triggered")
	assert_true(a.resolved, "resolve() sets resolved")


func test_anchor_equals() -> void:
	var a: NarrativeAnchor = NarrativeAnchor.from_content(&"x", 0.5, &"n", &"s")
	var b: NarrativeAnchor = NarrativeAnchor.from_content(&"x", 0.5, &"n", &"s")
	assert_true(a.equals(b), "two equal anchors are equal")
	a.trigger()
	assert_false(a.equals(b), "triggered/!triggered differ")
