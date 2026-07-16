# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M4 Track A research catalogue.
#
# `M4Research` is the canonical M4 research
# node catalogue. The catalogue is a
# `Dictionary[StringName, ResearchNode]`; the
# realm façade calls `M4Research.all()` once
# at sim registration to populate the
# `KnowledgeState.node_lookup` and the
# `register_research` action sources its
# `ResearchNode` from `M4Research.by_id(id)`.
#
# The catalogue is a *forest* (ADR-0010): each
# node's `prerequisites` form a tree (no
# cycles, no joins, no self-prereq). The M4
# closeout ships two trees (binding + survey)
# for a total of six nodes.
class_name M4Research
extends RefCounted


## Return the full catalogue as a
## `Dictionary[StringName, ResearchNode]`.
## The method is the canonical "all
## research nodes" entry point; the
## realm façade's M4 boot path calls
## this once and stores the result in
## `KnowledgeState.node_lookup`. The
## dictionary is a *new* dictionary per
## call (mutating the result does NOT
## mutate the catalogue).
static func all() -> Dictionary:
	var out: Dictionary = {}
	for n in _nodes():
		if n == null:
			continue
		if n.id == &"":
			continue
		out[n.id] = n
	return out


## Look up a single node by id. Returns
## `null` when the id is unknown. The
## method is the canonical "node by id"
## entry point.
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
## default is six nodes (two trees of
## three).
static func _nodes() -> Array:
	var out: Array = []
	# Tree 1: binding tree
	out.append(
		_make(
			&"binding_basics",
			ResearchNode.KIND_RESEARCH,
			&"M4_RESEARCH_BINDING_BASICS_NAME",
			&"M4_RESEARCH_BINDING_BASICS_SUMMARY",
			7.0,
			[],
			[&"binding_rituals_unlock"]
		)
	)
	out.append(
		_make(
			&"binding_rituals",
			ResearchNode.KIND_RESEARCH,
			&"M4_RESEARCH_BINDING_RITUALS_NAME",
			&"M4_RESEARCH_BINDING_RITUALS_SUMMARY",
			14.0,
			[&"binding_basics"],
			[&"deep_binding_unlock"]
		)
	)
	out.append(
		_make(
			&"deep_binding",
			ResearchNode.KIND_RESEARCH,
			&"M4_RESEARCH_DEEP_BINDING_NAME",
			&"M4_RESEARCH_DEEP_BINDING_SUMMARY",
			21.0,
			[&"binding_rituals"],
			[]
		)
	)
	# Tree 2: survey tree
	out.append(
		_make(
			&"survey_basics",
			ResearchNode.KIND_RESEARCH,
			&"M4_RESEARCH_SURVEY_BASICS_NAME",
			&"M4_RESEARCH_SURVEY_BASICS_SUMMARY",
			7.0,
			[],
			[&"survey_rituals_unlock"]
		)
	)
	out.append(
		_make(
			&"survey_rituals",
			ResearchNode.KIND_RESEARCH,
			&"M4_RESEARCH_SURVEY_RITUALS_NAME",
			&"M4_RESEARCH_SURVEY_RITUALS_SUMMARY",
			14.0,
			[&"survey_basics"],
			[&"deep_survey_unlock"]
		)
	)
	out.append(
		_make(
			&"deep_survey",
			ResearchNode.KIND_RESEARCH,
			&"M4_RESEARCH_DEEP_SURVEY_NAME",
			&"M4_RESEARCH_DEEP_SURVEY_SUMMARY",
			21.0,
			[&"survey_rituals"],
			[]
		)
	)
	return out


## Catalogue constructor. The
## dictionary's `cost` and `effect` keys
## are the canonical ADR-0010 keys; the
## M4 closeout keeps the names
## (`days` in cost, `pactmaker_power_id`
## / `decree_unlock` in effect) to make
## the per-tick rule's contract
## explicit.
static func _make(
	pid: StringName,
	pkind: StringName,
	pname: StringName,
	psum: StringName,
	pdays: float,
	prereqs: Array,
	plock_effects: Array,
) -> ResearchNode:
	var n: ResearchNode = ResearchNode.new()
	n.id = pid
	n.kind = pkind
	n.display_name = pname
	n.summary = psum
	n.cost = {"days": pdays, "knowledge_points": int(pdays)}
	n.prerequisites = prereqs.duplicate()
	# Each `unlocks` advisory becomes a
	# synthetic `effect` entry that the
	# per-tick rule emits as a
	# `pending_effects` payload.
	var eff: Dictionary = {}
	for u in plock_effects:
		eff[String(u)] = true
	n.effect = eff
	# `unlocks` is the advisory inverse
	# of `prerequisites`; for the M4
	# closeout it is empty (the per-tick
	# rule consumes `effect` directly).
	n.unlocks = []
	return n
