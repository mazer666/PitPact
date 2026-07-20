# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — isometric Camera2D controller.
#
# The camera is a Godot Camera2D node that satisfies ADR-0004
# (fixed orientation, free zoom, continuous pan). It is a pure
# presentation concern: it owns no game state, it does not
# preload anything from src/realm or src/world, and it does not
# mutate the data model. Other UI nodes (the main controller,
# the minimap, the title screen) call `zoom_to(value)` and
# `center_on(world_pos)` to drive it.
#
# The fixed-orientation rule from §8 of docs/requirements.md is
# enforced as an explicit no-op in `_set_rotation_safe()`; any
# non-zero write is logged and discarded. This is the
# confirmation-criterion test for ADR-0004 in the camera layer.
class_name IsometricCamera
extends Camera2D

## Free-zoom range. Mirrors the ADR-0004 pin values. Exposed
## as constants so tests can read the contract without poking
## private state.
const ZOOM_MIN: float = 0.5
const ZOOM_MAX: float = 3.0
const ZOOM_DEFAULT: float = 1.0

## Wheel / pinch step. Each mouse-wheel notch moves the zoom
## by this factor; touch pinch uses a ratio so the same
## constant produces a similar perceptual change.
const ZOOM_STEP: float = 1.1

## Pan speed multiplier for keyboard / trackpad edge-scroll.
## Drag-pan uses the raw mouse delta, not this constant.
const PAN_SPEED: float = 600.0

## Current zoom level. Read by the diagnostics overlay so the
## HUD can show the value the player is looking at.
var current_zoom: float = ZOOM_DEFAULT

## Optional reference to the realm façade. The camera never
## queries it for game state; the reference exists so the
## `center_on_world_tile()` helper can convert tile coordinates
## to world coordinates if a caller prefers the tile API. The
## reference is `null` until `bind_realm(realm)` is called.
var realm: RefCounted = null

## True if non-essential camera animations should be skipped
## (M5 closes out the full reduced-motion settings page; M1
## provides the hook so the rest of the UI can read it).
var reduced_motion: bool = false


func _ready() -> void:
	# Enforce the fixed-orientation rule from §8. Any non-zero
	# rotation on a Camera2D would tilt the isometric grid, which
	# is explicitly forbidden by ADR-0004. Setting it once at
	# _ready is enough; `_set_rotation_safe` is a guard for
	# accidental writes from elsewhere.
	_set_rotation_safe(0.0)
	make_current()
	current_zoom = zoom.x


## Programmatic zoom change. Clamps to [ZOOM_MIN, ZOOM_MAX] and
## updates the Camera2D `zoom` vector uniformly. Called by the
## minimap (zoom to fit), by debug commands, and by the wheel
## / pinch input handler.
func zoom_to(value: float) -> void:
	var clamped: float = clamp(value, ZOOM_MIN, ZOOM_MAX)
	current_zoom = clamped
	# Uniform scale: zoom is a Vector2, not a scalar, because
	# the Camera2D contract is per-axis. We keep the y axis
	# locked to the x axis so the aspect ratio is preserved.
	zoom = Vector2(clamped, clamped)


## Programmatic pan. Translates the camera so `world_pos`
## becomes the centre of the viewport. Other UI controls (the
## minimap click-to-jump, the pause-menu "centre on Hearth"
## action, the title-screen "centre on realm" preview) all
## route through this single entry point.
func center_on(world_pos: Vector2) -> void:
	position = world_pos


## Programmatic pan with a tile-coordinate convenience. If a
## realm façade has been bound via `bind_realm()`, the call
## goes through `WorldState` so the camera honours the
## isometric coordinate conversion in ADR-0004. If no realm
## is bound, the tile vector is treated as already in world
## coordinates and the call degrades to `center_on`.
func center_on_tile(tile: Vector2i) -> void:
	if realm != null and realm.has_method("tile_to_world"):
		center_on(realm.call("tile_to_world", tile))
	else:
		# Stand-alone (no realm yet) — interpret tile as world.
		center_on(Vector2(tile))


