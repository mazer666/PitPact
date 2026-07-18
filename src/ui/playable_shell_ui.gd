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

## M5-Closeout Bucket 1: the
## canonical culture-id to
## portrait-path mapping.
## The 6 cultures are the
## M2 Track A + M3 Closeout
## setup (per
## `src/sim/cultures/*.gd`).
const _CULTURE_PORTRAIT_PATHS: Dictionary = {
	"lanternbearer": "res://assets/inhabitants/lanternbearer_scribe.png",
	"bellows": "res://assets/inhabitants/bellows.png",
	"ember": "res://assets/inhabitants/ember.png",
	"ledger": "res://assets/inhabitants/ledger.png",
	"silvershroud": "res://assets/inhabitants/silvershroud.png",
	"tide": "res://assets/inhabitants/tide.png",
	# Settlers are a generic
	# fallback (the M4 closeout
	# had two settler inhabitants).
	"settler": "res://assets/inhabitants/settler.png",
}

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

## M5-Closeout: the game state
## carrier (`M5GameState`). The
## carrier tracks the player's
## survival progress and exposes
## the win/lose predicates. The
## UI's `GameOverBanner` reads the
## carrier to render the game-over
## screen.
var game_state: M5GameState

## M5-Closeout: the world map. The
## UI holds the world reference so
## the `GameOverBanner` can render
## the realm's final state.
var world: Variant

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

## The crisis banner. The M5-Foundation
## shows a translucent red banner when a
## crisis is pending; the player picks
## one of the three choices via the
## banner buttons.
var _crisis_banner: PanelContainer

## The intervention-counter label. The
## right panel shows "0 / 3 interventions"
## (the M4 closeout default).
var _counter_label: Label

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

## M5-Closeout: the original
## built-dictionary from
## `PlayableShell.build()`. The
## UI holds the reference so the
## Restart button can rebuild a
## fresh sim with a new SEED.
var _built_dict: Dictionary

## M5-Closeout: the game-over
## banner. The banner is hidden
## while the game is `playing`;
## visible when the outcome is
## `win` or `lose`.
var _game_over_banner: PanelContainer

## M5-Closeout: the game-over
## title label.
var _game_over_title: Label

## M5-Closeout: the game-over
## summary label.
var _game_over_summary: Label

## M5-Closeout: the current
## SEED. The seed is bumped
## on every restart.
var _current_seed: int = 0

## Build-once guard. The M5-Foundation
## `build_ui` is idempotent: `_ready`
## (scene path) and `bind` (test path)
## can both call it, but only the first
## call constructs the UI (the second
## call returns early). The guard pins
## the invariant: the inhabitant +
## power rows are populated exactly
## once.
var _built: bool = false


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
	game_state = built.get("game_state", null)
	world = built.get("world", null)
	_built_dict = built
	_current_seed = int(built.get("seed", 0))
	# M5-Closeout: sync the game
	# state's `inhabitant_count`
	# with the bound inhabitants
	# array. The `evaluate` method
	# uses the count for the
	# win/lose checks.
	if game_state != null and inhabitants != null:
		game_state.inhabitant_count = inhabitants.size()
	# The bind path is the canonical
	# "set the data" entry point;
	# the .tscn production path runs
	# `_ready` after bind, but the
	# headless test path calls
	# `build_ui` directly.
	if is_inside_tree():
		build_ui()


## Build the UI. The method is the
## canonical "set up the UI" entry
## point; the M5-Foundation smoke
## test calls it after `bind()`.
func _ready() -> void:
	# The .tscn path: when the scene is
	# added to the tree, the `_ready`
	# callback runs. The `bind()` call
	# is the canonical "set the sim
	# data" entry point; the M5-Foundation
	# pattern is: instantiate ->
	# bind -> add to tree.
	# If `sim` is already bound (e.g. by
	# a test that binds first), the
	# build runs immediately. Otherwise
	# the build is deferred to the
	# explicit `bind()` call.
	if sim != null:
		build_ui()


## Build the UI from the bound sim
## data. The method is the canonical
## "construct the UI" entry point;
## the smoke test calls it directly.
## The .tscn production path runs
## `build_ui` via `_ready` (when the
## scene is added to the tree after
## a `bind()` call).


