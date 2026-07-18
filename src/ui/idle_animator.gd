# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M13 Bucket 1:
# Idle Animator.
#
# The M13 closeout ships a
# simple 3-frame breathing
# animation for inhabitant
# portraits. The animator
# cycles through 3 scale
# values (1.0, 1.05, 0.95)
# over 2.0s.
#
# The M13 closeout's tests
# verify the cycle progression
# and the scale values.
class_name IdleAnimator
extends RefCounted

# The canonical M13 version.
# The M13 closeout pins the
# version per ADR-0025.
const VERSION_STRING: String = "0.9.0-m13-visual-polish"

# The 3-frame breathing scale
# values. The M13 closeout's
# cycle is 2.0s (60 frames @
# 60 FPS for 1 cycle of
# 20 frames per frame).
const _SCALE_VALUES: Array = [1.0, 1.05, 0.95]
const _FRAMES_PER_CYCLE: int = 60  # 1 second @ 60 FPS
const _CYCLE_DURATION: float = 2.0  # seconds

# `version()` returns the
# canonical M13 version
# string.
# Internal state.
var _nodes: Dictionary = {}
var _frame_offsets: Dictionary = {}
var _tick_count: int = 0


static func version() -> String:
	return VERSION_STRING


# `make()` creates a fresh
# idle animator.
static func make() -> IdleAnimator:
	var ia: IdleAnimator = IdleAnimator.new()
	ia._nodes = {}
	ia._frame_offsets = {}
	ia._tick_count = 0
	return ia


# `add_node()` registers a
# node for the idle animation.
# The optional `frame_offset`
# parameter offsets the node's
# frame (for variation).
# Returns the number of
# registered nodes.
func add_node(path: String, frame_offset: int = 0) -> int:
	if _nodes.has(path):
		return _nodes.size()
	_nodes[path] = 0
	_frame_offsets[path] = frame_offset
	return _nodes.size()


# `tick()` advances the
# animator by 1 frame.
func tick() -> int:
	_tick_count += 1
	for path in _nodes.keys():
		var offset: int = _frame_offsets.get(path, 0)
		var total: int = _tick_count + offset
		var frame: int = total % (_SCALE_VALUES.size() * _FRAMES_PER_CYCLE / _SCALE_VALUES.size())
		var scale_idx: int = int(frame / (_FRAMES_PER_CYCLE / _SCALE_VALUES.size()))
		_nodes[path] = _SCALE_VALUES[scale_idx]
	return _tick_count


# `frame_count()` returns the
# total number of ticks.
func frame_count() -> int:
	return _tick_count


# `current_frame()` returns
# the current scale value
# for the given node. Returns
# 1.0 if the node is not
# registered.
func current_frame(path: String) -> float:
	return _nodes.get(path, 1.0)


# `node_count()` returns the
# number of registered nodes.
func node_count() -> int:
	return _nodes.size()


# `scale_values()` returns
# the canonical 3 scale values.
static func scale_values() -> Array:
	return _SCALE_VALUES.duplicate()


# `cycle_duration()` returns
# the cycle duration in
# seconds.
static func cycle_duration() -> float:
	return _CYCLE_DURATION
