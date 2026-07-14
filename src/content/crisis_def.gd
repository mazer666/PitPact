# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — crisis definition resource.
#
# A `CrisisDef` is the data-driven schema for a
# single crisis template (e.g. `FirstInspection`).
# M2 Track B ships the first inspection crisis;
# the M3+ content pass adds more.
#
# The class is loaded from `res://data/events/*.tres`
# by `ContentRegistry` and is the contract between
# content data and the runtime in
# `src/sim/crisis.gd`. Per ADR-0002, `src/content`
# is data only; this class holds no behaviour
# beyond the `Resource` round-trip and the schema
# validator.
class_name CrisisDef
extends Resource

## Stable id used for content lookup and for
## cross-references in saves. MUST be a
## `StringName`.
@export var id: StringName = &""

## Localised display name. The `.tres` file
## stores the `StringName` lookup key; the
## runtime resolves it against the active locale
## via `tr(...)`.
@export var display_name: StringName = &""

## The in-game day the crisis is scheduled to
## trigger. The sim's per-tick rule uses this
## value to build the `Crisis.trigger_at_day`
## at construction time.
@export var trigger_at_day: float = 0.0

## The crisis's player choices, as an `Array` of
## `Dictionary` records. Each choice has the
## canonical keys `id` (StringName), `display_name`
## (StringName locale key), and
## `consequence_summary` (StringName locale key
## for the event-log summary). The runtime
## `Crisis` adds an `effect` Callable when it
## copies the choice; the `.tres` file does not
## carry `effect` Callables (the runtime wires
## them based on the choice's id).
@export var choices: Array = []


## Validate the definition. Returns an empty
## array on success, a list of human-readable
## errors otherwise.
func validate() -> PackedStringArray:
	var errs := PackedStringArray()
	if String(id).is_empty():
		errs.append("CrisisDef.id is empty; expected a non-empty StringName")
	if String(display_name).is_empty():
		(
			errs
			. append(
				"CrisisDef.display_name is empty; expected a StringName key into locales/source_strings.csv"
			)
		)
	if trigger_at_day < 0.0:
		errs.append("CrisisDef.trigger_at_day is negative (%f); must be >= 0.0" % trigger_at_day)
	if choices.is_empty():
		errs.append("CrisisDef.choices is empty; expected at least one choice")
		return errs
	for i in choices.size():
		var c: Variant = choices[i]
		if not (c is Dictionary):
			errs.append("CrisisDef.choices[%d] is not a Dictionary" % i)
			continue
		if not c.has("id"):
			errs.append("CrisisDef.choices[%d] is missing required key 'id'" % i)
		if not c.has("display_name"):
			errs.append("CrisisDef.choices[%d] is missing required key 'display_name'" % i)
		if not c.has("consequence_summary"):
			errs.append("CrisisDef.choices[%d] is missing required key 'consequence_summary'" % i)
	return errs
