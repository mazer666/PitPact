# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M4 Track A ritual catalogue.
#
# `M4Rituals` is the canonical M4 ritual
# node catalogue. The catalogue is a
# `Dictionary[StringName, ResearchNode]`;
# the realm façade calls
# `M4Rituals.all()` once at sim
# registration to populate the
# `KnowledgeState.node_lookup` and the
# `register_ritual` action sources its
# `ResearchNode` from
# `M4Rituals.by_id(id)`.
#
# The M4 closeout ships three rituals:
# `bind_inhabitant`, `survey_tile`, and
# `seal_breach`. The first two are
# player-facing exploration actions; the
# third is a Pactmaker-unlock ritual that
# the content catalogue exposes for
# `M4Pactmaker.powers` to consume.
class_name M4Rituals
extends RefCounted


## Return the full catalogue as a
## `Dictionary[StringName, ResearchNode]`.
static func all() -> Dictionary:
	var out: Dictionary = {}
	for n in _nodes():
		if n == null:
			continue
		if n.id == &"":
			continue
		out[n.id] = n
	return out


## Look up a single ritual by id. Returns
## `null` when the id is unknown.
static func by_id(id: StringName) -> ResearchNode:
	for n in _nodes():
		if n == null:
			continue
		if n.id == id:
			return n
	return null


## The catalogue builder. Each call
## returns a *new* `Array` of fresh
## `ResearchNode` instances. The M4
## closeout default is three rituals.
static func _nodes() -> Array:
	var out: Array = []
	# `bind_inhabitant` — binds an
	# inhabitant to the realm. Requires
	# the binding research tree.
	out.append(
		_make_ritual(
			&"bind_inhabitant",
			&"M4_RITUAL_BIND_INHABITANT_NAME",
			&"M4_RITUAL_BIND_INHABITANT_SUMMARY",
			3.0,
			[&"binding_basics"],
			{"summon_inhabitant": true}
		)
	)
	# `survey_tile` — reveals a fogged
	# tile. Requires the survey research
	# tree.
	out.append(
		_make_ritual(
			&"survey_tile",
			&"M4_RITUAL_SURVEY_TILE_NAME",
			&"M4_RITUAL_SURVEY_TILE_SUMMARY",
			1.0,
			[&"survey_basics"],
			{"reveal_tile": true}
		)
	)
	# `seal_breach` — seals a crisis
	# breach. Requires the deep binding
	# research.
	out.append(
		_make_ritual(
			&"seal_breach",
			&"M4_RITUAL_SEAL_BREACH_NAME",
			&"M4_RITUAL_SEAL_BREACH_SUMMARY",
			7.0,
			[&"deep_binding"],
			{"pactmaker_power_id": "seal_breach"}
		)
	)
	return out


## Ritual constructor. The cost is
## `days` (the time budget the per-tick
## rule consumes); the effect is a
## `Dictionary` of canonical
## `pactmaker_power_id` /
## `summon_inhabitant` / `reveal_tile`
## keys.
static func _make_ritual(
	pid: StringName,
	pname: StringName,
	psum: StringName,
	pdays: float,
	prereqs: Array,
	peffect: Dictionary,
) -> ResearchNode:
	var n: ResearchNode = ResearchNode.new()
	n.id = pid
	n.kind = ResearchNode.KIND_RITUAL
	n.display_name = pname
	n.summary = psum
	n.cost = {"days": pdays, "knowledge_points": int(pdays * 2.0)}
	n.prerequisites = prereqs.duplicate()
	n.effect = peffect.duplicate(true)
	n.unlocks = []
	return n
