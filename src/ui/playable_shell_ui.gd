# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M5-Foundation: PlayableShellUI controller.
#
# `PlayableShellUI` is the M5-Foundation code-driven
# UI controller. The controller is a `CanvasLayer`
# that programmatically builds the playable
# shell's UI: a top-bar (time, FPS), a left
# inhabitant panel, a right Pactmaker panel
# (3 powers with intervention-counter gauge),
# a bottom tick control (Step button + auto-tick
# toggle), and a settings menu (difficulty +
# locale).
#
# The controller is code-driven (no `.tscn`) so
# the M5-Foundation smoke test can instantiate it
# in headless mode without a scene file. The
# M5 closeout can swap the code-driven UI for a
# `.tscn`-driven UI (the M1-Closeout pattern) when
# the visual polish lands.
#
# Per ADR-0002, this file does not import from
# `src/realm/`. It imports from `src/core`,
# `src/sim`, `src/world`, `src/content`, and
# `src/save` only.
class_name PlayableShellUI
extends CanvasLayer

## The autostart delay. The shell's
## auto-tick loop ticks the sim at 1
## tick/second; the autostart delay is
## the M2 sim's documented time.
const AUTO_TICK_INTERVAL: float = 1.0

## The reference to the canonical M5
## playable sim (the `build()` factory's
## output). The UI mutates this sim in
## response to player input.
var sim: Sim

## The realm façade. The UI delegates
## the save/load to the realm. The
## M5-Foundation stub returns the
## sim directly; the M5 closeout
## wires the realm façade.
var realm: RefCounted

## The inhabitants. The UI renders
## the inhabitant list in the left
## panel.
var inhabitants: Array

## The Pactmaker. The UI renders the
## three powers in the right panel.
var pactmaker: Pactmaker

## The settings. The UI renders the
## difficulty + locale in the settings
## menu.
var settings: Settings

## The factions. The UI can show a
## faction-stance indicator (M5+
## content).
var factions: Array

## Auto-tick enabled. The UI ticks
## the sim every `AUTO_TICK_INTERVAL`
## seconds when this is true.
var auto_tick_enabled: bool = false

## Auto-tick accumulator. The
## accumulator increments every
## `_process` tick; when it reaches
## `AUTO_TICK_INTERVAL`, the sim
## ticks and the accumulator resets.
var _auto_tick_acc: float = 0.0

## Time display label. The top-bar
## shows the current sim time.
var _time_label: Label

## FPS display label. The top-bar
## shows the current FPS.
var _fps_label: Label

## Inhabitant panel container. The
## left panel renders one row per
## inhabitant.
var _inhabitant_panel: VBoxContainer

## Pactmaker panel container. The
## right panel renders one button
## per power + the intervention
## counter.
var _pactmaker_panel: VBoxContainer

## Tick control container. The
## bottom bar renders the Step
## button + the auto-tick toggle.
var _tick_control: HBoxContainer


## Initialize the UI from a
## `build()` output. The factory
## returns a `Dictionary`; the
## controller unpacks the keys
## and binds them to the public
## fields.
func bind(built: Dictionary) -> void:
	sim = built["sim"]
	realm = built.get("world", null)
	inhabitants = built["inhabitants"]
	pactmaker = built["pactmaker"]
	settings = built["settings"]
	factions = built["factions"]


