# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — src/content namespace stub.
#
# The src/content module hosts the data-driven content
# definitions (biomes, resources, room definitions,
# inhabitant cultures, contracts, research, origins, event
# templates). Per ADR-0002, this module is data only; it
# MUST NOT import from src/world, src/sim, src/realm,
# src/save, src/ui, or src/audit. The mechanical check that
# enforces that rule lives in
# tools/check_module_dependencies.sh.
#
# The real registry lands with the M1 cycle 2 commit. This
# stub establishes the public entry point required by §17
# of docs/requirements.md and gives downstream code a
# symbol to preload against.
class_name ContentRegistry
extends RefCounted


## Process-wide content registry. Obtained via
## `ContentRegistry.get_default()`. The full API
## (`get_room_def(id)`, `get_biome_def(id)`,
## `list_contracts()`, …) lands with M1 cycle 2.
static func version() -> String:
	return "0.1.0-m1-stub"
