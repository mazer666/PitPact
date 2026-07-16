# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M4 Track C faction catalogue.
#
# `M4Factions` is the canonical M4 faction
# catalogue. The catalogue is an `Array`
# of `Faction` instances; the realm
# façade calls `M4Factions.all()` once at
# sim registration and stores the result
# via `Sim.register_factions(arr)`.
#
# The M4 closeout ships three factions
# (lantern_clan, ledger_cabal,
# hollow_church) with the M4 default
# starting stance of "neutral" toward
# the realm. The per-tick rule walks the
# factions and applies
# `Faction.update_stance(...)` based on
# the sim's crisis / Pactmaker activity.
class_name M4Factions
extends RefCounted


## Return the full catalogue as an
## `Array[Faction]`. The method is the
## canonical "all factions" entry point.
static func all() -> Array:
	var out: Array = []
	out.append(_make(&"lantern_clan", &"FACTION_LANTERN_CLAN_NAME", 0.0))
	out.append(_make(&"ledger_cabal", &"FACTION_LEDGER_CABAL_NAME", 0.0))
	out.append(_make(&"hollow_church", &"FACTION_HOLLOW_CHURCH_NAME", 0.0))
	return out


## Look up a single faction by id.
## Returns `null` when the id is
## unknown.
static func by_id(id: StringName) -> Faction:
	for f in all():
		if f == null:
			continue
		if f.id == id:
			return f
	return null


## Faction constructor. The
## `initial_stance` is the starting
## stance toward the realm (`-1.0` =
## hostile, `0.0` = neutral, `1.0` =
## friendly). The M4 closeout default
## is `0.0` (neutral) for all three
## factions.
static func _make(fid: StringName, fname: StringName, initial_stance: float) -> Faction:
	var f: Faction = Faction.new()
	f.id = fid
	f.name = fname
	f.stance = {"realm": initial_stance}
	return f
