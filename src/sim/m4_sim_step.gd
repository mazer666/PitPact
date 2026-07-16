# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M4-Closeout per-tick step helpers.
#
# `M4SimStep` is the static-only helper
# class the M4 Closeout's per-tick steps
# (7c — research/ritual, 7d — factions,
# 7e — autonomous conflict) delegate to.
# The helpers live in this file so the
# `sim.gd` file stays under the 1000-line
# cap the lint check enforces.
#
# The M4 closeout default is "delegation":
# the per-tick rule in `sim.gd` calls
# the static methods on this class, the
# static methods walk the sim's
# `knowledge_state`, `factions`, and
# `crises` dictionaries. The static
# methods are pure functions of their
# arguments (no carrier state).
class_name M4SimStep
extends RefCounted


## Per-tick faction stance drift. The
## method walks `sim.factions` and
## applies the sign-preserving drift
## (a faction that is friendly drifts
## more friendly; a faction that is
## hostile drifts more hostile). The
## drift is `0.01` per day; the cap
## is `[-1.0, 1.0]`. The method is a
## no-op when `sim.factions` is `null`
## or not an `Array`.
static func update_factions(sim: Variant, delta_days: float) -> void:
	if sim == null:
		return
	if sim.factions == null:
		return
	if not (sim.factions is Array):
		return
	for f in sim.factions as Array:
		if f == null or not (f is Faction):
			continue
		var fac: Faction = f
		var current: float = float(fac.stance.get("realm", 0.0))
		var drift: float = 0.01 * delta_days
		if current < 0.0:
			drift = -drift
		current += drift
		current = clamp(current, -1.0, 1.0)
		fac.stance["realm"] = current


## Per-tick autonomous conflict step.
## The method walks `sim.crises` and
## auto-resolves every
## triggered-but-unresolved crisis
## whose `autonomous_resolution_days`
## deadline has passed at `time_days`.
## The method is a no-op when
## `sim.crises` is empty.
static func evaluate_autonomous_conflicts(sim: Variant, time_days: float) -> void:
	if sim == null:
		return
	if sim.crises == null:
		return
	if not (sim.crises is Dictionary):
		return
	for cr in (sim.crises as Dictionary).values():
		if cr == null or not (cr is Crisis):
			continue
		var crisis_obj: Crisis = cr
		if not crisis_obj.is_autonomous_deadline_reached(time_days):
			continue
		crisis_obj.autonomous_resolve(time_days)


## Per-tick Pactmaker yearly reset.
## The method checks whether
## `time_days` is past the
## `_last_auto_resolve_day + 360`
## threshold; if so, the method
## resets the Pactmaker intervention
## counter. The M4 closeout default
## is "yearly reset" (every 360
## in-game days).
static func maybe_reset_pactmaker_yearly(sim: Variant, time_days: float) -> void:
	if sim == null:
		return
	if sim.pactmaker == null:
		return
	if not (sim.pactmaker is Pactmaker):
		return
	if time_days >= float(sim._last_auto_resolve_day) + 360.0:
		(sim.pactmaker as Pactmaker).reset_yearly_count()
		sim._last_auto_resolve_day = time_days
