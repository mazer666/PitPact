# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — minimap controller.
#
# The minimap is a top-right, fixed-aspect panel that
# renders the explored grid as a coarse bitmap. The M1
# implementation is a stub: it draws a 12x12 grid of
# coloured rectangles using a 4-pixel-per-tile scale, and
# the colour reflects the tile's `ZonePurpose`. The M2
# realm façade plugs in; M3 / M4 wire the explored-grid
# mask. Click-to-jump is wired to the main controller's
# `camera.center_on(world_pos)`.
class_name MinimapController
extends CanvasLayer

## Pixel size of a single minimap cell. The M1 stub uses
## a 4-pixel cell so a 12x12 grid fits in a 48x48 panel.
const CELL_PX: int = 4

## Number of cells per side for the M1 placeholder grid.
## Track A replaces this with a real read of the world
## bounds.
const GRID_SIZE: int = 12

## Reference to the camera. Click-to-jump routes the
## click through `camera.center_on(world_pos)`. Public
## so the main scene controller can inject the camera
## after instantiation.
var camera: IsometricCamera = null

## Reference to the main controller. Used only to read
## the reduced-motion flag.
var main_controller: MainSceneController = null

## Panel size derived from the grid. The minimap's
## Container is anchored to top-right; we set the size in
## `_ready()` so the panel does not depend on the .tscn
## being perfectly laid out.
var _panel_size: Vector2

## The custom-draw Control. The minimap draws via the
## engine's `_draw()` callback on a `Control` so the
## CanvasLayer does not have to do the heavy lifting.
var _draw_control: Control


## Public toggle. The main controller calls this on M.
func toggle() -> void:
	visible = not visible


## Setup: create the draw Control if the .tscn did not
## provide one, set the panel size, and apply localized
## labels. The .tscn is responsible for positioning the
## panel in the top-right; we only own the contents.
func _ready() -> void:
	_panel_size = Vector2(GRID_SIZE * CELL_PX, GRID_SIZE * CELL_PX)
	_draw_control = _find_control("MinimapDraw")
	if _draw_control != null:
		_draw_control.custom_minimum_size = _panel_size
		_draw_control.size = _panel_size
		_draw_control.queue_redraw()
		# The GUI input is on the draw Control, not on the
		# CanvasLayer. The .tscn may already have wired it;
		# we re-wire defensively.
		if not _draw_control.gui_input.is_connected(_on_gui_input):
			_draw_control.gui_input.connect(_on_gui_input)

	var header: Label = _find_label("MinimapHeader")
	if header != null:
		header.text = tr("MINIMAP_TOGGLE")


## Click-to-jump: when the player clicks the minimap, the
## camera centres on the corresponding world position.
## The M1 stub uses a simple linear mapping from cell
## (gx, gy) to world position. Track A replaces the
## mapping with the proper isometric conversion.
func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_handle_click(mb.position)


## Translate a minimap-local click position to a world
## position and call the camera's `center_on` entry point.
## The mapping is intentionally naive (M1) — the real
## conversion comes from `src/world/coordinates.gd` via
## the realm façade.
func _handle_click(local_pos: Vector2) -> void:
	if camera == null or _draw_control == null:
		return
	var rect: Rect2 = _draw_control.get_rect()
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	# Map local_pos (in the draw-control's local space) to
	# a grid cell.
	var gx: int = clampi(int(local_pos.x / CELL_PX), 0, GRID_SIZE - 1)
	var gy: int = clampi(int(local_pos.y / CELL_PX), 0, GRID_SIZE - 1)
	# Convert grid cell to a world-space anchor. The M1 stub
	# uses a 64x32 isometric tile (ADR-0004 reference), so
	# the world anchor for cell (gx, gy) is (gx*64, gy*32).
	var world_anchor: Vector2 = Vector2(gx * 64.0, gy * 32.0)
	camera.center_on(world_anchor)


func _find_control(node_name: String) -> Control:
	var n: Node = find_child(node_name, true, false)
	if n is Control:
		return n
	return null


func _find_label(node_name: String) -> Label:
	var n: Node = find_child(node_name, true, false)
	if n is Label:
		return n
	return null
