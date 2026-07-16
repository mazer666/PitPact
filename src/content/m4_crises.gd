# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M4 Track C crisis catalogue.
#
# `M4Crises` is the canonical M4 crisis
# catalogue. The catalogue is an `Array`
# of `Dictionary` payloads (the
# `Crisis.make(...)` factory consumes
# them). The realm façade calls
# `M4Crises.all()` once at sim
# registration and stores the result
# via `Sim.register_crises(arr)`.
#
# The M4 closeout ships two crises
# (ADR-0011 §"The two M4 default
# crises"): `plague_outbreak` and
# `faction_dispute`. Both have
# `autonomous_resolution_days = 14.0`
# and three choices each. The
# `plague_outbreak` choices are
# `quarantine`, `seek_pactmaker`, and
# `burn_infected`; the
# `faction_dispute` choices are
# `mediate`, `side_lantern_clan`, and
# `side_ledger_cabal`.
class_name M4Crises
extends RefCounted

## The default autonomous-resolution
## deadline (in in-game days). The M4
## closeout pins this value; the per-
## crisis `autonomous_resolution_days`
## field is set to this constant.
const DEFAULT_AUTONOMOUS_RESOLUTION_DAYS: float = 14.0


## Return the full catalogue as an
## `Array[Dictionary]`. The method is
## the canonical "all M4 crises" entry
## point; the realm façade's M4 boot
## path calls this once and stores the
## result in `Sim.crises` (after
## `Crisis.make(...)`).
static func all() -> Array:
	var out: Array = []
	out.append(_plague_outbreak())
	out.append(_faction_dispute())
	return out


## The `plague_outbreak` crisis
## definition. Three choices: quarantine
## (morale -10, no deaths), seek_pactmaker
## (consumes one Pactmaker intervention,
## no morale hit), burn_infected (morale
## -20, no deaths but `-1` inhabitant
## from the affected list).
static func _plague_outbreak() -> Dictionary:
	return {
		"id": &"plague_outbreak",
		"trigger_at_day": 0.0,
		"condition": Callable(),
		"autonomous_resolution_days": DEFAULT_AUTONOMOUS_RESOLUTION_DAYS,
		"sealable": true,
		"pausable": true,
		"choices":
		[
			{
				"id": &"quarantine",
				"label": &"M4_CRISIS_PLAGUE_QUARANTINE",
				"summary": &"M4_CRISIS_PLAGUE_QUARANTINE_SUMMARY",
				"effect": Callable(),
				"is_default": true,
			},
			{
				"id": &"seek_pactmaker",
				"label": &"M4_CRISIS_PLAGUE_SEEK_PACTMAKER",
				"summary": &"M4_CRISIS_PLAGUE_SEEK_PACTMAKER_SUMMARY",
				"effect": Callable(),
				"is_default": false,
			},
			{
				"id": &"burn_infected",
				"label": &"M4_CRISIS_PLAGUE_BURN_INFECTED",
				"summary": &"M4_CRISIS_PLAGUE_BURN_INFECTED_SUMMARY",
				"effect": Callable(),
				"is_default": false,
			},
		],
	}


## The `faction_dispute` crisis
## definition. Three choices: mediate
## (no stance change), side_lantern_clan
## (lantern_clan +0.2, ledger_cabal -0.2),
## side_ledger_cabal (the inverse).
static func _faction_dispute() -> Dictionary:
	return {
		"id": &"faction_dispute",
		"trigger_at_day": 0.0,
		"condition": Callable(),
		"autonomous_resolution_days": DEFAULT_AUTONOMOUS_RESOLUTION_DAYS,
		"sealable": false,
		"pausable": true,
		"choices":
		[
			{
				"id": &"mediate",
				"label": &"M4_CRISIS_FACTION_MEDIATE",
				"summary": &"M4_CRISIS_FACTION_MEDIATE_SUMMARY",
				"effect": Callable(),
				"is_default": true,
			},
			{
				"id": &"side_lantern_clan",
				"label": &"M4_CRISIS_FACTION_SIDE_LANTERN",
				"summary": &"M4_CRISIS_FACTION_SIDE_LANTERN_SUMMARY",
				"effect": Callable(),
				"is_default": false,
			},
			{
				"id": &"side_ledger_cabal",
				"label": &"M4_CRISIS_FACTION_SIDE_LEDGER",
				"summary": &"M4_CRISIS_FACTION_SIDE_LEDGER_SUMMARY",
				"effect": Callable(),
				"is_default": false,
			},
		],
	}
