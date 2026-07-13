# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — Resource definition resource.
#
# A `ResourceDef` is the data-driven schema for a single resource
# category (e.g. stone, fungi, ember, memory). The four resource
# categories required by §10.1 — stone, food/medicine, knowledge,
# magical essence — are stored as `ResourceDef` instances under
# `res://data/resources/*.tres`. The runtime in `src/sim` (lands
# with M2) reads them; the realm façade exposes them to the UI
# through `ContentRegistry`.
#
# Per ADR-0002, `src/content` is data only; this class holds no
# behaviour beyond the `Resource` round-trip and the schema
# validator.
class_name ResourceDef
extends Resource

## Allowed category values, exposed as a static list so the
## validator and the UI agree. The list is the canonical
## reference for §10.1's "four resource categories" — adding
## a fifth is an M2+ content decision.
const ALLOWED_CATEGORIES: Array = ["stone", "food", "knowledge", "essence"]

## Stable id used for cross-references in saves, contracts, and
## room materials_cost dictionaries. MUST be a `StringName`.
@export var id: StringName = &""

## Localised display name. The runtime resolves this through
## `tr(...)` so the English literal never appears in `.gd` source.
@export var display_name: StringName = &""

## The four resource categories from §10.1. The category is a
## closed enum because the UI and the simulation branch on it
## (e.g. "is this consumed by a workshop?"). The values are:
##
##   "stone"   — raw material from the earth.
##   "food"    — food, medicine, comfort goods.
##   "knowledge" — research, secrets, memories.
##   "essence" — magical essence from places, events, or beings.
##
## Stored as `StringName` for the same `Dictionary`-key
## round-trip reason `id` is.
@export var category: StringName = &"stone"

## Base value per unit in abstract "value points". The UI shows
## this; the simulation uses it for the value-density estimate
## in the storage UI. The M1 number is provisional — the
## M2 simulation rebalances it.
@export var base_value: int = 1

## Decay rate per in-game day, expressed as a fraction of the
## stored amount (0.0 .. 1.0). `0.0` means "never decays"
## (e.g. stone); `0.05` means "5% of the stock spoils per day"
## (e.g. fresh fungi). The simulation multiplies this by the
## current stock; the value is clamped to a non-negative
## integer at the end of the tick.
@export var decay_rate: float = 0.0

## Free-form tag list. Tags include provenance hints
## (e.g. "organic", "mineral", "volatile"), gameplay hooks
## (e.g. "crafting_input"), and content-version markers
## (e.g. "m1_demo").
@export var tags: PackedStringArray = PackedStringArray()


## Validate the definition. Returns an empty array on success.
func validate() -> PackedStringArray:
	var errs := PackedStringArray()
	if String(id).is_empty():
		errs.append("ResourceDef.id is empty")
	if String(display_name).is_empty():
		errs.append("ResourceDef.display_name is empty")
	if not ALLOWED_CATEGORIES.has(String(category)):
		errs.append(
			(
				"ResourceDef.category '%s' is not one of %s"
				% [String(category), str(ALLOWED_CATEGORIES)]
			)
		)
	if base_value < 0:
		errs.append("ResourceDef.base_value is negative (%d)" % base_value)
	if decay_rate < 0.0 or decay_rate > 1.0:
		errs.append("ResourceDef.decay_rate (%f) is outside [0.0, 1.0]" % decay_rate)
	return errs
