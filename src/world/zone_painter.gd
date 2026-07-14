# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — drag-paint zone tool.
#
# `ZonePainterTool` is a `Node2D` that listens for
# `ui_paint` (the input action registered in
# `project.godot` for Track B) and drag-paints a
# rectangular zone with the mouse. The tool is a thin
# shim over the realm façade: it holds a reference to a
# `Realm` and forwards `paint_zone` calls.
#
# The tool snaps to tile boundaries (the painter's
# algorithm uses `WorldCoordinates.world_to_tile`) and
# shows a translucent overlay while painting so the
# player can see the rect before committing.
#
# Per ADR-0002, this file does not import from `src/ui`
# or `src/sim`. It imports from `src/core`, `src/world`,
# and `src/realm` only.
class_name ZonePainterTool
extends Node2D

## Overlay colour while painting.
const _OVERLAY_COLOR: Color = Color(0.9, 0.5, 0.2, 0.35)

## The realm façade this tool paints into. Set via
## `bind_realm`. The tool is inert until a realm is
## bound.
var realm: RefCounted

## The `TileMapLayer` this tool queries for tile
## coordinates. The tool needs the layer's
## `screen_to_tile` to convert mouse events to tiles.
## `null` until `bind_tile_map` is called.
var tile_map: RefCounted

## The zone purpose the tool paints. The M1 minimum is
## `ZonePurpose.HEARTH`; the painter defaults to that.
var purpose: int = 2  # ZoneOps.ZonePurpose.HEARTH

## The current drag rect in tile coordinates. The
## overlay is drawn from this rect.
var _drag_start: Vector2i = Vector2i(-1, -1)

## End corner of the current drag rect in tile
## coordinates. See `_drag_start`.
var _drag_end: Vector2i = Vector2i(-1, -1)

## True while a drag is in progress.
var _is_painting: bool = false


## Bind the realm façade. The tool is inert until a
## realm is bound.
func bind_realm(p_realm: RefCounted) -> void:
	realm = p_realm


## Bind the `TileMapLayer` whose `screen_to_tile` the
## tool uses to convert mouse events to tile
## coordinates.
func bind_tile_map(p_tile_map: Node) -> void:
	tile_map = p_tile_map


## Start a paint at the given screen position. The
## position is converted to a tile via the bound
## `TileMapLayer`.
func start_paint(screen_pos: Vector2) -> void:
	if realm == null or tile_map == null:
		return
	var t: Vector2i = tile_map.screen_to_tile(screen_pos)
	_drag_start = t
	_drag_end = t
	_is_painting = true
	queue_redraw()


## Update the drag end position. The tool recomputes
## the overlay rect on every move.
func update_paint(screen_pos: Vector2) -> void:
	if not _is_painting:
		return
	if tile_map == null:
		return
	var t: Vector2i = tile_map.screen_to_tile(screen_pos)
	_drag_end = t
	queue_redraw()


## Commit the drag rect to the realm. Paints the rect
## with the configured `purpose` and resets the drag
## state.
func end_paint() -> void:
	if not _is_painting:
		return
	_is_painting = false
	if realm == null:
		queue_redraw()
		return
	var rect: Rect2i = _current_rect()
	if rect.size.x <= 0 or rect.size.y <= 0:
		queue_redraw()
		return
	realm.paint_zone(rect, purpose)
	queue_redraw()


## Cancel the current drag without painting.
func cancel_paint() -> void:
	_is_painting = false
	_drag_start = Vector2i(-1, -1)
	_drag_end = Vector2i(-1, -1)
	queue_redraw()


## The current drag rect, normalised so `position` is
## the top-left and `size` is positive.
func _current_rect() -> Rect2i:
	if not _is_painting:
		return Rect2i(0, 0, 0, 0)
	var x0: int = mini(_drag_start.x, _drag_end.x)
	var y0: int = mini(_drag_start.y, _drag_end.y)
	var x1: int = maxi(_drag_start.x, _drag_end.x)
	var y1: int = maxi(_drag_start.y, _drag_end.y)
	return Rect2i(Vector2i(x0, y0), Vector2i(x1 - x0 + 1, y1 - y0 + 1))


## Draw the overlay. The painter renders a translucent
## rectangle in screen space (via the layer's
## `tile_to_local` to convert tile to local
## coordinates).
func _draw() -> void:
	if not _is_painting:
		return
	if tile_map == null:
		return
	var rect: Rect2i = _current_rect()
	if rect.size.x <= 0 or rect.size.y <= 0:
		return
	var top_left: Vector2 = tile_map.tile_to_local(rect.position)
	var tile_w: int = 256
	var tile_h: int = 128
	var size: Vector2 = Vector2(rect.size.x * tile_w, rect.size.y * tile_h)
	draw_rect(Rect2(top_left, size), _OVERLAY_COLOR)


## Input handling. The tool listens for the `ui_paint`
## action (Track B's input map). We use
## `_unhandled_input` so focused UI controls (text
## fields, sliders) can still receive their events.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_paint"):
		# `is_action_pressed` does not carry a
		# position; we read the mouse position from
		# the viewport. The TouchScreen action
		# (also bound to `ui_paint`) carries a
		# position; the mouse path is the
		# desktop-only branch.
		var mouse_pos: Vector2 = get_global_mouse_position()
		start_paint(mouse_pos)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseMotion and _is_painting:
		update_paint(event.position)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_released("ui_paint"):
		end_paint()
		get_viewport().set_input_as_handled()
		return
