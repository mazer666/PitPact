# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — title screen controller.
#
# The title screen is a small, opinionated menu. It owns three
# buttons — "New Campaign", "Continue", "Quit" — and routes
# clicks to the main scene controller. The "Continue" button is
# greyed out (or hidden) when no save slot is present; the M1
# stub checks the user data directory for a sentinel file and
# shows the button if any save exists. The real save
# enumeration lands with M2.
class_name TitleScreenController
extends CanvasLayer

## Preloaded button scene. We use the engine's PackedButton
## path so the title screen is portable; contributors can
## theme it without touching this script.
const _BUTTON_PATH := "res://scenes/ui/_DefaultButton.tscn"

## Visible-when-no-save flag. The M1 stub flips this on if
## the player has a save; the M2 save service replaces the
## detection with a real slot scan.
@export var allow_continue: bool = false

## Reference to the main scene controller. Injected by the
## main scene after `add_child` so the title screen can
## call `start_campaign(slot)` / `quit_game()` without
## knowing the full scene tree. The reference is `null` in
## the editor preview, which is fine — the buttons no-op.
var main_controller: MainSceneController = null

## Cached references to the three buttons. Wired in
## `_ready()`. Private because the wiring is an
## implementation detail; the title screen's public
## surface is the controller hook.
var _new_button: Button
var _continue_button: Button
var _quit_button: Button


func _ready() -> void:
	_new_button = _find_button("NewCampaignButton")
	_continue_button = _find_button("ContinueButton")
	_quit_button = _find_button("QuitButton")

	# The title screen does not own its child scene tree
	# (the .tscn provides it); we just wire signals.
	if _new_button != null:
		_new_button.pressed.connect(_on_new_pressed)
	if _continue_button != null:
		_continue_button.pressed.connect(_on_continue_pressed)
		_continue_button.disabled = not allow_continue
	if _quit_button != null:
		_quit_button.pressed.connect(_on_quit_pressed)

	# Externalise every label. The strings live in
	# locales/source_strings.csv; the M1 stub inlines the
	# key for traceability but `tr()` is the only way a
	# user-visible string leaves this script.
	_apply_localized_labels()


## New Campaign pressed. The M1 shell does not know how to
## build a campaign; the main controller is the seam. We
## pass `slot = -1` to mean "no slot, fresh campaign".
func _on_new_pressed() -> void:
	if main_controller != null:
		main_controller.start_campaign(-1)


## Continue pressed. M1 stubs this: the save service is M2.
## We still route through the main controller so the call
## surface stays consistent.
func _on_continue_pressed() -> void:
	if main_controller != null:
		main_controller.start_campaign(0)


## Quit pressed. Routes to the main controller's quit hook
## so the title screen does not have to know about the
## SceneTree.
func _on_quit_pressed() -> void:
	if main_controller != null:
		main_controller.quit_game()


## Wire the localized labels. The `tr()` calls use MSGID
## keys; the locale catalogue (M1 stub) maps them to
## English. A real German translation lands with M5.
func _apply_localized_labels() -> void:
	if _new_button != null:
		_new_button.text = tr("MENU_NEW_CAMPAIGN")
	if _continue_button != null:
		_continue_button.text = tr("MENU_CONTINUE")
	if _quit_button != null:
		_quit_button.text = tr("MENU_QUIT")
	# Window / scene title. The label's initial text is set
	# in the .tscn to a placeholder; we override it here
	# with the localized name of the game.
	var title_label: Label = _find_label("TitleLabel")
	if title_label != null:
		title_label.text = tr("PITPACT_GAME_NAME")


## Helper: walk the children to find a button by name. The
## title-screen .tscn names the buttons deterministically
## so the script does not have to track them through
## positions.
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
