# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — the runtime biome data carrier (M3-foundation skeleton).
#
# `Biome` is the per-biome data carrier the M3 world
# generator (ADR-0007) emits and the realm façade, the
# renderer, and the inhabitants read. The on-disk
# definition of a biome lives in `src/content/biome_def.gd`
# (a `BiomeDef` resource, loaded by `ContentRegistry`); the
# `Biome` class is the runtime in-memory representation
# the generator and the realm use.
#
# The skeleton declares the public surface that M3
# cycle 2 (Track A) will fill in. The fields are:
#
#   * `id` — stable identity (`StringName`).
#   * `display_name` — locale key, resolved via `tr()`
#     at draw time (the runtime stores the key, the UI
#     resolves it; per §15 of `docs/requirements.md`).
#   * `burden` — a "hostility" measure in `[0.0, 1.0]`.
#     A high burden means the biome is harder to settle
#     (per §8 of `docs/requirements.md`); the M3 default
#     is `0.0` for friendly biomes and `1.0` for hostile
#     ones. The M3 cycle 2 (Track A) commit pins the
#     per-biome value against the `BiomeDef.resource_bias`
#     and `BiomeDef.hazard_bias` fields.
#   * `movement_modifier` — a multiplier on the per-tile
#     movement cost. `1.0` is the default; biomes that
#     impede movement (e.g. dense forests, deep water)
#     set a value > 1.0; biomes that ease movement
#     (e.g. open dunes) set a value < 1.0. The M3
#     default is `1.0`. The M3 cycle 2 (Track A) commit
#     pins the per-biome value.
#
# Per ADR-0002, this file does not import from `src/ui`,
# `src/sim`, `src/realm`, `src/save`, or `src/audit`. It
# imports from `src/core` and `src/content` only.
class_name Biome
extends RefCounted

## The biome's stable identity. `StringName` for the
## same reasons as `Tile.id` and `Inhabitant.id`: it
## survives the dictionary round-trip and identity
## comparisons are O(1) hashed lookups. The id is
## assigned once at construction and never changes.
## The save/load pipeline (ADR-0003) round-trips this
## value under `body.world.biomes[*].id`.
var id: StringName = &""

## Localised display name. The runtime stores the
## `StringName` *locale key* (per §15 of
## `docs/requirements.md`); the UI resolves it via
## `tr()` at draw time. The M3 default is an empty
## `StringName`; the generator's content-adapter
## step (M3 cycle 2, Track A) populates the value
## from the loaded `BiomeDef.display_name`.
var display_name: StringName = &""

## The biome's "hostility" measure. A `float` in
## `[0.0, 1.0]`; high values mean the biome is
## harder to settle. The M3 default is `0.0`
## (a friendly biome); the M3 cycle 2 (Track A)
## commit pins the per-biome value. ADR-0007's
## "low burden" Hearth constraint uses this field:
## the Hearth's tile has `biome.burden <=
## constraints.hearth_burden_max` (default `0.3`).
var burden: float = 0.0

## The per-tile movement-cost multiplier. A
## `float`; the M3 default is `1.0` (no change
## to the per-tile movement cost). Biomes that
## impede movement (e.g. dense forests) set a
## value > 1.0; biomes that ease movement (e.g.
## open dunes) set a value < 1.0. The M3 cycle 2
## (Track A) commit pins the per-biome value.
var movement_modifier: float = 1.0


## Default constructor. All fields default to
## their zero-equivalents; the generator's
## content-adapter step (M3 cycle 2, Track A)
## populates the values from the loaded
## `BiomeDef`.
func _init() -> void:
	id = &""
	display_name = &""
	burden = 0.0
	movement_modifier = 1.0


## Convenience factory. Equivalent to
## `Biome.new()` followed by field assignments,
## but reads more naturally at call sites. The
## generator's content-adapter step uses this
## factory.
static func make(
	p_id: StringName = &"",
	p_display_name: StringName = &"",
	p_burden: float = 0.0,
	p_movement_modifier: float = 1.0
) -> Biome:
	var b: Biome = Biome.new()
	b.id = p_id
	b.display_name = p_display_name
	b.burden = p_burden
	b.movement_modifier = p_movement_modifier
	return b


## Equality by value. Two biomes are equal iff
## they have the same `id`, the same
## `display_name`, the same `burden`, and the
## same `movement_modifier`. Used by the
## M3 cycle 2 (Track A) determinism test to
## assert the generator's biome catalogue is
## deep-equal across two runs of the same seed.
func equals(other: Biome) -> bool:
	if other == null:
		return false
	if id != other.id:
		return false
	if display_name != other.display_name:
		return false
	if not is_equal_approx(burden, other.burden):
		return false
	if not is_equal_approx(movement_modifier, other.movement_modifier):
		return false
	return true
