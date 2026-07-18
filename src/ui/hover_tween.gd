# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M12 Bucket 2:
# Hover Tween Helper.
#
# The M12 closeout ships a
# helper carrier for animated
# hover transitions. The
# helper provides the canonical
# "fade the stylebox" entry
# point; the M12 closeout's
# tests verify the tween
# timings respect the 60 FPS
# perf budget (per ADR-0023).
class_name HoverTween
extends RefCounted

# The canonical M12 version.
# The M12 closeout pins the
# version per ADR-0024.
const VERSION_STRING: String = "0.8.0-m12-ui-grafical-rework"

# The M12 closeout's tween
# duration (0.15s = 150ms).
# This gives 6-7 frames at
# 60 FPS, well within the
# perf budget.
const _TWEEN_DURATION: float = 0.15


# `version()` returns the
# canonical M12 version
# string.
static func version() -> String:
	return VERSION_STRING


# `tween_duration()` returns
# the tween duration in
# seconds.
static func tween_duration() -> float:
	return _TWEEN_DURATION


# `frames_for_tween()` returns
# the number of frames at 60
# FPS that the tween takes.
# The M12 closeout uses this
# for the perf budget check.
static func frames_for_tween() -> int:
	return int(ceil(_TWEEN_DURATION * 60.0))


# `apply_hover()` simulates
# the hover state on a button
# (returns the new modulation
# color for the tween). The
# M12 closeout uses a subtle
# brightness boost.
static func apply_hover(base_modulate: Color) -> Color:
	return Color(
		base_modulate.r * 1.2, base_modulate.g * 1.2, base_modulate.b * 1.2, base_modulate.a
	)


# `apply_pressed()` simulates
# the pressed state (darker
# + slight scale).
static func apply_pressed(base_modulate: Color) -> Color:
	return Color(
		base_modulate.r * 0.7, base_modulate.g * 0.7, base_modulate.b * 0.7, base_modulate.a
	)


# `apply_disabled()` simulates
# the disabled state (gray-out
# + low alpha).
static func apply_disabled(base_modulate: Color) -> Color:
	return Color(
		base_modulate.r * 0.5 + 0.2,
		base_modulate.g * 0.5 + 0.2,
		base_modulate.b * 0.5 + 0.2,
		base_modulate.a * 0.6
	)
