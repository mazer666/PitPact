# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — Culture definition resource (M2 Track A).
#
# A `CultureData` is the data-driven schema for a
# single creature culture. The M2 Track A commit
# ships the *minimal* schema the M2 integration
# test (test_inhabitant_lifecycle.gd) needs: `id`,
# `display_name`, `body_form`, `values`. The M5
# cultures pass extends the schema with the
# gameplay-side fields (profession family, room
# height preference, conflict pattern, …) that the
# per-culture `*Culture` classes in
# `src/sim/cultures/*.gd` already expose in code.
#
# The `CultureData` is loaded by the realm
# façade's content loader from
# `res://data/cultures/*.tres` and is the bridge
# between the content data and the runtime in
# `src/sim/cultures/*.gd`. The M2 Track A
# integration test exercises the bridge end-to-
# end; the M5 commit replaces this minimal
# schema with the full one.
#
# Per ADR-0002, this file lives in `src/content/`
# and has no `src/ui`, `src/realm`, or `src/save`
# imports.
class_name CultureData
extends Resource

## Stable id used for content lookup and for
## cross-references in saves. MUST be a
## `StringName` so it can be used as a
## `Dictionary` key without conversion. The id
## is what `Inhabitant.culture` references; the
## bridge in `src/sim/cultures/lanternbearer.gd`
## (and the M5 sibling stubs) maps the id to
## the runtime class.
@export var id: StringName = &""

## Localised display name. The `.tres` file
## stores the `StringName` lookup key; the
## runtime resolves it against the active
## locale via `tr(...)` so the English literal
## never appears in `.gd` source.
@export var display_name: StringName = &""

## Localised body-form description. The UI's
## body-form renderer (M5+) resolves this key.
@export var body_form: StringName = &""

## The culture's core values, as a
## `PackedStringArray` of locale keys. The M2
## Track A schema accepts an arbitrary list;
## the M5 commit narrows the field to the
## canonical "primary + secondary" pair.
@export var values: PackedStringArray = PackedStringArray()


## Validate the definition against the M2
## Track A contract. Returns an empty
## `PackedStringArray` on success, or a list
## of human-readable error messages. The
## validator is a single place to land schema
## rules so a `.tres` file with a bad `id`
## (empty `StringName`) fails fast with a
## useful error message.
func validate() -> PackedStringArray:
	var errs := PackedStringArray()
	if String(id).is_empty():
		errs.append("CultureData.id is empty; expected a non-empty StringName")
	if String(display_name).is_empty():
		errs.append(
			(
				"CultureData.display_name is empty; expected a StringName key into"
				+ " locales/source_strings.csv"
			)
		)
	return errs
