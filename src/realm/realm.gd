# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — src/realm namespace stub (Realm).
#
# The src/realm module hosts the player-facing realm façade —
# the single object the UI is allowed to talk to about
# gameplay state. Per ADR-0002, this module is the bottom of
# the UI dependency chain: it composes src/world and src/sim,
# and it MUST NOT import from src/ui. The mechanical check
# that enforces that rule lives in
# tools/check_module_dependencies.sh.
#
# The real façade (Realm, the player-command surface) lands
# with the M1 cycle 2 commit. This stub establishes the
# public entry point required by §17 of
# docs/requirements.md and gives downstream code a symbol to
# preload against.
class_name Realm
extends RefCounted


## Per-campaign player-facing realm façade. One `Realm` per
## loaded campaign. Constructed exclusively by
## `RealmFactory`; callers receive the instance from the
## factory and never hand-construct it.
##
## The full API (`set_zone_purpose`, `create_room`, `pause`,
## `save`, …) lands with the M1 cycle 2 commit.
static func version() -> String:
	return "0.1.0-m1-stub"
