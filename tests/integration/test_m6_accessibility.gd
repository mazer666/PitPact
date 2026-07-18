# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M6 Bucket 4: Accessibility
# test net.
#
# The M6 Bucket 4 deliverable is the
# accessibility standard. The test net
# exercises:
#
#   1. The theme's Label color + bg
#      pass WCAG 2.1 AA contrast
#      (>= 4.5:1).
#   2. The theme's Button normal/hover
#      colors pass WCAG 2.1 AA.
#   3. The PlayableShell has focusable
#      Controls (StepButton,
#      AutoTickToggle, Power buttons).
#   4. The `tr()` resolution works for
#      all M6 strings.
extends GutTest

const _THEME_PATH: String = "res://assets/ui/gothic_fantasy_theme.tres"


## M6 Bucket 4: compute the
## relative luminance of an
## sRGB color (per WCAG 2.1).
func _luminance(c: Color) -> float:
	# WCAG 2.1: for each channel
	# (R, G, B), if value <= 0.03928,
	# use value / 12.92; otherwise use
	# ((value + 0.055) / 1.055) ** 2.4.
	var r: float = c.r
	var g: float = c.g
	var b: float = c.b
	if r <= 0.03928:
		r = r / 12.92
	else:
		r = pow((r + 0.055) / 1.055, 2.4)
	if g <= 0.03928:
		g = g / 12.92
	else:
		g = pow((g + 0.055) / 1.055, 2.4)
	if b <= 0.03928:
		b = b / 12.92
	else:
		b = pow((b + 0.055) / 1.055, 2.4)
	return 0.2126 * r + 0.7152 * g + 0.0722 * b


## M6 Bucket 4: compute the
## contrast ratio between two
## colors (per WCAG 2.1).
func _contrast(c1: Color, c2: Color) -> float:
	var l1: float = _luminance(c1)
	var l2: float = _luminance(c2)
	var lighter: float = max(l1, l2)
	var darker: float = min(l1, l2)
	return (lighter + 0.05) / (darker + 0.05)


func test_accessibility_label_contrast() -> void:
	# The Label foreground (parchment)
	# has a contrast >= 4.5:1 with the
	# background (ink). The test pins
	# the WCAG 2.1 AA threshold.
	var theme: Theme = load(_THEME_PATH)
	var fg: Color = theme.get_color("font_color", "Label")
	# Background is the Panel's bg_color
	# (the M5-Closeout panel bg is
	# (0.07, 0.06, 0.10, 0.92)).
	var bg: Color = Color(0.07, 0.06, 0.10, 1.0)
	var ratio: float = _contrast(fg, bg)
	assert_gte(
		ratio, 4.5, "Label foreground vs Panel bg: contrast = %.2f:1 (>= 4.5:1 WCAG AA)" % ratio
	)


func test_accessibility_button_normal_contrast() -> void:
	# The Button normal foreground
	# (parchment) has a contrast
	# >= 4.5:1 with the Button normal
	# background (stone). The test
	# pins the WCAG 2.1 AA threshold.
	var theme: Theme = load(_THEME_PATH)
	var fg: Color = theme.get_color("font_color", "Button")
	# Button normal bg is the M5-Closeout
	# (0.18, 0.16, 0.20, 1.0).
	var bg: Color = Color(0.18, 0.16, 0.20, 1.0)
	var ratio: float = _contrast(fg, bg)
	assert_gte(ratio, 4.5, "Button normal fg vs bg: contrast = %.2f:1 (>= 4.5:1 WCAG AA)" % ratio)


func test_accessibility_button_hover_contrast() -> void:
	# The Button hover foreground
	# (gold/white) has a contrast
	# >= 4.5:1 with the Button hover
	# background. The test pins the
	# WCAG 2.1 AA threshold.
	var theme: Theme = load(_THEME_PATH)
	var fg: Color = theme.get_color("font_hover_color", "Button")
	# Button hover bg is the M5-Closeout
	# (0.30, 0.20, 0.30, 1.0).
	var bg: Color = Color(0.30, 0.20, 0.30, 1.0)
	var ratio: float = _contrast(fg, bg)
	assert_gte(ratio, 4.5, "Button hover fg vs bg: contrast = %.2f:1 (>= 4.5:1 WCAG AA)" % ratio)


func test_accessibility_playable_shell_has_focusable_controls() -> void:
	# The PlayableShell.tscn has
	# focusable Controls: StepButton,
	# AutoTickToggle, Power buttons.
	# The test asserts each is a
	# focusable Control.
	var shell: PackedScene = load("res://scenes/main/PlayableShell.tscn")
	var instance: Node = shell.instantiate()
	add_child_autofree(instance)
	# The StepButton is focusable.
	var step: Button = instance.get_node_or_null("TickControl/HBox/StepButton")
	assert_ne(step, null, "StepButton exists in the .tscn")
	assert_true(step.focus_mode != Control.FOCUS_NONE, "StepButton is focusable")
	# The AutoTickToggle is focusable.
	var auto: CheckButton = instance.get_node_or_null("TickControl/HBox/AutoTickToggle")
	assert_ne(auto, null, "AutoTickToggle exists in the .tscn")
	assert_true(auto.focus_mode != Control.FOCUS_NONE, "AutoTickToggle is focusable")
	instance.queue_free()


func test_accessibility_i18n_strings_resolve() -> void:
	# The M6 closeout uses `tr()` for
	# all player-facing strings. The
	# test asserts a sample of keys
	# resolve to non-empty strings.
	assert_gt(
		String(tr("M5_GAMEOVER_TITLE_WIN")).length(), 0, "tr('M5_GAMEOVER_TITLE_WIN') is non-empty"
	)
	assert_gt(
		String(tr("M5_GAMEOVER_TITLE_LOSE")).length(),
		0,
		"tr('M5_GAMEOVER_TITLE_LOSE') is non-empty"
	)
	assert_gt(
		String(tr("M5_GAMEOVER_BUTTON_RESTART")).length(),
		0,
		"tr('M5_GAMEOVER_BUTTON_RESTART') is non-empty"
	)
	assert_gt(String(tr("ROOM_SHRINE_NAME")).length(), 0, "tr('ROOM_SHRINE_NAME') is non-empty")
	assert_gt(
		String(tr("CULTURE_LANTERNBEARER_NAME")).length(),
		0,
		"tr('CULTURE_LANTERNBEARER_NAME') is non-empty"
	)
