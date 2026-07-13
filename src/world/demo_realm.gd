# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — placeholder 12x12 demo realm.
#
# Track A will replace this with the real `TileMapLayer` and
# grid; while we wait for the merge, this stub paints a
# 12x12 isometric grid as a `Node2D` with a single
# `_draw()` callback. The grid is intentionally minimal: it
# exists so the camera, input, minimap, and diagnostics
# overlay can be exercised end-to-end before Track A lands.
#
# This file lives under src/world/ — the dependency-check
# script enforces that it does NOT import from src/ui/.
class_name DemoRealm
extends Node2D

## Tile dimensions in screen pixels. The ADR-0004 reference
## values are 64x32; we mirror them so the placeholder is
## already aligned with the real renderer that Track A
## will deliver.
const TILE_W: int = 64
const TILE_H: int = 32

## Grid size. The M1 stub is fixed at 12x12; Track A reads
## this from the realm façade.
const GRID_W: int = 12
const GRID_H: int = 12

## Optional reference to the realm façade. The M1 stub
## does not use it; Track A will, to project tile contents
## (biome, structure) onto the grid.
var realm: RefCounted = null


func _ready() -> void:
	# Force a redraw. The grid is data-driven, not animated,
	# so one redraw on boot is enough.
	queue_redraw()


## Public: set the realm façade. M2 will read the grid from
## the realm; M1 just stores the reference so the camera /
## minimap can find it.
func bind_realm(realm_ref: RefCounted) -> void:
	realm = realm_ref
	queue_redraw()


## The single draw call. Renders a 12x12 grid of diamond
## tiles. The colour is a constant; the per-tile data is
## not yet plumbed. Track A replaces this with a real
## `TileMapLayer` and we delete this script.
func _draw() -> void:
	# Background. A subtle dark blue that contrasts with
	# the diagnostics panel's black backdrop.
	var bg := Color(0.08, 0.10, 0.14, 1.0)
	draw_rect(Rect2(Vector2.ZERO, Vector2(GRID_W * TILE_W, GRID_H * TILE_H)), bg)

	# Grid lines. Each tile is a diamond; we draw the four
	# edges so the player can see tile boundaries.
	var line_color := Color(0.20, 0.22, 0.28, 1.0)
	for y in range(GRID_H + 1):
		var p1 := Vector2(0, y * TILE_H)
		var p2 := Vector2(GRID_W * TILE_W, y * TILE_H)
		draw_line(p1, p2, line_color, 1.0)
	for x in range(GRID_W + 1):
		var p1 := Vector2(x * TILE_W, 0)
		var p2 := Vector2(x * TILE_W, GRID_H * TILE_H)
		draw_line(p1, p2, line_color, 1.0)
