# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M11 Bucket 2:
# Prozedural Upgrade.
#
# The M11 closeout ships a
# prozedural upgrader that
# enhances the M5-Real-UI-Assets
# procedurally-generated tiles
# + inhabitants with texture
# variations (Perlin-noise
# overlays) and color shifts
# (hue shifts). The upgrader
# is deterministic (per
# ADR-0005) and reproducible.
#
# The M11 closeout's tests
# verify the upgrade logic;
# the production path renders
# the upgraded assets to PNG
# (the M11.1 closeout's job).
class_name ProceduralUpgrader
extends RefCounted

# The canonical M11 version.
# The M11 closeout pins the
# version per ADR-0023.
const VERSION_STRING: String = "0.7.0-m11-art-rework"


# `version()` returns the
# canonical M11 version
# string.
static func version() -> String:
	return VERSION_STRING


# `apply_hue_shift()` shifts
# the hue of a color by the
# given amount (in degrees,
# 0-360). The M11 closeout
# uses this for inhabitant
# variation (each inhabitant
# gets a slightly different
# hue for visual distinction).
static func apply_hue_shift(color: Color, shift_deg: float) -> Color:
	var h: float = color.h
	var s: float = color.s
	var v: float = color.v
	h = fmod(h + shift_deg / 360.0, 1.0)
	return Color.from_hsv(h, s, v, color.a)


# `apply_perlin_overlay()`
# adds a perlin-noise-based
# variation to a color. The
# M11 closeout uses this for
# tile texturing.
static func apply_perlin_overlay(color: Color, seed_value: int, intensity: float) -> Color:
	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.seed = seed_value
	noise.frequency = 0.05
	# The M11 closeout uses
	# a 1D perlin value (with
	# the seed_value as x) to
	# modulate the color's
	# brightness. Different
	# seeds give different
	# noise values.
	var noise_value: float = noise.get_noise_1d(float(seed_value))
	var factor: float = 1.0 + noise_value * intensity
	return Color(color.r * factor, color.g * factor, color.b * factor, color.a)


# `compute_tile_offsets()`
# returns the (x, y) offsets
# for a tile in the 4x4
# atlas. The M11 closeout
# uses this for the tile
# atlas (per ADR-0019).
static func compute_tile_offsets(tile_id: int) -> Vector2i:
	return Vector2i(tile_id % 4, tile_id / 4)


# `compute_hue_shift_for_inhabitant()`
# returns a deterministic
# hue shift for an inhabitant
# (based on their culture +
# role). The M11 closeout
# uses this to differentiate
# the 13 inhabitants.
static func compute_hue_shift_for_inhabitant(culture: String, role: String) -> float:
	# Simple hash-based shift.
	var hash: int = hash(culture + ":" + role)
	return fmod(float(hash) / 1000.0, 60.0) - 30.0


# `seed_for_tile()` returns a
# deterministic seed for a
# tile (based on the tile id).
static func seed_for_tile(tile_id: int) -> int:
	return tile_id * 7919 + 42
