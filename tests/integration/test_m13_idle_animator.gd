# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M13 Bucket 1 (Idle
# Animator) test net.
extends GutTest

const _IA_PATH: String = "res://src/ui/idle_animator.gd"


func test_m13_idle_animator_version() -> void:
	var IA: GDScript = load(_IA_PATH)
	var v: String = IA.call("version")
	assert_eq(v, "0.9.0-m13-visual-polish", "version() returns the M13 closeout version")


func test_m13_idle_animator_make() -> void:
	var IA: GDScript = load(_IA_PATH)
	var anim: Variant = IA.call("make")
	assert_eq(anim.node_count(), 0, "no nodes initially")
	assert_eq(anim.frame_count(), 0, "0 frames initially")


func test_m13_idle_animator_add_node() -> void:
	var IA: GDScript = load(_IA_PATH)
	var anim: Variant = IA.call("make")
	var n: int = anim.add_node("/root/Node1")
	assert_eq(n, 1, "1 node registered")


func test_m13_idle_animator_add_node_with_offset() -> void:
	var IA: GDScript = load(_IA_PATH)
	var anim: Variant = IA.call("make")
	anim.add_node("/root/Node1", 5)
	anim.add_node("/root/Node2", 10)
	assert_eq(anim.node_count(), 2, "2 nodes registered")


func test_m13_idle_animator_add_duplicate_is_noop() -> void:
	# Adding a node twice is
	# a no-op.
	var IA: GDScript = load(_IA_PATH)
	var anim: Variant = IA.call("make")
	anim.add_node("/root/Node1")
	anim.add_node("/root/Node1")
	assert_eq(anim.node_count(), 1, "1 node (duplicate ignored)")


func test_m13_idle_animator_tick_advances_frames() -> void:
	var IA: GDScript = load(_IA_PATH)
	var anim: Variant = IA.call("make")
	anim.add_node("/root/Node1")
	anim.tick()
	assert_eq(anim.frame_count(), 1, "1 frame after 1 tick")
	anim.tick()
	assert_eq(anim.frame_count(), 2, "2 frames after 2 ticks")


func test_m13_idle_animator_scale_values_canonical() -> void:
	# The 3 scale values are
	# 1.0, 1.05, 0.95.
	var IA: GDScript = load(_IA_PATH)
	var values: Array = IA.call("scale_values")
	assert_eq(values.size(), 3, "3 scale values")
	assert_eq(values[0], 1.0, "first scale=1.0 (neutral)")
	assert_eq(values[1], 1.05, "second scale=1.05 (inhale)")
	assert_eq(values[2], 0.95, "third scale=0.95 (exhale)")


func test_m13_idle_animator_current_frame_unknown_node() -> void:
	# `current_frame()` for an
	# unknown node returns
	# 1.0 (default).
	var IA: GDScript = load(_IA_PATH)
	var anim: Variant = IA.call("make")
	var scale: float = anim.current_frame("/root/Unknown")
	assert_eq(scale, 1.0, "default scale=1.0 for unknown node")


func test_m13_idle_animator_cycle_duration() -> void:
	# Cycle duration is 2.0s.
	var IA: GDScript = load(_IA_PATH)
	var d: float = IA.call("cycle_duration")
	assert_eq(d, 2.0, "cycle duration is 2.0s")
