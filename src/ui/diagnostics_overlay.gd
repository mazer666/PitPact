# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — diagnostics overlay controller.
#
# The diagnostics overlay is a translucent panel that shows
# the current camera target, zoom level, world time,
# inhabitant count, room count, and the tail of the event
# log. It is toggled with F3. The M1 implementation is a
# stub: it reads the camera state and shows fixed placeholders
# for the realm data. M2 wires the realm façade and the
# audit log.
class_name DiagnosticsOverlayController
extends CanvasLayer

## Update rate for the readouts. Higher than 4 Hz is wasted
## on a diagnostics panel; lower is fine but feels laggy.
const UPDATE_INTERVAL_SEC: float = 0.25

## Reference to the camera. The overlay reads the camera
## state once per `_process` tick (at 4 Hz; we do not
## need 60 Hz) and copies the values into the labels.
var camera: IsometricCamera = null

## Reference to the main scene controller. The overlay
## uses the reduced-motion flag from the main controller
## to skip the M5-styled entrance pulse. M1 has no pulse
## so the value is currently a no-op.
var main_controller: MainSceneController = null

## Cached labels. Wired in `_ready()`. The .tscn names
## each label deterministically so this script does not
## have to walk by index.
var _camera_target_label: Label
var _zoom_label: Label
var _world_time_label: Label
var _inhabitant_count_label: Label
var _room_count_label: Label
var _event_log_label: Label
var _header_label: Label

## Update accumulator. Throttles the readout refresh to
## `UPDATE_INTERVAL_SEC` so the panel does not redraw at
## 60 Hz (wasted work on a diagnostics panel).
var _update_accumulator: float = 0.0


func _ready() -> void:
	_camera_target_label = _find_label("CameraTargetLabel")
	_zoom_label = _find_label("ZoomLabel")
	_world_time_label = _find_label("WorldTimeLabel")
	_inhabitant_count_label = _find_label("InhabitantCountLabel")
	_room_count_label = _find_label("RoomCountLabel")
	_event_log_label = _find_label("EventLogLabel")
	_header_label = _find_label("DiagnosticsHeader")

	_apply_localized_labels()

	# Set a translucent backdrop. The .tscn provides the
	# ColorRect; we read its colour and force the alpha to
	# 0.6 so the overlay is readable but does not occlude
	# the world entirely. ADR-0004's "no rotation" rule does
	# not apply to UI elements — the overlay is a Godot
	# Control, not the projection camera.
	var backdrop: ColorRect = _find_color_rect("Backdrop")
	if backdrop != null:
		var c: Color = backdrop.color
		c.a = 0.6
		backdrop.color = c

	# First paint so the labels are correct on the frame
	# the overlay first becomes visible.
	_refresh_readouts()


## Per-frame tick. Reads the camera state at a throttled
## rate and refreshes the readouts. M1 does not have a
## realm façade or an audit log, so the non-camera fields
## stay at their placeholder values.
func _process(delta: float) -> void:
	if not visible:
		return
	_update_accumulator += delta
	if _update_accumulator < UPDATE_INTERVAL_SEC:
		return
	_update_accumulator = 0.0
	_refresh_readouts()


## Public toggle. The main controller calls this on F3
## (and the route through `visible` is also valid; the
## method is provided so callers do not have to flip the
## `visible` flag directly).
func toggle() -> void:
	visible = not visible


## Apply localized labels. MSGID keys match the
## `source_strings.csv` row IDs.
func _apply_localized_labels() -> void:
	# The header uses the DIAG_TOGGLE key from the locale
	# CSV (which documents the F3 hotkey). The other
	# readouts are M1 placeholders; their keys are
	# reserved but the CSV is owned by the content track
	# and will be updated alongside any new label.
	if _header_label != null:
		_header_label.text = tr("DIAG_TOGGLE")
	if _camera_target_label != null:
		_camera_target_label.text = tr("DIAG_CAMERA_TARGET") + ": -"
	if _zoom_label != null:
		_zoom_label.text = tr("DIAG_ZOOM") + ": -"
	if _world_time_label != null:
		_world_time_label.text = tr("DIAG_WORLD_TIME") + ": -"
	if _inhabitant_count_label != null:
		_inhabitant_count_label.text = tr("DIAG_INHABITANTS") + ": -"
	if _room_count_label != null:
		_room_count_label.text = tr("DIAG_ROOMS") + ": -"
	if _event_log_label != null:
		_event_log_label.text = tr("DIAG_EVENT_LOG_HEADER")


## Refresh the readouts. The camera fields are live; the
## realm fields are placeholders. M2 will replace the
## placeholders with calls into the realm façade and the
## audit log.
func _refresh_readouts() -> void:
	if camera != null and _camera_target_label != null:
		_camera_target_label.text = (
			tr("DIAG_CAMERA_TARGET")
			+ ": ("
			+ str(snappedf(camera.position.x, 0.1))
			+ ", "
			+ str(snappedf(camera.position.y, 0.1))
			+ ")"
		)
	if camera != null and _zoom_label != null:
		_zoom_label.text = (tr("DIAG_ZOOM") + ": " + str(snappedf(camera.current_zoom, 0.01)) + "x")
	# Placeholders. The M2 audit log + realm façade plug in
	# here. We render the keys as the visible string so the
	# panel is never empty / always truthful about its
	# current data.
	if _world_time_label != null:
		_world_time_label.text = tr("DIAG_WORLD_TIME") + ": 0"
	if _inhabitant_count_label != null:
		_inhabitant_count_label.text = tr("DIAG_INHABITANTS") + ": 0"
	if _room_count_label != null:
		_room_count_label.text = tr("DIAG_ROOMS") + ": 0"
	if _event_log_label != null:
		_event_log_label.text = tr("DIAG_EVENT_LOG_HEADER") + "\n  -"


func _find_label(node_name: String) -> Label:
	var n: Node = find_child(node_name, true, false)
	if n is Label:
		return n
	return null


func _find_color_rect(node_name: String) -> ColorRect:
	var n: Node = find_child(node_name, true, false)
	if n is ColorRect:
		return n
	return null
