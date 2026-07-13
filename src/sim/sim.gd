# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — src/sim namespace stub.
#
# The src/sim module hosts the deterministic, tick-based
# simulation of a single realm. Per ADR-0002, this module MUST
# NOT import from src/ui, src/realm, or src/save. The mechanical
# check that enforces that rule lives in
# tools/check_module_dependencies.sh.
#
# The real simulation (inhabitant roster, needs, contracts,
# tasks, relationships, event memory) lands with the M2 commit.
# This stub establishes the public entry point required by §17
# of docs/requirements.md and gives downstream code a symbol to
# preload against.
class_name Simulation
extends RefCounted


## Per-realm simulation. One `Simulation` per loaded realm.
## Owned by `src/realm/Realm`; callers do not construct it
## directly. The full API (`tick`, `add_inhabitant`,
## `evaluate_contracts`, …) lands with M2.
static func version() -> String:
	return "0.1.0-m1-stub"
