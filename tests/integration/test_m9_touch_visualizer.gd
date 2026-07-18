# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M9 Side-Quest F (Touch
# Visualizer) test net.
extends GutTest

const _TV_PATH: String = "res://src/debug/touch_visualizer.gd"


func test_m9_touch_visualizer_version() -> void:
	var TV: GDScript = load(_TV_PATH)
	var v: String = TV.call("version")
	assert_eq(v, "0.5.0-m9-coop-foundation", "version() returns the M9 closeout version")


func test_m9_touch_visualizer_record_tap() -> void:
	var TV: GDScript = load(_TV_PATH)
	var vis: Variant = TV.call("make")
	vis.record_tap(Vector2(100, 200))
	vis.record_tap(Vector2(300, 400))
	assert_eq(vis.tap_count(), 2, "2 taps recorded")
	var taps: Array = vis.taps()
	assert_eq(taps[0], Vector2(100, 200), "first tap pos")
	assert_eq(taps[1], Vector2(300, 400), "second tap pos")


func test_m9_touch_visualizer_record_drag() -> void:
	var TV: GDScript = load(_TV_PATH)
	var vis: Variant = TV.call("make")
	vis.record_drag(Vector2(0, 0), Vector2(100, 100))
	assert_eq(vis.drag_count(), 1, "1 drag recorded")
	var drags: Array = vis.drags()
	assert_eq(drags[0]["from"], Vector2(0, 0), "drag from")
	assert_eq(drags[0]["to"], Vector2(100, 100), "drag to")


func test_m9_touch_visualizer_is_in_step_zone() -> void:
	var TV: GDScript = load(_TV_PATH)
	var vis: Variant = TV.call("make")
	# Default viewport 800x600.
	var viewport: Vector2 = Vector2(800, 600)
	# Center of step zone: (400, 510).
	assert_true(vis.is_in_step_zone(Vector2(400, 510), viewport), "step zone center is in zone")
	# Edge of zone: (200, 540).
	assert_true(vis.is_in_step_zone(Vector2(201, 541), viewport), "step zone edge is in zone")
	# Outside zone: (100, 100).
	assert_false(vis.is_in_step_zone(Vector2(100, 100), viewport), "top-left is outside step zone")


func test_m9_touch_visualizer_clear() -> void:
	var TV: GDScript = load(_TV_PATH)
	var vis: Variant = TV.call("make")
	vis.record_tap(Vector2(0, 0))
	vis.record_drag(Vector2(0, 0), Vector2(1, 1))
	vis.clear()
	assert_eq(vis.tap_count(), 0, "tap_count after clear")
	assert_eq(vis.drag_count(), 0, "drag_count after clear")


func test_m9_touch_visualizer_counters() -> void:
	var TV: GDScript = load(_TV_PATH)
	var vis: Variant = TV.call("make")
	# Initially empty.
	assert_eq(vis.tap_count(), 0, "initial tap_count=0")
	assert_eq(vis.drag_count(), 0, "initial drag_count=0")
