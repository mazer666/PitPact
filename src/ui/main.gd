# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — main UI scene controller.
#
# `Main` is the single scene that boots the M1 playable shell:
# it composes the camera, the placeholder tile grid, the title
# screen, the pause menu, the diagnostics overlay, and the
# minimap. It does NOT own gameplay state; gameplay state lives
# behind the realm façade. This script is a *router* — it
# listens for input actions and forwards them to the right
# subcontroller.
#
# The M1 shell is intentionally minimal. It exists to prove:
#
#   1. The camera responds to wheel / pinch / drag and exposes
#      `zoom_to()` / `center_on()` programmatically.
#   2. The input map is wired and every action has a touch
#      binding.
#   3. F3 toggles the diagnostics overlay; M toggles the
#      minimap; Esc pauses the game.
#   4. The pause menu can save, resume, and return to title.
#   5. Save / load does NOT mutate the camera state (covered
#      by tests/integration/test_camera_input.gd).
#
# The M2 / M3 milestones will fill in the realm façade, the
# event log, and the inhabitant list. This script's structure
# is forward-compatible: every subcontroller is a child node
# and the routing logic is just a switch on action names.
class_name MainSceneController
extends Node

## Path constants for the sub-scenes. They are preloaded at
## load time so a missing scene surfaces immediately instead
## of timing out at runtime. Use `preload()` (not `load()`)
## so the editor's class-name table resolves the children
## before the scene is instantiated.
const _TITLE_SCREEN_PATH := "res://scenes/main/TitleScreen.tscn"
const _PAUSE_MENU_PATH := "res://scenes/ui/PauseMenu.tscn"
const _DIAGNOSTICS_OVERLAY_PATH := "res://scenes/ui/DiagnosticsOverlay.tscn"
const _MINIMAP_PATH := "res://scenes/ui/Minimap.tscn"
const _DEMO_REALM_PATH := "res://scenes/world/DemoRealm.tscn"

## Live instances of the sub-controllers. They are children
## of `Main` so the SceneTree owns their lifetime. Public
## so the integration tests can poke at them (e.g.
## `main.camera` in test_camera_input.gd).
var camera: IsometricCamera
var diagnostics: CanvasLayer
var minimap: CanvasLayer
var pause_menu: CanvasLayer
var title_screen: Control
var demo_realm: Node2D

## The most recent realm scene we instantiated, used by the
## pause menu's "save" / "load" actions. `null` when no realm
## is loaded.
var realm_root: Node = null

## Reduced-motion preference. M5 will surface this in a
## settings page; for M1 the value is read once at boot and
## propagated to the sub-controllers. Default false (no
## reduced motion) until the player opts in.
var reduced_motion: bool = false

## Whether the game is currently paused. The M1 shell only
## pauses its own input and clock; the M2 sim will gate its
## own tick on this flag.
var is_paused: bool = false

## Cached sub-scenes. We do not need to free them: the
## `Main` node owns them and Godot ref-counts resources.
## Private because the controllers are the public surface;
## the scenes are an implementation detail of `_ready()`.
var _title_screen_scene: PackedScene
var _pause_menu_scene: PackedScene
var _diagnostics_scene: PackedScene
var _minimap_scene: PackedScene
var _demo_realm_scene: PackedScene


func _ready() -> void:
	# Preload every sub-scene. We use ResourceLoader.exists()
	# defensively so a missing asset is logged once, at boot,
	# not buried in a runtime crash later.
	_title_screen_scene = _preload_or_null(_TITLE_SCREEN_PATH, "title screen")
	_pause_menu_scene = _preload_or_null(_PAUSE_MENU_PATH, "pause menu")
	_diagnostics_scene = _preload_or_null(_DIAGNOSTICS_OVERLAY_PATH, "diagnostics overlay")
	_minimap_scene = _preload_or_null(_MINIMAP_PATH, "minimap")
	_demo_realm_scene = _preload_or_null(_DEMO_REALM_PATH, "demo realm")

	# Camera: child of the world layer so the UI overlay
	# (CanvasLayer) does not move with it. The IsometricCamera
	# class is defined in src/ui/isometric_camera.gd; it owns
	# its own _ready() and enforces the fixed-orientation rule.
	camera = IsometricCamera.new()
	camera.name = "IsometricCamera"
	camera.zoom_to(IsometricCamera.ZOOM_DEFAULT)
	add_child(camera)

	# Demo realm placeholder. Track A will swap this for the
	# real TileMapLayer; the stand-alone DemoRealm is a
	# coloured 12x12 grid that exercises the camera + input
	# plumbing without depending on Track A.
	if _demo_realm_scene != null:
		realm_root = _demo_realm_scene.instantiate()
		realm_root.name = "Realm"
		add_child(realm_root)

	# UI overlays. Each lives on its own CanvasLayer so the
	# camera transform does not affect it. The canvas layer
	# order is the draw order: minimap on top of the world,
	# diagnostics over the minimap, pause menu / title screen
	# over everything.
	if _minimap_scene != null:
		minimap = _minimap_scene.instantiate()
		minimap.name = "Minimap"
		minimap.layer = 10
		add_child(minimap)

	if _diagnostics_scene != null:
		diagnostics = _diagnostics_scene.instantiate()
		diagnostics.name = "Diagnostics"
		diagnostics.layer = 20
		# Diagnostics start hidden; the player toggles them
		# with F3. The M1 default is hidden so the demo is
		# not noisy out of the box.
		diagnostics.visible = false
		add_child(diagnostics)

	if _title_screen_scene != null:
		title_screen = _title_screen_scene.instantiate()
		title_screen.name = "TitleScreen"
		title_screen.layer = 30
		add_child(title_screen)
		# The title screen starts visible. The realm scene is
		# still mounted so the background of the title screen
		# is the (currently empty) world.
		title_screen.visible = true

	if _pause_menu_scene != null:
		pause_menu = _pause_menu_scene.instantiate()
		pause_menu.name = "PauseMenu"
		pause_menu.layer = 40
		pause_menu.visible = false
		add_child(pause_menu)

	# Apply the reduced-motion preference to every controller
	# that cares. The M1 stubs are no-ops; M5 wires the real
	# animations.
	_apply_reduced_motion()


