# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — exploration-step helper for `Sim` (M3 cycle 2 Track A).
#
# The exploration step is the per-tick work `Sim` does when an
# `ExplorationMap` is registered. The step is intentionally small
# and pure: it picks a living inhabitant, picks the nearest
# unrevealed tile to the Hearth, moves the inhabitant, reveals
# the destination's `2`-Manhattan neighbourhood, and appends an
# `exploration.revealed` event to the event log.
#
# Per ADR-0002, this file imports from `src/core`,
# `src/world`, and `src/sim` only.
class_name ExplorationStep
extends RefCounted


## Run one exploration step. The function is a pure function
## on `sim.time_days`, `sim.event_log`, `inhabitants`, and
## `exploration_map`. Returns `true` if a tile was
## successfully explored; `false` if the step was a no-op.
static func run(
	sim, delta_days: float, inhabitants: Array, exploration_map_v, advance_time: bool
) -> bool:
	if exploration_map_v == null:
		if advance_time:
			sim.time_days += delta_days
		return false
	if not (exploration_map_v is ExplorationMap):
		if advance_time:
			sim.time_days += delta_days
		return false
	var emap: ExplorationMap = exploration_map_v
	if emap.is_fully_revealed():
		if advance_time:
			sim.time_days += delta_days
		return false
	# Pick a living inhabitant.
	var mover: Variant = null
	for inh in inhabitants:
		if inh == null:
			continue
		if not (inh is Inhabitant):
			continue
		if int((inh as Inhabitant).state) != Inhabitant.STATE_ALIVE:
			continue
		mover = inh
		break
	if mover == null:
		if advance_time:
			sim.time_days += delta_days
		return false
	# Pick the nearest unrevealed tile to the Hearth.
	var origin: Vector2i = emap.home_position
	if origin.x < 0 or origin.y < 0:
		origin = (mover as Inhabitant).position
	var target_v: Variant = emap.nearest_unrevealed(origin)
	if target_v == null:
		if advance_time:
			sim.time_days += delta_days
		return false
	var target: Vector2i = target_v
	# Move the inhabitant.
	(mover as Inhabitant).position = target
	# Reveal the 2-Manhattan neighbourhood around the
	# destination.
	var newly_revealed: Array = emap.reveal(target, 2)
	# The per-tile cost. The default exploration rate
	# (one inhabitant-tile per in-game day) corresponds
	# to `movement_modifier = 1.0`.
	var mm: float = 1.0
	var cost: float = 1.0 / max(0.1, mm)
	# Append the exploration event.
	var post_time: float = sim.time_days + (delta_days if advance_time else cost)
	var entry: Dictionary = {
		"id": StringName("exploration.revealed.%d" % int(round(post_time * 1000.0))),
		"time_days": post_time,
		"kind": &"exploration.revealed",
		"summary": &"EVENT_EXPLORATION_REVEALED",
		"affected": PackedStringArray([String((mover as Inhabitant).id)]),
		"inhabitant_id": (mover as Inhabitant).id,
		"target": target,
		"radius": 2,
		"newly_revealed_count": newly_revealed.size(),
		"newly_revealed": newly_revealed,
		"cost_days": cost,
	}
	sim.event_log.append(entry)
	if advance_time:
		sim.time_days += delta_days
	return true
