# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M5-Foundation: PlayableShell carrier.
#
# `PlayableShell` is the canonical "playable
# sim" factory. The carrier composes the
# M0-M4 sim (Inhabitant + Needs + Contracts
# + Tasks + Relationships + EventLog + Crisis
# + Branch + NarrativeAnchor + WorldGenerator
# + ExplorationMap + Knowledge + Pactmaker
# + Faction + Settings) into a single
# "playable sim" object. The M5 closeout
# extends the factory with content (six
# cultures, ten rooms, fifteen events);
# the M5-Foundation delivers the minimal
# playable sim with three inhabitants,
# one crisis, one Pactmaker, and one world.
#
# The carrier is the *headless* factory: it
# creates the sim and exposes the public
# surface. The UI scene
# (`scenes/main/PlayableShell.tscn`) consumes
# the factory's output and renders it. The
# separation lets the end-to-end smoke test
# exercise the factory without the UI.
#
# Per ADR-0002, this file does not import
# from `src/ui/`. It imports from `src/core`,
# `src/sim`, `src/world`, `src/content`,
# `src/save`, and `src/audit`.
class_name PlayableShell
extends RefCounted

## The M5-Foundation seed. The seed is
## pinned so the end-to-end smoke test
## can assert deterministic post-state
## (the M3 ADR-0005 determinism contract).
const SEED: int = 4242

## The M5-Foundation world size. 24x24
## matches the M3-Closeout smoke test
## (the M3-Foundation ADR-0007 reference
## size; the M5 closeout can extend to
## 48x48 if needed).
const WORLD_W: int = 24
const WORLD_H: int = 24

## The M5-Foundation realm anchor (the
## world tile the realm is centered on).
## The M4 Closeout's reveal_tile power
## uses this as the radius center.
const REALM_ANCHOR: Vector2i = Vector2i(12, 12)

## The M5-Foundation tick count for the
## end-to-end smoke test. 30 days is
## enough to exercise the per-tick loop,
## the autonomous conflict step, and the
## Pactmaker yearly reset (every 360 days;
## the 30-day run does not trigger a
## yearly reset, but the test asserts
## the counter is preserved across the
## run).
const TICKS: int = 30

## The M5-Foundation default settings.
## The M4 closeout's `Settings.make_settings_default()`
## returns the M4 default (BALANCED
## difficulty, 7 auto-resolve days, en
## locale). The M5-Foundation uses the
## M4 default.
const DEFAULT_DIFFICULTY: int = 1  # BALANCED

## The version tag for the M5-Foundation
## carrier. The M5 closeout bumps this
## to `0.2.0-m5-closeout` when the M5
## content lands.
const _VERSION: String = "0.1.0-m5-foundation"


## Return the carrier's version tag.
## The method is the canonical "give
## me the carrier's version" entry
## point; the smoke test asserts the
## version (a regression that bumps
## the version without bumping the
## test is caught).
static func version() -> String:
	return _VERSION