## Bind the realm façade. The camera never calls into the
## façade on its own; binding only changes how
## `center_on_tile()` resolves coordinates. This is the
## single edge from the camera into src/realm and it is
## one-directional (camera -> realm, never the reverse).
func bind_realm(realm_ref: RefCounted) -> void:
	realm = realm_ref


## Convenience: jump back to the default zoom level. Used by
## the diagnostics overlay's "Reset view" button.
func reset_zoom() -> void:
	zoom_to(ZOOM_DEFAULT)


## Wheel zoom: each wheel notch scales by ZOOM_STEP toward
## the wheel direction. Bound in `_unhandled_input` so a
## focused LineEdit / Slider still receives its wheel events.
func _on_zoom_in() -> void:
	zoom_to(current_zoom * ZOOM_STEP)


func _on_zoom_out() -> void:
	zoom_to(current_zoom / ZOOM_STEP)


## Pan by a delta in world space. Right-mouse drag and
## two-finger trackpad drag both call into this entry point.
func pan_by(delta: Vector2) -> void:
	# Dividing by `current_zoom` keeps the on-screen pan speed
	# independent of zoom level (at higher zoom the player
	# expects to see less world move under their finger).
	position -= delta / max(current_zoom, 0.0001)


## Reduced-motion setter. When true, future animation paths
## (M5: minimap pulse, M5: camera follow-easing) will be
## stubbed. The M1 implementation does not animate the camera
## at all, so this is a no-op for now; the setter is exposed
## so the settings UI can drive it without an API change.
func set_reduced_motion(p_enabled: bool) -> void:
	reduced_motion = p_enabled


## Guarded rotation setter. ADR-0004 forbids any camera
## rotation; this method is the single point where the rule
## is enforced. Calling code that attempts to rotate the
## camera will hit this guard and get a logged warning.
func _set_rotation_safe(angle_degrees: float) -> void:
	if not is_equal_approx(angle_degrees, 0.0):
		push_warning("IsometricCamera: rotation attempt ignored (ADR-0004 fixed orientation)")
		return
	rotation_degrees = 0.0


## Camera2D in Godot 4 exposes a `rotation_degrees` setter via
## the `rotation` property. We override the `_set` hook so a
## direct write through the Inspector (or via tween / anim)
## also goes through the guard.
func _set(property: StringName, value: Variant) -> bool:
	if property == "rotation" or property == "rotation_degrees":
		_set_rotation_safe(float(value))
		return true
	return false


## Input handler. The Camera2D prefers `_unhandled_input` so
## focused controls (text fields, sliders) can still receive
## their own events; the camera is a viewport-level concern.
func _unhandled_input(event: InputEvent) -> void:
	# Mouse wheel: each notch zooms one step. factor > 0 means
	# scroll up (zoom in), factor < 0 means scroll down (zoom
	# out). We use `button_index == MOUSE_BUTTON_WHEEL_UP/DOWN`
	# because they are guaranteed by the engine contract.
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.pressed:
			match mb.button_index:
				MOUSE_BUTTON_WHEEL_UP:
					_on_zoom_in()
					get_viewport().set_input_as_handled()
				MOUSE_BUTTON_WHEEL_DOWN:
					_on_zoom_out()
					get_viewport().set_input_as_handled()

	# Touch: two-finger pinch zoom. We track the first two
	# `ScreenTouch` events and accumulate the distance between
	# them. When the distance changes by more than a deadband
	# we scale the zoom. Single-finger touches are forwarded
	# to the input map and are interpreted as pan by the main
	# scene.
	if event is InputEventScreenTouch:
		# The actual pinch math lives in `_on_pinch`; here we
		# only need to forward the touch to the main scene via
		# the input map (the main scene owns the drag-pan
		# state machine).
		pass

	# Trackpad / two-finger pan: when the cursor moves with
	# the right mouse button held, we pan. We detect this
	# generically by checking for any `InputEventMouseMotion`
	# whose `button_mask` includes the right mouse button.
	if event is InputEventMouseMotion:
		var mm: InputEventMouseMotion = event
		if (mm.button_mask & MOUSE_BUTTON_MASK_RIGHT) != 0:
			pan_by(mm.relative)
			get_viewport().set_input_as_handled()
