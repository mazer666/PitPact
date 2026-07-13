# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — the TileMapLayer-based renderer for the grid.
#
# `WorldTileMapLayer` is a thin `TileMapLayer` (Godot 4.3
# API) that projects a `Grid` onto the screen. It owns
# no game state; it reads the realm façade and projects.
# The layer is a child of the realm scene and lives
# behind the UI shell.
#
# Per ADR-0002, this file does not import from `src/ui`
# or `src/sim` or `src/realm`. It imports from
# `src/world` (for `Grid` and `WorldCoordinates`) only.
# The TileMapLayer node itself is a Godot scene-tree
# primitive, not a `src/ui/` symbol.
class_name WorldTileMapLayer
extends TileMapLayer


## Set the grid this layer renders. The grid's `w`,
## `h`, and `tile.id` are read; the layer rebuilds its
## atlas cells to match. The rebuild is atomic from the
## renderer's point of view (the previous frame's state
## is dropped only when the new state is in place) so
## the player never sees a half-updated grid.
##
## This is the M1 implementation: the layer writes a
## single cell per tile. M2+ will swap in a multi-layer
## atlas for terrain + features.
func set_grid(grid: Grid) -> void:
	if grid == null:
		return
	# Clear the previous state. `clear()` is the
	# TileMapLayer API to drop every cell.
	clear()
	for y in range(grid.h):
		for x in range(grid.w):
			var tile: Tile = grid.tile_at(x, y)
			if tile == null:
				continue
			# Map the tile id to an atlas coordinate.
			# The M1 atlas is a single 0..7 column;
			# the renderer is intentionally simple.
			var atlas_coord: Vector2i = Vector2i(tile.id % 8, 0)
			set_cell(Vector2i(x, y), 0, atlas_coord, 0)  # source_id  # alternative_tile


## Convert a screen position (from a mouse event) to a
## tile coordinate. Pure pass-through to
## `WorldCoordinates.world_to_tile` after converting
## from layer-local to world coordinates.
func screen_to_tile(screen_pos: Vector2) -> Vector2i:
	var world_pos: Vector2 = to_global(screen_pos)
	return WorldCoordinates.world_to_tile(world_pos)


## Inverse: tile to world (in layer-local coordinates).
func tile_to_local(tile: Vector2i) -> Vector2:
	return WorldCoordinates.tile_to_world(tile)