## Build the canonical M5-Foundation
## playable sim. The factory is the
## canonical "give me a playable
## realm" entry point; the UI scene
## and the end-to-end smoke test
## both call this.
##
## The factory returns a `Dictionary`
## with the following keys:
## - `sim: Sim` — the M2-M4 simulation
##   core (M4 systems registered)
## - `world: World` — the M3 world
##   (24x24, two biomes)
## - `inhabitants: Array[Inhabitant]`
##   — three inhabitants
## - `crises: Array[Crisis]` — one
##   crisis (plague_outbreak, with the
##   M4 14-day autonomous resolution)
## - `pactmaker: Pactmaker` — the M4
##   canonical Pactmaker (3
##   interventions/year, 3 powers)
## - `factions: Array[Faction]` —
##   three factions
## - `settings: Settings` — the M4
##   default Settings
## - `knowledge: KnowledgeState` —
##   empty knowledge state
## - `exploration_map: ExplorationMap`
##   — the M3 fog-of-war map
## - `narrative_anchors: Array` —
##   three narrative anchors
## - `log: EventLog` — the sim's
##   event log
static func build() -> Dictionary:
	var log: EventLog = EventLog.new()
	var sim: Sim = Sim.new(SEED)
	# World: 24x24 with two biomes
	# (Marshlands + Highlands).
	var gen: WorldGenerator = WorldGenerator.new()
	var constraints: Dictionary = {
		"hearth_position": REALM_ANCHOR,
		"hearth_burden_max": 0.3,
		"min_biome_count": 2,
		"required_biome_ids": [&"marshlands", &"highlands"],
	}
	var world: Variant = gen.generate(SEED, WORLD_W, WORLD_H, constraints)
	# Exploration map: 24x24, fog-of-war
	# centered on the realm anchor, radius 1.
	var emap: ExplorationMap = ExplorationMap.new(WORLD_W, WORLD_H, REALM_ANCHOR, 1)
	sim.register_exploration(emap)
	sim.anchor = REALM_ANCHOR
	# Inhabitants: three (1 Lanternbearer
	# + 2 generic). The M5-Foundation uses
	# the M2 Track A inhabitant carrier
	# (id, culture, name, role, position).
	var inhabitants: Array = []
	inhabitants.append(_make_inhabitant(&"lanternbearer_lia", &"lanternbearer", &"scribe"))
	inhabitants.append(_make_inhabitant(&"generic_aren", &"lanternbearer", &"settler"))
	inhabitants.append(_make_inhabitant(&"generic_bex", &"lanternbearer", &"settler"))
	for inh in inhabitants:
		inh.position = REALM_ANCHOR
	# Contracts: one standard pact per
	# inhabitant (the M2 Track B standard
	# pact is the canonical contract).
	for inh in inhabitants:
		sim.add_contract(_make_standard_contract(inh.id))
	# Narrative anchors: three (the M3
	# Track B canonical set).
	var anchors: Array = [
		NarrativeAnchor.from_content(
			&"first_morning", 2.0, &"ANCHOR_FIRST_MORNING_NAME", &"ANCHOR_FIRST_MORNING_SUMMARY"
		),
		NarrativeAnchor.from_content(
			&"stowaway", -1.0, &"ANCHOR_STOWAWAY_NAME", &"ANCHOR_STOWAWAY_SUMMARY"
		),
		NarrativeAnchor.from_content(
			&"first_pactmaker_visit",
			5.0,
			&"ANCHOR_FIRST_PACTMAKER_VISIT_NAME",
			&"ANCHOR_FIRST_PACTMAKER_VISIT_SUMMARY"
		),
	]
	sim.register_anchors(anchors)
	# Crises: one (plague_outbreak, M4
	# canonical, 14-day autonomous
	# resolution). The crisis is added
	# to the sim's crisis queue.
	var crisis_def: Dictionary = M4Crises._plague_outbreak()
	var cr: Crisis = Crisis.make(&"plague_outbreak", 10.0, Callable(), [])
	cr.data = crisis_def.get("data", {})
	cr.autonomous_resolution_days = float(crisis_def.get("autonomous_resolution_days", 14.0))
	# Re-create the choices from the
	# content catalogue (Crisis.make takes
	# raw choice dictionaries).
	var choices: Array = []
	for choice_def in crisis_def.get("choices", []):
		(
			choices
			. append(
				{
					"id": choice_def.get("id", &""),
					"label": choice_def.get("label", &""),
					"summary": choice_def.get("summary", &""),
					"effect": Callable(),
					"is_default": choice_def.get("is_default", false),
				}
			)
		)
	cr.choices = choices
	cr.bind_event_log(log)
	sim.add_crisis(cr)
	# Pactmaker: the M4 canonical
	# Pactmaker (3 interventions/year,
	# 3 powers: seal_breach, pause_crisis,
	# reveal_tile).
	var pactmaker: Pactmaker = M4Pactmaker.build()
	sim.register_pactmaker(pactmaker)
	# Factions: three (lantern_clan,
	# ledger_cabal, hollow_church).
	sim.register_factions(M4Factions.all())
	# Settings: the M4 default
	# (BALANCED difficulty, 7
	# auto-resolve days, en locale).
	var settings: Settings = Settings.new()
	settings.difficulty = DEFAULT_DIFFICULTY
	settings.auto_resolve_days = 7
	settings.locale = "en"
	sim.register_settings(settings)
	# Knowledge state: empty (no
	# researched nodes; the player
	# will research via the UI).
	var knowledge: KnowledgeState = KnowledgeState.new()
	sim.register_knowledge(knowledge)
	return {
		"sim": sim,
		"world": world,
		"inhabitants": inhabitants,
		"crises": [cr],
		"pactmaker": pactmaker,
		"factions": M4Factions.all(),
		"settings": settings,
		"knowledge": knowledge,
		"exploration_map": emap,
		"narrative_anchors": anchors,
		"log": log,
		"version": _VERSION,
	}


## M5-Foundation: build a fresh
## `Inhabitant` with the canonical
## (id, culture, name, role)
## fields. The factory mirrors the
## M2 Track A pattern (`_init_id`)
## so the M5-Foundation smoke test
## can construct inhabitants without
## hand-rolling each field.
static func _make_inhabitant(
	p_id: StringName, p_culture: StringName, p_role: StringName
) -> Inhabitant:
	var inh: Inhabitant = Inhabitant.new()
	inh._init_id(p_id, p_culture, p_id, p_role)
	return inh


## M5-Foundation: build the canonical
## standard-pact contract for an
## inhabitant. The factory uses the
## M2 Track B terms (lodging, food_share,
## labour_hours_per_day, breach_consequence)
## so the M5-Foundation contract is
## compatible with the M2 save service
## and the M3-Closeout smoke test.
static func _make_standard_contract(p_inhabitant_id: StringName) -> Contract:
	var c: Contract = Contract.new()
	c.id = StringName(String(p_inhabitant_id) + "_pact")
	c.inhabitant_id = p_inhabitant_id
	c.terms = {
		&"lodging": true,
		&"food_share": true,
		&"labour_hours_per_day": 8,
		&"breach_consequence": &"morale_penalty",
	}
	return c
