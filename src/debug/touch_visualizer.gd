# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M9 Side-Quest F:
# Touch Visualizer.
#
# The M9 closeout ships a
# headless-safe touch-input
# visualizer. The visualizer
# tracks taps + drag paths in
# memory and exposes them as
# a test-friendly API. The
# production path can render
# the visualization as a
# `Control` overlay (the M9.1
# closeout's job).
class_name TouchVisualizer
extends RefCounted

# The M9 closeout's touch
# visualizer constants. The
# zone matches the M8
# closeout's step-button zone
# (bottom-center, 50% wide,
# 10% tall).
const _STEP_ZONE_CENTER_X: float = 0.5
const _STEP_ZONE_CENTER_Y: float = 0.85
const _STEP_ZONE_HALF_W: float = 0.25
const _STEP_ZONE_HALF_H: float = 0.1

# Internal state.
var _taps: Array = []
var _drags: Array = []


# The canonical M9 version.
# The M9 closeout pins the
# version per ADR-0021.
static func version() -> String:
	return "0.5.0-m9-coop-foundation"


# `make()` creates a fresh
# visualizer.
static func make() -> TouchVisualizer:
	var v: TouchVisualizer = TouchVisualizer.new()
	return v


# `record_tap()` records a tap
# at the given position. The
# M9 closeout's tap is a
# single `InputEventScreenTouch`
# with `pressed=true`.
func record_tap(pos: Vector2) -> int:
	_taps.append(pos)
	return _taps.size()


# `record_drag()` records a
# drag from `from` to `to`.
# The M9 closeout's drag is a
# series of `InputEventScreenDrag`
# events.
func record_drag(from: Vector2, to: Vector2) -> int:
	_drags.append({"from": from, "to": to})
	return _drags.size()


# `is_in_step_zone()` returns
# whether the given position
# is in the step-button zone
# (the M8 closeout's zone).
func is_in_step_zone(pos: Vector2, viewport_size: Vector2) -> bool:
	var dx: float = absf(pos.x - viewport_size.x * _STEP_ZONE_CENTER_X)
	var dy: float = absf(pos.y - viewport_size.y * _STEP_ZONE_CENTER_Y)
	return dx < viewport_size.x * _STEP_ZONE_HALF_W and dy < viewport_size.y * _STEP_ZONE_HALF_H


# `tap_count()` returns the
# number of recorded taps.
func tap_count() -> int:
	return _taps.size()


# `drag_count()` returns the
# number of recorded drags.
func drag_count() -> int:
	return _drags.size()


# `taps()` returns the list of
# recorded tap positions.
func taps() -> Array:
	return _taps.duplicate()


# `drags()` returns the list
# of recorded drags.
func drags() -> Array:
	return _drags.duplicate()


# `clear()` removes all
# recorded events.
func clear() -> void:
	_taps.clear()
	_drags.clear()
