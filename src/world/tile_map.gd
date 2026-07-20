# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — the TileMapLayer-based renderer for the grid.
#
# `WorldTileMapLayer` is a thin `TileMapLayer` (Godot 4.7+
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
## This is the M5-Foundation implementation: the
## layer maps the tile id to an atlas coordinate
## in the M5 TileSet (`assets/tiles/world_tileset.tres`,
## 8 tiles in a 4x2 grid of 16x16 cells). The
## M5-Foundation atlas is loaded by the editor's
## `.import` system (see `tools/assets/generate_assets.gd`).
## The M5 closeout can extend the atlas with the
## M5 content (six cultures, ten rooms).
##
## The tile id to atlas coord mapping is:
## 0 = floor_stone, 1 = floor_marsh, 2 = floor_highland,
## 3 = wall_stone, 4 = hearth, 5 = fog,
## 6 = floor_stone (variant), 7 = wall_stone (variant).
const _TILE_ATLAS_PATH: String = "res://assets/tiles/world_tileset.tres"


## Map a tile id to an atlas coordinate. The mapping
## is pinned in the test
## `test_world_tile_map_atlas_mapping` (regression
## net for the M5-Foundation atlas layout).
## M5-Closeout Bucket 2: the atlas is now
## 4x3 = 12 cells (4 new rooms: shrine, forge,
## well, trap). The mapping is
## `(tile_id % 4, tile_id / 4)` — tiles 0..3 in
## row 0, 4..7 in row 1, 8..11 in row 2.
func tile_id_to_atlas_coord(tile_id: int) -> Vector2i:
	# The atlas is 4x3 = 12 cells. Tiles 0..3
	# in row 0, 4..7 in row 1, 8..11 in row 2.
	return Vector2i(tile_id % 4, int(tile_id / 4))


## Bind the M5 TileSet to this layer. The M5-Foundation
## uses the procedural TileSet at
## `assets/tiles/world_tileset.tres`; the M5 closeout
## can swap in a hand-drawn TileSet without touching
## the layer's `set_grid` body.
func bind_tileset() -> void:
	var ts: TileSet = load(_TILE_ATLAS_PATH)
	if ts != null:
		tile_set = ts


## This is the M5-Foundation implementation: the
## layer writes a single cell per tile. The M1 stub
## used a single-row atlas; the M5 atlas is a
## 4x2 grid of 16x16 cells.
func set_grid(grid: Grid) -> void:
	if grid == null:
		return
	# Bind the M5 TileSet on first use. The bind
	# is idempotent (TileMapLayer.tile_set = X is
	# a no-op when X is already set).
	if tile_set == null:
		bind_tileset()
	# Clear the previous state. `clear()` is the
	# TileMapLayer API to drop every cell.
	clear()
	for y in range(grid.h):
		for x in range(grid.w):
			var tile: Tile = grid.tile_at(x, y)
			if tile == null:
				continue
			var atlas_coord: Vector2i = tile_id_to_atlas_coord(tile.id)
			set_cell(Vector2i(x, y), 0, atlas_coord)


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
