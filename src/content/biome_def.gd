# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — Biome definition resource.
#
# A `BiomeDef` is the data-driven schema for one biome. The
# M1 release ships two biomes (Hollow and Dustmaze); they
# land under `res://data/biomes/*.tres` and are loaded by
# `ContentRegistry`. The generator in `src/world` (lands
# with M3) reads them; the UI uses the `palette_hint` and
# `narrative_anchor` to render the world.
#
# Per ADR-0002, `src/content` is data only; this class holds
# no behaviour beyond the `Resource` round-trip and the
# schema validator.
class_name BiomeDef
extends Resource

## Stable id used for cross-references in saves and the
## generator. MUST be a `StringName`.
@export var id: StringName = &""

## Localised display name. Resolved through `tr(...)` at
## runtime; the English literal lives in
## `locales/source_strings.csv`.
@export var display_name: StringName = &""

## Palette hint is a short identifier the renderer reads to
## pick the right texture set / colour ramp. The value is a
## `StringName` so the dictionary look-up in the renderer is
## a direct key match. Examples: "stone_dark", "sand_pale".
@export var palette_hint: StringName = &""

## Resource bias is the relative weighting the generator uses
## to pick resources in this biome. Keys are `ResourceDef.id`
## values (e.g. `&"stone"`), values are non-negative floats
## (relative weights, not absolute rates). The generator
## normalises the weights at load time.
@export var resource_bias: Dictionary = {}

## Hazard bias is the list of hazard tags most common in
## this biome. The simulation rolls hazards from this list
## at the biome's hazard density; M3 closes the loop on
## the actual hazard resolution.
@export var hazard_bias: PackedStringArray = PackedStringArray()

## Localised narrative anchor — a one-sentence story hook
## the UI shows when the player first enters the biome.
@export var narrative_anchor: StringName = &""


## Validate the definition. Returns an empty array on success.
func validate() -> PackedStringArray:
	var errs := PackedStringArray()
	if String(id).is_empty():
		errs.append("BiomeDef.id is empty")
	if String(display_name).is_empty():
		errs.append("BiomeDef.display_name is empty")
	if String(palette_hint).is_empty():
		errs.append("BiomeDef.palette_hint is empty")
	for k in resource_bias.keys():
		var v: Variant = resource_bias[k]
		if not (v is int) and not (v is float):
			errs.append("BiomeDef.resource_bias[%s] is not a number" % str(k))
			break
		if float(v) < 0.0:
			errs.append("BiomeDef.resource_bias[%s] is negative" % str(k))
			break
	return errs
