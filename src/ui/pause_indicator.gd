# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M16 Bucket 4: Pause Indicator.
# Per ADR-0028, when the window
# loses focus, show a "PAUSED"
# overlay + pause auto-tick.
class_name PauseIndicator
extends RefCounted

const VERSION_STRING: String = "0.12.0-m16-docs-eol"
const _REASON_NONE: String = ""
const _REASON_WINDOW_UNFOCUSED: String = "window_unfocused"
const _REASON_MANUAL: String = "manual_pause"
const _REASON_AUTO: String = "auto_pause"

var _focused: bool = true
var _manually_paused: bool = false
var _reason: String = _REASON_NONE


static func version() -> String:
	return VERSION_STRING


static func make() -> PauseIndicator:
	return PauseIndicator.new()


static func reason_window_unfocused() -> String:
	return _REASON_WINDOW_UNFOCUSED


static func reason_manual_pause() -> String:
	return _REASON_MANUAL


static func reason_auto_pause() -> String:
	return _REASON_AUTO


func is_paused() -> bool:
	return not _focused or _manually_paused


func pause_reason() -> String:
	if _manually_paused:
		return _REASON_MANUAL
	if not _focused:
		return _REASON_WINDOW_UNFOCUSED
	return _REASON_NONE


func set_focused(focused: bool) -> void:
	_focused = focused


func is_focused() -> bool:
	return _focused


func set_manual_pause(paused: bool) -> void:
	_manually_paused = paused


func is_manually_paused() -> bool:
	return _manually_paused


func resume() -> void:
	_focused = true
	_manually_paused = false


func should_show_overlay() -> bool:
	# Show overlay only when paused
	# for a non-trivial reason.
	return is_paused()
