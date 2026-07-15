# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — research-node payload carrier (M4
# foundation).
#
# `ResearchNode` is the typed carrier for a
# single entry in the content-driven research
# and ritual tree (ADR-0010). A research node
# and a ritual node share the same schema;
# the `kind` field is the discriminator
# (`&"research"` or `&"ritual"`).
#
# The M4 foundation commit ships the
# carrier as a SKELETON: the `from_content`
# factory converts a content
# `Dictionary[StringName, Variant]` into a
# typed `ResearchNode` so the rest of the
# sim can read the typed fields. The
# per-tick progression rule is a separate
# concern (M4 Track A); the carrier
# *stores* the rule's inputs (the
# `prerequisites`, `cost`, `effect`), it
# does not *evaluate* them.
#
# The carrier is a *content* carrier, not a
# *state* carrier. The state side of the
# research tree lives in
# `KnowledgeState.researched` (a
# per-realm counter); the `ResearchNode`
# carrier is the per-node *definition* the
# content catalogue loads and the per-tick
# rule reads.
#
# Per ADR-0002, this file does not import
# from `src/ui`, `src/realm`, or `src/save`.
# It imports from `src/core` and
# `src/content` (the content adapter is a
# planned M4 Track A dependency; the
# skeleton declares it but does not
# preload it).
class_name ResearchNode
extends RefCounted

## The discriminator values. A node whose
## `kind` is `&"research"` is a research
## node; a node whose `kind` is
## `&"ritual"` is a ritual node. The M4
## default is the only allowed values; the
## content catalogue's validator asserts
## the discriminator at load time.
const KIND_RESEARCH: StringName = &"research"
const KIND_RITUAL: StringName = &"ritual"

## The node's stable identity. `StringName`
## so it survives the dictionary round-trip
## and so identity comparisons are O(1)
## hashed lookups. The id is the dictionary
## key in the content catalogue and the
## lookup key in
## `KnowledgeState.researched`.
var id: StringName = &""

## The discriminator. Either
## `KIND_RESEARCH` (`&"research"`) or
## `KIND_RITUAL` (`&"ritual"`). The M4
## default is `KIND_RESEARCH`; the M4
## Track A commit adds the content
## catalogue's validator that asserts
## the discriminator.
var kind: StringName = KIND_RESEARCH

## The node's display name, stored as a
## `StringName` that is a *locale key*
## (see `docs/localization.md` §"Naming").
## The M4 code does not resolve the key;
## the UI layer resolves it via `tr()` at
## draw time. The name is a `StringName`
## so it survives the dictionary
## round-trip.
var display_name: StringName = &""

## The node's summary, stored as a
## `StringName` that is a *locale key*.
## The M4 code does not resolve the key;
## the UI layer resolves it via `tr()` at
## draw time.
var summary: StringName = &""

## The cost of completing the node. The
## M4 default keys are
## `knowledge_points: int` (a flat
## knowledge budget the per-tick rule
## consumes) and `time_days: float` (a
## per-ritual time budget; unused for
## research nodes, which are instant).
## A ritual node also accepts
## `mana: float` (content-defined). The
## cost is a content value; the carrier
## does not enforce it (the per-tick
## rule consumes the cost and emits a
## `research.completed` or
## `ritual.completed` event when the
## cost is met).
var cost: Dictionary = {}

## The ids of the nodes that must be
## researched before this node can be
## progressed. The M4 default is `[]`
## (a root node); the forest invariant
## (ADR-0010) forces the prereq closure
## to be a single tree (no joins, no
## cycles, no self-prereq). The M4
## Track A commit adds the content
## catalogue's validator that asserts
## the invariant.
var prerequisites: Array = []

## The ids of the nodes that *this* node
## unlocks. The `unlocks` field is the
## *advisory* inverse of `prerequisites`;
## the load-time validator cross-checks
## the two (a node in `unlocks` is a
## node whose `prerequisites` contains
## this id). The field is advisory so
## content authors do not have to keep
## the two in sync by hand. The M4
## default is `[]` (a leaf node).
var unlocks: Array = []

## The effect applied to the realm when
## the node completes. The M4 default
## keys are `pactmaker_power_id:
## StringName` (unlocks a Pactmaker
## power), `decree_unlock: StringName`
## (unlocks a decree), `room_unlock:
## StringName` (unlocks a room type).
## A ritual node may also carry
## `crisis_summon_id: StringName` (a
## crisis the realm can deliberately
## trigger by completing this ritual).
## The effect is a content value; the
## carrier does not enforce it (the
## per-tick rule emits an event when
## the effect fires).
var effect: Dictionary = {}


## Default constructor. Starts with empty
## fields. The `kind` default is
## `KIND_RESEARCH`; the M4 Track A commit
## adds the validator that asserts the
## discriminator.
func _init() -> void:
	id = &""
	kind = KIND_RESEARCH
	display_name = &""
	summary = &""
	cost = {}
	prerequisites = []
	unlocks = []
	effect = {}


## Static factory. The canonical way to
## construct a `ResearchNode` from a
## content `Dictionary[StringName,
## Variant]`. The factory copies every
## field; the input `d` is not mutated.
## A `null` or non-`Dictionary`
## argument returns a fresh
## `ResearchNode` with empty fields
## (the M4 default is "lenient parse":
## the validator's job is the strict
## shape; the carrier's job is to
## surface the values).
##
## The M4 foundation commit ships the
## factory as a full implementation;
## the content catalogue's validator
## is the M4 Track A commit's
## responsibility.
static func from_content(d: Dictionary) -> ResearchNode:
	var n: ResearchNode = ResearchNode.new()
	if d == null:
		return n
	if not (d is Dictionary):
		return n
	n.id = StringName(String(d.get("id", &"")))
	n.kind = StringName(String(d.get("kind", KIND_RESEARCH)))
	n.display_name = StringName(String(d.get("display_name", &"")))
	n.summary = StringName(String(d.get("summary", &"")))
	if d.has("cost") and d["cost"] is Dictionary:
		n.cost = (d["cost"] as Dictionary).duplicate(true)
	if d.has("prerequisites") and d["prerequisites"] is Array:
		n.prerequisites = (d["prerequisites"] as Array).duplicate(true)
	if d.has("unlocks") and d["unlocks"] is Array:
		n.unlocks = (d["unlocks"] as Array).duplicate(true)
	if d.has("effect") and d["effect"] is Dictionary:
		n.effect = (d["effect"] as Dictionary).duplicate(true)
	return n


## Whether the node's prerequisites are
## all researched in `state`. Returns
## `true` when every id in
## `prerequisites` is in
## `state.researched` with a non-zero
## value. The M4 default is "all-or-
## nothing": a node with one missing
## prereq is not progressable.
##
## The method is a pure function on
## the node and the state; it does
## not mutate either. The M4 Track A
## commit's per-tick progression rule
## calls this method as the gate
## for "is this node ready to
## progress?".
func prereqs_met(state: KnowledgeState) -> bool:
	if state == null:
		return false
	for p in prerequisites:
		if not (p is StringName) and not (p is String):
			return false
		if not state.is_researched(StringName(String(p))):
			return false
	return true
