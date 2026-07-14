# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — contract definition resource.
#
# A `ContractDef` is the data-driven schema for a
# single contract template (e.g. the standard pact).
# M2 Track B ships the standard pact; the M5 content
# pass adds specialist pacts (apprenticeship, mercenary,
# scholarly loan, …).
#
# The class is loaded from `res://data/contracts/*.tres`
# by `ContentRegistry` and is the contract between
# content data and the runtime in `src/sim/contract.gd`.
# Per ADR-0002, `src/content` is data only; this class
# holds no behaviour beyond the `Resource` round-trip
# and the schema validator.
class_name ContractDef
extends Resource

## Stable id used for content lookup and for cross-
## references in saves. MUST be a `StringName`.
@export var id: StringName = &""

## Localised display name. The `.tres` file stores the
## `StringName` lookup key; the runtime resolves it
## against the active locale via `tr(...)`.
@export var display_name: StringName = &""

## The contract's clause set, as a `Dictionary`. The
## standard pact's keys are:
##   * `lodging: bool`                 — the realm
##                                       must house
##                                       the
##                                       inhabitant.
##   * `food_share: bool`              — the realm
##                                       must feed
##                                       the
##                                       inhabitant.
##   * `labour_hours_per_day: int`     — the
##                                       inhabitant's
##                                       daily labour
##                                       obligation.
##   * `breach_consequence: StringName`— the
##                                       consequence
##                                       tag the
##                                       `contract.breach`
##                                       event carries
##                                       in its
##                                       `breach_consequence`
##                                       field.
## Content-defined pacts may add more keys; the
## simulator only evaluates the keys the per-tick rule
## knows about.
@export var terms: Dictionary = {}


## Validate the definition. Returns an empty array on
## success, a list of human-readable errors otherwise.
func validate() -> PackedStringArray:
	var errs := PackedStringArray()
	if String(id).is_empty():
		errs.append("ContractDef.id is empty; expected a non-empty StringName")
	if String(display_name).is_empty():
		(
			errs
			. append(
				"ContractDef.display_name is empty; expected a StringName key into locales/source_strings.csv"
			)
		)
	if terms.is_empty():
		errs.append("ContractDef.terms is empty; expected at least one clause")
		return errs
	# Standard-pact contract. Other pcts may add keys;
	# these are the keys the standard pact is required
	# to carry.
	if not terms.has(&"lodging"):
		errs.append("ContractDef.terms is missing required key 'lodging' (bool)")
	if not terms.has(&"food_share"):
		errs.append("ContractDef.terms is missing required key 'food_share' (bool)")
	if not terms.has(&"labour_hours_per_day"):
		errs.append("ContractDef.terms is missing required key 'labour_hours_per_day' (int)")
	if not terms.has(&"breach_consequence"):
		errs.append("ContractDef.terms is missing required key 'breach_consequence' (StringName)")
	return errs
