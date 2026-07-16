# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M4 foundation public façade.
#
# `M4Skeleton` is the public façade that
# re-exports the M4 carriers (KnowledgeState,
# ResearchNode, Pactmaker, Power, Faction,
# Settings) for the M4 closeout smoke test
# (`tests/integration/test_m4_skeleton.gd`).
# The façade is a *thin* re-export: it holds
# no state of its own, it just gives the
# closeout smoke test a single
# `class_name M4Skeleton` to load so the test
# can verify that every M4 carrier is
# loadable and that the public surface is
# intact.
#
# Why a façade at all? Two reasons:
#
#   1. **Discoverability.** A new contributor
#      looking for "the M4 carriers" can find
#      them all in one place. The M2 cycle 3
#      `sim.gd` façade is the same idea for
#      the M2 carriers; the M4 façade is the
#      M4 counterpart.
#   2. **Smoke-test surface.** The M4 closeout
#      smoke test
#      (`tests/integration/test_m4_skeleton.gd`)
#      is the canonical "is the M4 foundation
#      wired up?" check. Loading the façade
#      and asserting every carrier's public
#      surface is a one-page test that
#      exercises every M4 file.
#
# The M4 foundation commit ships the façade
# as a SKELETON: the `version()` method
# returns the M4 foundation version tag; the
# M4 Track A commit bumps the version when
# the per-tick rule lands.
#
# Per ADR-0002, this file does not import
# from `src/ui`, `src/realm`, or `src/save`.
# It imports from `src/sim/` (the M4
# carriers) and `src/core` only.
class_name M4Skeleton
extends RefCounted

## M4 foundation version tag. The value is
## a string rather than a numeric constant
## so the version can be derived from a
## single source of truth in a later
## milestone. The M4 foundation tag is
## `0.1.0-m4-foundation`; the M4 Track A
## commit (research/ritual progression rule)
## bumps it to `0.2.0-m4-track-a`; the M4
## Track B commit (Pactmaker powers and
## autonomous conflict) bumps it to
## `0.3.0-m4-track-b`.
const _VERSION: String = "0.5.0-m4-closeout"


## Default constructor. The façade holds no
## state; the constructor is a no-op. The
## `class_name M4Skeleton` declaration is
## the load-bearing reason this file
## exists; the constructor is here so the
## GUT 9 test runner can instantiate the
## façade without raising.
func _init() -> void:
	pass


## Build a fresh `KnowledgeState` with the
## default fields. The factory is the
## canonical "give me a knowledge carrier"
## helper for tests and the M4 Track A
## commit's per-tick rule. The M4 foundation
## commit ships the factory as a thin
## wrapper over `KnowledgeState.new()`; the
## M4 Track A commit extends the factory
## with a content-catalogue-driven
## constructor (e.g. "load the default
## research tree from `data/research/
## default.tres` and produce a carrier that
## knows about the tree").
static func make_knowledge_state() -> KnowledgeState:
	return KnowledgeState.new()


## Build a fresh `ResearchNode` with the
## default fields. The factory is the
## canonical "give me an empty research
## node" helper for tests and the M4 Track
## A commit's content catalogue. The M4
## foundation commit ships the factory as
## a thin wrapper over `ResearchNode.new()`;
## the M4 Track A commit's catalogue
## loader uses `ResearchNode.from_content`
## for the real construction.
static func make_research_node() -> ResearchNode:
	return ResearchNode.new()


## Build a fresh `Pactmaker` with the
## default fields. The factory is the
## canonical "give me a Pactmaker"
## helper for tests and the realm
## façade's construction path. The M4
## foundation commit ships the factory
## as a thin wrapper over
## `Pactmaker.new()`; the M4 Track A
## commit extends the factory with an
## `origin_id` argument (the factory
## reads the origin's
## `intervention_limit` from the content
## catalogue and sets the carrier's
## field).
static func make_pactmaker() -> Pactmaker:
	return M4Pactmaker.build()


## Build a fresh `Power` with the default
## fields. The factory is the canonical
## "give me an empty power" helper for
## tests and the M4 Track A commit's
## per-power registration. The M4
## foundation commit ships the factory as
## a thin wrapper over `Power.new()`.
static func make_power() -> Power:
	return Power.new()


## Build a fresh `Faction` with the
## default fields. The factory is the
## canonical "give me a faction" helper
## for tests and the M4 Track A commit's
## faction-catalogue loader. The M4
## foundation commit ships the factory as
## a thin wrapper over `Faction.new()`.
static func make_faction() -> Faction:
	return Faction.new()


## Build a fresh `Settings` with the
## default fields. The factory is the
## canonical "give me a settings carrier"
## helper for tests and the realm
## façade's construction path. The M4
## foundation commit ships the factory as
## a thin wrapper over
## `Settings.from_dict({})`; the M4
## Track A commit extends the factory
## with a "load from `user://settings.cfg`"
## path.
static func make_settings() -> Settings:
	return Settings.from_dict({})


## Return the M4 foundation version tag.
## The value is a string rather than a
## numeric constant so the version can be
## derived from a single source of truth
## in a later milestone. The M4 foundation
## tag is `0.1.0-m4-foundation`; the M4
## Track A commit bumps it to
## `0.2.0-m4-track-a`; the M4 Track B
## commit bumps it to
## `0.3.0-m4-track-b`. The M4 closeout
## smoke test asserts the version tag;
## the test is the mechanical check for
## "is the M4 foundation in place?".
static func version() -> String:
	return _VERSION


## M4-Closeout: build the M4 default
## research catalogue as a fresh
## `Dictionary[StringName, ResearchNode]`.
## The factory is the canonical "M4
## research nodes" entry point; the
## realm façade's boot path calls this
## and stores the result in
## `KnowledgeState.node_lookup`.
static func make_research_catalogue() -> Dictionary:
	return M4Research.all()


## M4-Closeout: build the M4 default
## ritual catalogue as a fresh
## `Dictionary[StringName, ResearchNode]`.
static func make_ritual_catalogue() -> Dictionary:
	return M4Rituals.all()


## M4-Closeout: build the canonical M4
## faction list. The factory is the
## canonical "M4 factions" entry point;
## the realm façade's boot path calls
## this and stores the result via
## `Sim.register_factions(arr)`.
static func make_factions() -> Array:
	return M4Factions.all()


## M4-Closeout: build the M4 default
## crisis catalogue as an `Array` of
## `Dictionary` payloads (the
## `Crisis.make(...)` factory consumes
## them).
static func make_crisis_catalogue() -> Array:
	return M4Crises.all()
