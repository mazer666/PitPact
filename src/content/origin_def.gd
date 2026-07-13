# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — Pactmaker origin definition resource.
#
# An `OriginDef` is the data-driven schema for a Pactmaker
# origin (the player's initial identity, §5 of the requirements
# spec). M1 ships two — `Scholar` and `Warden` — under
# `res://data/origins/*.tres`. The realm façade reads them at
# campaign creation time and exposes them to the UI through
# `ContentRegistry`.
#
# Naming is provisional; the final culture-aligned names land
# with the M5 cultures pass. The id (`&"scholar"`, `&"warden"`)
# is the stable cross-version handle.
#
# Per ADR-0002, `src/content` is data only; this class holds
# no behaviour beyond the `Resource` round-trip and the
# schema validator.
class_name OriginDef
extends Resource

## Stable id used for cross-references in saves and the
## title-screen UI. MUST be a `StringName`.
@export var id: StringName = &""

## Localised display name. Resolved through `tr(...)`.
@export var display_name: StringName = &""

## The Pactmaker powers the origin starts with. Each entry
## is a `StringName` power id; the simulation looks the power
## up in `data/research/...` (lands with M4). For M1 the list
## is a placeholder; the M4 milestone wires the actual
## resolution.
@export var starting_powers: PackedStringArray = PackedStringArray()

## Preferred culture ids — which inhabitant cultures the
## origin's "starts trusted" rule applies to. The ids are
## `CultureDef.id` values; the final culture names land
## with the M5 cultures pass, so the M1 values are
## placeholders (`&"scholar_tradition"`, `&"warden_culture"`).
@export var preferred_cultures: PackedStringArray = PackedStringArray()

## Weakness is a single `StringName` power id (or tag) the
## simulation uses to bias events against the origin. A
## `Scholar`'s `&"duelist"` weakness means the simulation is
## more likely to put the player in a duel they would
## rather negotiate out of.
@export var weakness: StringName = &""

## Localised narrative anchor — the one-sentence "who are
## you?" the title screen shows beneath the origin name.
@export var narrative_anchor: StringName = &""


## Validate the definition. Returns an empty array on success.
func validate() -> PackedStringArray:
	var errs := PackedStringArray()
	if String(id).is_empty():
		errs.append("OriginDef.id is empty")
	if String(display_name).is_empty():
		errs.append("OriginDef.display_name is empty")
	if String(weakness).is_empty():
		errs.append("OriginDef.weakness is empty; expected a StringName power id or tag")
	if String(narrative_anchor).is_empty():
		errs.append("OriginDef.narrative_anchor is empty")
	return errs