func build_ui() -> void:
	if _built:
		return
	_built = true
	for c2 in get_children():
		print("  child: ", c2.name, " type=", c2.get_class())
	# Try to bind to the .tscn-defined
	# nodes first (the canonical M5
	# production path). Fall back to
	# code-driven UI when the node
	# references are missing (the
	# headless smoke-test path).
	var node_top: Node = get_node_or_null("TopBar/HBox/TimeLabel")
	if node_top != null:
		_time_label = node_top
		_fps_label = get_node("TopBar/HBox/FpsLabel")
		# Build inhabitant + pactmaker
		# rows from the data into the
		# .tscn-defined VBoxContainers.
		var inhab_list: Node = get_node("InhabitantPanel/VBox/InhabitantList")
		_inhabitant_panel = inhab_list
		for inh in inhabitants:
			_inhabitant_panel.add_child(_build_inhabitant_row(inh))
		var powers_list: Node = get_node("PactmakerPanel/VBox/PowersList")
		_pactmaker_panel = powers_list
		for power in pactmaker.powers:
			powers_list.add_child(_build_power_button(power))
		_counter_label = get_node("PactmakerPanel/VBox/CounterLabel")
		_counter_label.text = "0 / %d interventions" % int(pactmaker.intervention_limit)
		# Wire the .tscn-defined tick
		# controls.
		var step_btn: Button = get_node("TickControl/HBox/StepButton")
		step_btn.pressed.connect(_on_step_pressed)
		var auto_btn: CheckButton = get_node("TickControl/HBox/AutoTickToggle")
		auto_btn.toggled.connect(_on_auto_tick_toggled)
		# Hide the crisis banner until
		# a crisis is pending.
		_crisis_banner = get_node("CrisisBanner")
		_crisis_banner.visible = false
		# M5-Closeout: hide the game-over
		# banner (the player is alive).
		_game_over_banner = null
		if has_node("GameOverBanner"):
			_game_over_banner = get_node("GameOverBanner")
			_game_over_title = get_node("GameOverBanner/VBox/GameOverTitle")
			_game_over_summary = get_node("GameOverBanner/VBox/GameOverSummary")
			var restart_btn: Button = get_node("GameOverBanner/VBox/HBox/RestartButton")
			var quit_btn: Button = get_node("GameOverBanner/VBox/HBox/QuitButton")
			restart_btn.pressed.connect(_on_restart_pressed)
			quit_btn.pressed.connect(_on_quit_pressed)
			_game_over_banner.visible = false
		return
	# Code-driven fallback (headless
	# test path: no .tscn, build the
	# UI from scratch). The M5
	# closeout can drop the fallback
	# once the .tscn is mandatory.
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
		var row: HBoxContainer = _build_inhabitant_row(inh)
		_inhabitant_panel.add_child(row)
	# Right panel: Pactmaker powers.
	_pactmaker_panel = VBoxContainer.new()
	_pactmaker_panel.name = "PactmakerPanel"
	add_child(_pactmaker_panel)
	for power in pactmaker.powers:
		var btn: Button = _build_power_button(power)
		_pactmaker_panel.add_child(btn)


## M5-Closeout Bucket 1: return
## the portrait path for a
## culture. The method is the
## canonical "give me the
## portrait for this culture"
## entry point; the test
## pins the mapping for all
## 6 cultures.
func _portrait_path_for_culture(culture: String) -> String:
	if _CULTURE_PORTRAIT_PATHS.has(culture):
		return String(_CULTURE_PORTRAIT_PATHS[culture])
	# Fallback: lanternbearer
	# portrait (the M4 default).
	return "res://assets/inhabitants/lanternbearer_scribe.png"


## Build a single inhabitant row (HBoxContainer
## with portrait + label). The factory is the
## canonical "row per inhabitant" entry point;
## the M5 closeout can swap the portrait
## for a hand-drawn sprite.
func _build_inhabitant_row(inh: Inhabitant) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	var portrait: TextureRect = TextureRect.new()
	portrait.custom_minimum_size = Vector2(16, 24)
	portrait.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	# Load the portrait from the
	# assets directory. The M4 closeout
	# portraits are keyed by culture +
	# role. The M5-Closeout Bucket 1
	# supports 6 cultures (per ADR-0017):
	# lanternbearer, bellows, ember,
	# ledger, silvershroud, tide.
	# The default portrait is
	# `lanternbearer_scribe`; the
	# per-culture override is a
	# `res://assets/inhabitants/<culture>.png`
	# lookup. The factory is the
	# canonical "portrait for
	# culture" entry point.
	var portrait_path: String = _portrait_path_for_culture(String(inh.culture))
	if ResourceLoader.exists(portrait_path):
		portrait.texture = load(portrait_path)
	row.add_child(portrait)
	var label: Label = Label.new()
	label.text = "%s (%s)" % [String(inh.id), String(inh.role)]
	row.add_child(label)
	return row


## Build a single Pactmaker power button.
## The factory is the canonical "button
## per power" entry point; the M5 closeout
## can swap the icon for a hand-drawn
## sprite.
func _build_power_button(power: Power) -> Button:
	var btn: Button = Button.new()
	btn.text = String(power.id)
	btn.name = "Power_" + String(power.id)
	btn.pressed.connect(_on_power_pressed.bind(power.id))
	# Optional: load an icon from
	# `res://assets/ui/power_<id>.png`
	# when present.
	var icon_path: String = "res://assets/ui/power_%s.png" % String(power.id)
	if ResourceLoader.exists(icon_path):
		btn.icon = load(icon_path)
	return btn


