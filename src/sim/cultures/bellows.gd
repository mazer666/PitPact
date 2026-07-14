# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — Bellows culture stub.
#
# The Bellows is one of the six original cultures the
# M5 release ships. The M2 Track A commit ships this
# as a *stub* — the identifying data (id, display
# name) is pinned, but the per-tick behaviour lands
# with the M5 cultures pass.
#
# The name is provisional; the final name lands at
# the M5 cultures pass. The M5 commit replaces this
# stub with a real `BellowsCulture` class.
#
# Per ADR-0002, this file does not import from
# `src/ui`, `src/realm`, or `src/save`. It imports
# from `src/core` only.
class_name BellowsCulture
extends RefCounted

## The culture's stable id, used as the
## `Inhabitant.culture` field value and as the
## `data/cultures/bellows.tres` file's `id`
## key.
const CULTURE_ID: StringName = &"bellows"

## The culture's localised display name, as
## a `StringName` that is a *locale key* (see
## `docs/localization.md` §"Naming"). The M5
## cultures pass adds the row to
## `locales/source_strings.csv`.
const DISPLAY_NAME: StringName = &"CREATURE_BELLOWS_NAME"


## The Bellows' identifying data as a plain
## `Dictionary`. M5 fleshes this out; the M2
## stub ships the two canonical fields.
func info() -> Dictionary:
	return {
		"id": CULTURE_ID,
		"display_name": DISPLAY_NAME,
	}


## The Bellows' per-tick morale/stress bias
## hook. M2's stub is a `pass`; M5 fills in
## the per-culture tilt. The signature is
## pinned now so M5 does not change the call
## site.
func apply_bias(_morale: Morale, _delta_days: float) -> void:
	# M2 STUB: M5 cultures pass replaces
	# this with the per-culture morale /
	# stress tilt. The signature is pinned
	# so the sim's step 2 call site does not
	# change between M2 and M5.
	pass
