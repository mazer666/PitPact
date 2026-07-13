# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — pause menu controller.
#
# The pause menu is a small modal panel. It owns four
# buttons — "Resume", "Save", "Load", "Quit to Title" — and
# routes clicks to the main scene controller. The F3 toggle
# of the diagnostics overlay is exposed on the same key in
# the input map; this controller does not own that
# behaviour, the main controller does.
class_name PauseMenuController
extends CanvasLayer

## Reference to the main scene controller. Injected by the
## main scene after `add_child`. All routing goes through
## this seam.
var main_controller: MainSceneController = null

## Cached references to the four buttons. Wired in
## `_ready()`. Private because the wiring is an
## implementation detail; the public surface is the
## controller hook.
var _resume_button: Button
var _save_button: Button
var _load_button: Button
var _quit_button: Button


func _ready() -> void:
	_resume_button = _find_button("ResumeButton")
	_save_button = _find_button("SaveButton")
	_load_button = _find_button("LoadButton")
	_quit_button = _find_button("QuitToTitleButton")

	if _resume_button != null:
		_resume_button.pressed.connect(_on_resume_pressed)
	if _save_button != null:
		_save_button.pressed.connect(_on_save_pressed)
	if _load_button != null:
		_load_button.pressed.connect(_on_load_pressed)
	if _quit_button != null:
		_quit_button.pressed.connect(_on_quit_pressed)

	_apply_localized_labels()


## Resume: the main controller owns the pause flag, so we
## route through it. The F3 / Esc binding in the main
## controller will also unpause, which keeps the key and
## the button in sync.
func _on_resume_pressed() -> void:
	if main_controller != null:
		# The main controller's toggle is symmetric; calling
		# it twice is fine.
		main_controller._toggle_pause()


## Save: M1 stub. The save service lands with M2.
func _on_save_pressed() -> void:
	if main_controller != null:
		main_controller.save_game()


## Load: M1 stub. The save service lands with M2.
func _on_load_pressed() -> void:
	if main_controller != null:
		main_controller.load_game()


## Quit to title: the main controller is the seam.
func _on_quit_pressed() -> void:
	if main_controller != null:
		main_controller.quit_to_title()


## Apply localized labels. The MSGID keys match the
## `source_strings.csv` row IDs added by the content track.
func _apply_localized_labels() -> void:
	if _resume_button != null:
		_resume_button.text = tr("MENU_RESUME")
	if _save_button != null:
		_save_button.text = tr("MENU_SAVE")
	if _load_button != null:
		_load_button.text = tr("MENU_LOAD")
	if _quit_button != null:
		_quit_button.text = tr("MENU_RETURN_TO_TITLE")

	var header: Label = _find_label("PauseHeader")
	if header != null:
		header.text = tr("MENU_RESUME")


func _find_button(node_name: String) -> Button:
	var n: Node = find_child(node_name, true, false)
	if n is Button:
		return n
	return null


func _find_label(node_name: String) -> Label:
	var n: Node = find_child(node_name, true, false)
	if n is Label:
		return n
	return null
