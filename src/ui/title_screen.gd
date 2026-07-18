# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M12 Side-Quest I:
# Title Screen.
#
# The M12 closeout ships a
# title screen with logo +
# subtitle + start button.
# The screen fades in over
# 1.5s (60 FPS perf budget
# per ADR-0023).
extends Control

# The canonical M12 version.
# The M12 closeout pins the
# version per ADR-0024.
const VERSION_STRING: String = "0.8.0-m12-ui-grafical-rework"

# Fade-in duration (1.5s).
# At 60 FPS, that's 90 frames.
const _FADE_DURATION: float = 1.5


# `version()` returns the
# canonical M12 version
# string.
static func version() -> String:
	return VERSION_STRING


# `_ready()` is the canonical
# "set up the title screen"
# entry point. The M12
# closeout's title screen
# fades in over 1.5s.
func _ready() -> void:
	var logo: TextureRect = get_node_or_null("Logo")
	var subtitle: Label = get_node_or_null("Subtitle")
	var start_button: Button = get_node_or_null("StartButton")
	if logo != null:
		_tween_fade_in(logo)
	if subtitle != null:
		_tween_fade_in(subtitle)
	if start_button != null:
		_tween_fade_in(start_button)


# `_tween_fade_in()` is the
# canonical "fade a node in"
# entry point. The M12 closeout
# uses `Tween` (0.15s per the
# perf budget; here we use
# 1.5s for the full title
# screen).
func _tween_fade_in(node: CanvasItem) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(node, "modulate:a", 1.0, _FADE_DURATION)


# `fade_in_duration()` returns
# the fade-in duration.
static func fade_in_duration() -> float:
	return _FADE_DURATION
