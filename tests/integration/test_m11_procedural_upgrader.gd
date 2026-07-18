# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M11 Bucket 2
# (Prozedural Upgrade) test net.
extends GutTest

const _PU_PATH: String = "res://src/assets/procedural_upgrader.gd"


func test_m11_procedural_upgrader_version() -> void:
	var PU: GDScript = load(_PU_PATH)
	var v: String = PU.call("version")
	assert_eq(v, "0.7.0-m11-art-rework", "version() returns the M11 closeout version")


func test_m11_apply_hue_shift_changes_hue() -> void:
	# Hue shift changes the
	# color's hue.
	var PU: GDScript = load(_PU_PATH)
	var original: Color = Color.from_hsv(0.0, 0.5, 0.5)
	var shifted: Color = PU.call("apply_hue_shift", original, 90.0)
	assert_ne(shifted.h, original.h, "shifted hue differs from original")
	assert_eq(shifted.s, original.s, "saturation preserved")
	assert_eq(shifted.v, original.v, "value preserved")


func test_m11_apply_hue_shift_zero_is_identity() -> void:
	# 0-degree shift returns
	# the same hue.
	var PU: GDScript = load(_PU_PATH)
	var original: Color = Color.from_hsv(0.3, 0.5, 0.5)
	var shifted: Color = PU.call("apply_hue_shift", original, 0.0)
	assert_eq(shifted.h, original.h, "0-degree shift is identity")


func test_m11_apply_perlin_overlay_deterministic() -> void:
	# Same seed = same overlay.
	var PU: GDScript = load(_PU_PATH)
	var color: Color = Color(0.5, 0.5, 0.5)
	var a: Color = PU.call("apply_perlin_overlay", color, 42, 0.1)
	var b: Color = PU.call("apply_perlin_overlay", color, 42, 0.1)
	assert_eq(a, b, "same seed -> same overlay")


func test_m11_apply_perlin_overlay_different_seeds() -> void:
	# Different seeds give
	# different overlays.
	var PU: GDScript = load(_PU_PATH)
	var color: Color = Color(0.5, 0.5, 0.5)
	var a: Color = PU.call("apply_perlin_overlay", color, 1, 0.1)
	var b: Color = PU.call("apply_perlin_overlay", color, 2, 0.1)
	assert_ne(a, b, "different seeds -> different overlays")


func test_m11_compute_tile_offsets_4x4_atlas() -> void:
	# The M11 closeout uses a
	# 4x4 atlas (per ADR-0019).
	var PU: GDScript = load(_PU_PATH)
	var offsets: Vector2i = PU.call("compute_tile_offsets", 0)
	assert_eq(offsets, Vector2i(0, 0), "tile 0 = (0, 0)")
	var offsets5: Vector2i = PU.call("compute_tile_offsets", 5)
	assert_eq(offsets5, Vector2i(1, 1), "tile 5 = (1, 1)")


func test_m11_compute_hue_shift_deterministic() -> void:
	# Same culture + role =
	# same hue shift.
	var PU: GDScript = load(_PU_PATH)
	var a: float = PU.call("compute_hue_shift_for_inhabitant", "lanternbearer", "pilot")
	var b: float = PU.call("compute_hue_shift_for_inhabitant", "lanternbearer", "pilot")
	assert_eq(a, b, "same input -> same hue shift")


func test_m11_compute_hue_shift_different_for_different_inputs() -> void:
	# Different cultures get
	# different hue shifts.
	var PU: GDScript = load(_PU_PATH)
	var a: float = PU.call("compute_hue_shift_for_inhabitant", "lanternbearer", "pilot")
	var b: float = PU.call("compute_hue_shift_for_inhabitant", "bellows", "pilot")
	assert_ne(a, b, "different cultures -> different shifts")