## Per-frame update. The method## Per-frame update. The method
## advances the auto-tick
## accumulator and updates the
## time + FPS labels.
func _process(delta: float) -> void:
	if sim != null and _time_label != null:
		_time_label.text = "Day %d" % int(sim.time_days)
	if _fps_label != null:
		_fps_label.text = "FPS %d" % int(Engine.get_frames_per_second())
	if _counter_label != null and pactmaker != null:
		_counter_label.text = (
			"%d / %d interventions"
			% [int(pactmaker.intervention_count), int(pactmaker.intervention_limit)]
		)
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
	# M5-Closeout: tick the game
	# state carrier. The carrier
	# increments `days_survived`,
	# recomputes the room counts,
	# and re-evaluates the win/
	# lose conditions.
	if game_state != null:
		game_state.tick_day_with_world(sim, world)
		# If the game ended, show
		# the game-over banner.
		if game_state.check_win_condition() or game_state.check_lose_condition():
			_show_game_over()
	# Update the time label
	# immediately so headless
	# tests (no _process loop)
	# can assert the day.
	if _time_label != null:
		_time_label.text = format_day_label(int(sim.time_days))


## Format the day label. The method is
## the canonical "Day N" entry point;
## the M5 closeout can swap the format
## string (e.g. "Day N / T") without
## touching the call sites. The test
## net pins the format to "Day N".
func format_day_label(day: int) -> String:
	return "Day %d" % int(day)


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


## M5-Closeout: show the game-over
## banner. The method is the canonical
## "the game is over, show the UI"
## entry point; the test pins the
## banner visibility + title + summary.
func _show_game_over() -> void:
	if _game_over_banner == null:
		return
	_game_over_banner.visible = true
	if game_state == null:
		return
	# Win: green-tinted "Victory!"
	# Lose: red-tinted "Defeat".
	if game_state.check_win_condition():
		if _game_over_title != null:
			_game_over_title.text = "Victory!"
		if _game_over_summary != null:
			_game_over_summary.text = (
				"You survived %d days and built a viable realm." % int(game_state.days_survived)
			)
	else:
		if _game_over_title != null:
			_game_over_title.text = "Defeat"
		if _game_over_summary != null:
			_game_over_summary.text = "Reason: %s" % String(game_state.reason)


## M5-Closeout: hide the game-over
## banner. The method is the canonical
## "reset the game-over UI" entry
## point; the test pins the banner
## visibility (false after restart).
func _hide_game_over() -> void:
	if _game_over_banner != null:
		_game_over_banner.visible = false


## M5-Closeout: restart the game. The
## method is the canonical "start a
## new game" entry point; the
## `RestartButton` calls it after the
## player loses or wins. The method
## bumps the SEED, rebuilds the sim,
## and re-binds the UI. The M5-Closeout
## ADR-0017 §Bucket 4 pins the
## restart loop's invariants.
func _on_restart_pressed() -> void:
	_hide_game_over()
	# Bump the SEED so the next
	# game has a different
	# outcome (the M5-Closeout
	# restart loop).
	_current_seed += 1
	# Rebuild the sim with the
	# new SEED. The `PlayableShell.build()`
	# factory is SEED-pinned (per
	# ADR-0005).
	var PS: GDScript = load("res://src/ui/playable_shell.gd")
	if PS == null:
		return
	var fresh: Dictionary = PS.call("build_with_seed", _current_seed)
	if fresh.is_empty():
		return
	# Re-bind the UI to the
	# fresh sim. The `bind()` call
	# resets the UI state (the
	# `_built` guard is reset by
	# the call).
	_reset_built()
	bind(fresh)


## M5-Closeout: quit the game. The
## method is the canonical "exit
## the game" entry point; the
## `QuitButton` calls it. The
## M5-Foundation headless mode
## simply calls `quit()`; the
## M5-Closeout can swap in a
## "are you sure?" dialog.
func _on_quit_pressed() -> void:
	get_tree().quit()


## M5-Closeout: reset the
## build-once guard. The
## method is the canonical
## "allow `build_ui` to run
## again" entry point; the
## restart path calls it
## before `bind()` so the
## fresh sim's data
## re-populates the UI.
func _reset_built() -> void:
	_built = false
	# Clear the existing UI
	# children so the fresh
	# build_ui call does not
	# duplicate them.
	if _inhabitant_panel != null:
		for child in _inhabitant_panel.get_children():
			child.queue_free()
	if _pactmaker_panel != null:
		for child in _pactmaker_panel.get_children():
			child.queue_free()
	_inhabitant_panel = null
	_pactmaker_panel = null
	_counter_label = null
	_time_label = null
	_fps_label = null
	_game_over_banner = null
	_game_over_title = null
	_game_over_summary = null
