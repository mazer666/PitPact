# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — src/world namespace stub.
#
# The src/world module hosts the spatial state of a realm: tile
# grid, zones, rooms, and the pure coordinate conversions defined
# in ADR-0004. Per ADR-0002, this module MUST NOT import from
# src/ui, src/sim, src/realm, src/save, or src/audit. The
# mechanical check that enforces that rule lives in
# tools/check_module_dependencies.sh.
#
# The real data model (TileGrid, Zone, Room, coordinate
# conversions) lands with the M1 cycle 2 commit. This stub
# establishes the public entry point required by §17 of
# docs/requirements.md and gives downstream code a symbol to
# preload against.
class_name WorldState
extends RefCounted


## Per-realm spatial state. One `WorldState` per loaded realm.
## Constructed exclusively by `src/realm/RealmFactory`; callers
## receive the instance from the realm façade and never
## hand-construct it.
##
## The full API (`tile_at`, `tiles_in_zone`, `room_at`, etc.)
## lands with the M1 cycle 2 commit. This stub holds the
## namespace and the `class_name` so that other modules can
## refer to it.
static func version() -> String:
	return "0.1.0-m1-stub"
