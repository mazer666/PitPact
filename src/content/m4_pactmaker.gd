# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M4 Track B Pactmaker catalogue.
#
# `M4Pactmaker` is the canonical M4
# Pactmaker carrier. The carrier is a
# `Pactmaker` with the M4-default
# `intervention_limit = 3` and three
# powers: `seal_breach`, `pause_crisis`,
# and `reveal_tile`. The realm façade
# calls `M4Pactmaker.build()` once at
# sim registration and stores the
# result via `Sim.register_pactmaker(p)`.
class_name M4Pactmaker
extends RefCounted

## The M4-default intervention limit per
## year. The constant is the canonical
## value the M4 design doc pins; the
## carrier's `intervention_limit` is
## always equal to this value.
const INTERVENTION_LIMIT_PER_YEAR: int = 3


## Build the canonical M4 Pactmaker.
## Each call returns a *new* `Pactmaker`
## instance with the M4 default powers
## and `intervention_limit`. The
## method is the canonical "new M4
## Pactmaker" entry point; tests use
## it to set up Pactmaker state
## without duplicating the catalogue
## logic.
static func build() -> Pactmaker:
	var p: Pactmaker = Pactmaker.new()
	p.id = &"m4_pactmaker"
	p.name = &"PACTMAKER_NAME"
	p.origin_id = &"m4_origin"
	p.intervention_limit = INTERVENTION_LIMIT_PER_YEAR
	p.intervention_count = 0
	p.powers = _powers()
	return p


## Build the three M4 powers. The
## powers' effects are `Callable`s that
## accept `(sim, time_days)` and return
## `bool`. The M4 closeout default
## effects are:
## - `seal_breach`: emit a
##   `crisis.resolved` event for the
##   first pending crisis with the
##   `sealable` flag.
## - `pause_crisis`: emit a
##   `crisis.paused` event for the
##   first pending crisis with the
##   `pausable` flag.
## - `reveal_tile`: reveal a 3-tile
##   radius around the realm's anchor.
static func _powers() -> Array:
	var out: Array = []
	out.append(_make_power(&"seal_breach", &"POWER_SEAL_BREACH_NAME", 1, 7, _effect_seal_breach))
	out.append(_make_power(&"pause_crisis", &"POWER_PAUSE_CRISIS_NAME", 1, 5, _effect_pause_crisis))
	out.append(_make_power(&"reveal_tile", &"POWER_REVEAL_TILE_NAME", 1, 0, _effect_reveal_tile))
	return out


## Power constructor.
static func _make_power(
	pid: StringName,
	pname: StringName,
	pcost: int,
	pcountdown: int,
	peffect: Callable,
) -> Power:
	var p: Power = Power.new()
	p.id = pid
	p.name = pname
	p.cost_interventions = pcost
	p.cooldown_days = pcountdown
	p.effect = peffect
	p._last_used_at_day = -1.0
	return p


## `seal_breach` effect. Walks the
## sim's pending crises and resolves the
## first `sealable` one. Returns `true`
## when a crisis was resolved, `false`
## otherwise.
static func _effect_seal_breach(sim: Variant, _time_days: float) -> bool:
	if sim == null:
		return false
	if sim.crises == null:
		return false
	# `sim.crises` is a `Dictionary` in
	# the canonical Sim; iterate over
	# values to get the crises.
	var crises_iter: Array = []
	if sim.crises is Dictionary:
		crises_iter = (sim.crises as Dictionary).values()
	elif sim.crises is Array:
		crises_iter = sim.crises
	for c in crises_iter:
		if c == null or not (c is Crisis):
			continue
		var cr: Crisis = c
		if cr.resolved:
			continue
		if bool(cr.data.get("sealable", false)):
			cr.resolved = true
			cr.chosen_id = &"sealed_by_pactmaker"
			return true
	return false


## `pause_crisis` effect. Walks the
## sim's pending crises and pauses the
## first `pausable` one (sets the
## `paused` flag). Returns `true` when
## a crisis was paused, `false`
## otherwise.
static func _effect_pause_crisis(sim: Variant, _time_days: float) -> bool:
	if sim == null:
		return false
	if sim.crises == null:
		return false
	var crises_iter: Array = []
	if sim.crises is Dictionary:
		crises_iter = (sim.crises as Dictionary).values()
	elif sim.crises is Array:
		crises_iter = sim.crises
	for c in crises_iter:
		if c == null or not (c is Crisis):
			continue
		var cr: Crisis = c
		if cr.resolved:
			continue
		if bool(cr.data.get("pausable", false)):
			cr.data["paused"] = true
			return true
	return false


## `reveal_tile` effect. Reveals a
## 3-tile radius around the realm's
## anchor in the sim's `exploration_map`.
## Returns `true` when the map is
## present, `false` otherwise.
static func _effect_reveal_tile(sim: Variant, _time_days: float) -> bool:
	if sim == null:
		return false
	if sim.exploration_map == null:
		return false
	if not (sim.exploration_map is ExplorationMap):
		return false
	var em: ExplorationMap = sim.exploration_map
	# The anchor is `sim.anchor` (a
	# `Vector2i`); the M4 closeout
	# default is "3-tile radius".
	var anchor: Vector2i = Vector2i(0, 0)
	if sim.anchor != null and sim.anchor is Vector2i:
		anchor = sim.anchor
	em.reveal_radius(anchor, 3)
	return true