## Input routing. `_unhandled_input` is the right hook for
## global actions that should fire even when a focused control
## is active — the diagnostics overlay and minimap want F3 /
## M to work even when the player is hovering a button. We
## only call `set_input_as_handled()` when we actually
## consumed the event.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_toggle_diagnostics"):
		_toggle_diagnostics()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_toggle_minimap"):
		_toggle_minimap()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_pause"):
		_toggle_pause()
		get_viewport().set_input_as_handled()
		return


## The title screen calls this when the player picks
## "New Campaign" or "Continue". The M1 stub simply hides
## the title; M2 will hand the call to the realm factory
## and the save service.
func start_campaign(_slot: int) -> void:
	if title_screen != null:
		title_screen.visible = false


## The pause menu calls this when the player picks "Save".
## The M1 stub logs the intent; the M2 save service will
## replace the body. The camera state is intentionally NOT
## saved — see `tests/integration/test_camera_input.gd`.
func save_game() -> void:
	print("[Main] save_game (M1 stub; M2 will delegate to src/save/)")


## The pause menu calls this when the player picks "Load".
## Same stub shape as `save_game()`. Camera state is also
## not restored on load.
func load_game() -> void:
	print("[Main] load_game (M1 stub; M2 will delegate to src/save/)")


## The pause menu calls this when the player picks
## "Quit to Title". Restores the title screen and unhides it.
func quit_to_title() -> void:
	is_paused = false
	get_tree().paused = false
	if pause_menu != null:
		pause_menu.visible = false
	if title_screen != null:
		title_screen.visible = true


## The title screen calls this when the player picks "Quit".
## M1 stops the process; M2 may want to return to a clean
## state instead.
func quit_game() -> void:
	get_tree().quit(0)


## Public setter for the reduced-motion flag. The settings
## UI (M5) will call this directly. Tests call it too.
func set_reduced_motion(enabled: bool) -> void:
	reduced_motion = enabled
	_apply_reduced_motion()


## Toggle the diagnostics overlay. The overlay exposes its
## own `toggle()` method so the visibility-flip logic lives
## near the data it flips.
func _toggle_diagnostics() -> void:
	if diagnostics == null:
		return
	diagnostics.visible = not diagnostics.visible


## Toggle the minimap.
func _toggle_minimap() -> void:
	if minimap == null:
		return
	minimap.visible = not minimap.visible


## Toggle the pause menu. The M1 shell only flips visibility
## and the `is_paused` flag; M2 will gate the sim tick on
## `is_paused`.
func _toggle_pause() -> void:
	if pause_menu == null:
		return
	is_paused = not is_paused
	pause_menu.visible = is_paused
	# Honour the convention from the M0 closeout: pause
	# freezes world input, not UI input. The pause menu
	# itself is still interactive.
	get_tree().paused = is_paused


## Apply the reduced-motion preference. M5 will read this
## from a settings resource; M1 keeps the value on the
## controller so tests can flip it without touching the
## project settings.
func _apply_reduced_motion() -> void:
	if camera != null:
		camera.set_reduced_motion(reduced_motion)


## Helper: preload a scene and return null with a clear
## warning if it is missing. The M1 boot path is
## best-effort: a missing overlay should not crash the
## game; a missing world should not either. The test suite
## asserts that the world scene is present.
func _preload_or_null(path: String, label: String) -> PackedScene:
	if not ResourceLoader.exists(path):
		push_warning("Main: '%s' scene missing at %s; degraded boot." % [label, path])
		return null
	var res: Resource = load(path)
	if res is PackedScene:
		return res
	push_warning("Main: '%s' scene at %s is not a PackedScene." % [label, path])
	return null