## Build the UI. The method is the
## canonical "set up the UI" entry
## point; the M5-Foundation smoke
## test calls it after `bind()`.
func _ready() -> void:
	# Top bar: time + FPS.
	var top_bar: HBoxContainer = HBoxContainer.new()
	top_bar.name = "TopBar"
	add_child(top_bar)
	_time_label = Label.new()
	_time_label.name = "TimeLabel"
	_time_label.text = "Day 0"
	top_bar.add_child(_time_label)
	_fps_label = Label.new()
	_fps_label.name = "FPSLabel"
	_fps_label.text = "FPS 0"
	top_bar.add_child(_fps_label)
	# Left panel: inhabitants.
	_inhabitant_panel = VBoxContainer.new()
	_inhabitant_panel.name = "InhabitantPanel"
	add_child(_inhabitant_panel)
	for inh in inhabitants:
		var row: HBoxContainer = HBoxContainer.new()
		var label: Label = Label.new()
		label.text = "%s (%s)" % [String(inh.id), String(inh.role)]
		row.add_child(label)
		_inhabitant_panel.add_child(row)
	# Right panel: Pactmaker powers.
	_pactmaker_panel = VBoxContainer.new()
	_pactmaker_panel.name = "PactmakerPanel"
	add_child(_pactmaker_panel)
	for power in pactmaker.powers:
		var btn: Button = Button.new()
		btn.text = String(power.id)
		btn.name = "Power_" + String(power.id)
		# Connect the click to a
		# Callable that invokes
		# the power via
		# `pactmaker.apply_power`.
		btn.pressed.connect(_on_power_pressed.bind(power.id))
		_pactmaker_panel.add_child(btn)
	# Bottom bar: Step button + auto-tick toggle.
	_tick_control = HBoxContainer.new()
	_tick_control.name = "TickControl"
	add_child(_tick_control)
	var step_btn: Button = Button.new()
	step_btn.text = "Step"
	step_btn.name = "StepButton"
	step_btn.pressed.connect(_on_step_pressed)
	_tick_control.add_child(step_btn)
	var auto_btn: CheckButton = CheckButton.new()
	auto_btn.text = "Auto-tick"
	auto_btn.name = "AutoTickToggle"
	auto_btn.toggled.connect(_on_auto_tick_toggled)
	_tick_control.add_child(auto_btn)


## Per-frame update. The method
## advances the auto-tick
## accumulator and updates the
## time + FPS labels.
func _process(delta: float) -> void:
	if sim != null and _time_label != null:
		_time_label.text = "Day %d" % int(sim.time_days)
	if _fps_label != null:
		_fps_label.text = "FPS %d" % int(Engine.get_frames_per_second())
	if auto_tick_enabled and sim != null:
		_auto_tick_acc += delta
		if _auto_tick_acc >= AUTO_TICK_INTERVAL:
			_auto_tick_acc = 0.0
			_on_step_pressed()


## Step the sim by 1 in-game day.
## The method is the canonical
## "advance the sim" entry point.
## It is called by the Step button
## and the auto-tick loop.
func _on_step_pressed() -> void:
	if sim == null:
		return
	sim.tick(1.0, inhabitants, [])


## Toggle the auto-tick. The
## method is the canonical "switch
## auto-tick on/off" entry point.
## The Step button is independent
## of the auto-tick (the player can
## always step manually).
func _on_auto_tick_toggled(toggled_on: bool) -> void:
	auto_tick_enabled = toggled_on
	if not toggled_on:
		_auto_tick_acc = 0.0


## Power button click. The method
## is the canonical "use a
## Pactmaker power" entry point.
## It builds the sim dictionary
## the M4Pactmaker powers expect
## and calls
## `pactmaker.apply_power`.
func _on_power_pressed(power_id: StringName) -> void:
	if pactmaker == null or sim == null:
		return
	# The M4 Pactmaker powers read
	# the sim's `crises` as a
	# `Dictionary` (the canonical
	# Sim type). The
	# PlayableShell's sim is a
	# `Sim` instance; the powers
	# read `sim.crises` directly.
	var sim_dict: Dictionary = {
		"crises": sim.crises,
		"settings": settings,
		"knowledge_state": sim.knowledge_state,
		"pactmaker": pactmaker,
		"factions": factions,
		"exploration_map": sim.exploration_map,
		"anchor": sim.anchor if sim.anchor != null else Vector2i(12, 12),
	}
	pactmaker.apply_power(power_id, sim_dict, sim.time_days)
