# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M16 Side-Quest M: Performance
# Overlay. F3 toggles a debug
# overlay showing FPS, frame
# time, draw calls, memory.
class_name PerformanceOverlay
extends RefCounted

const VERSION_STRING: String = "0.12.0-m16-docs-eol"

var _visible: bool = false
var _metrics: Dictionary = {"fps": 0, "frame_ms": 0.0, "draw_calls": 0, "memory_mb": 0.0}


static func version() -> String:
	return VERSION_STRING


static func make() -> PerformanceOverlay:
	return PerformanceOverlay.new()


func is_visible() -> bool:
	return _visible


func set_visible(visible: bool) -> void:
	_visible = visible


func toggle() -> bool:
	_visible = not _visible
	return _visible


func update_metrics(fps: int, frame_ms: float, draw_calls: int, memory_mb: float) -> void:
	_metrics["fps"] = fps
	_metrics["frame_ms"] = frame_ms
	_metrics["draw_calls"] = draw_calls
	_metrics["memory_mb"] = memory_mb


func metrics() -> Dictionary:
	return _metrics.duplicate()


func fps() -> int:
	return _metrics.get("fps", 0)


func frame_ms() -> float:
	return _metrics.get("frame_ms", 0.0)


func draw_calls() -> int:
	return _metrics.get("draw_calls", 0)


func memory_mb() -> float:
	return _metrics.get("memory_mb", 0.0)


func is_fps_target_met(target_fps: int) -> bool:
	return _metrics.get("fps", 0) >= target_fps
