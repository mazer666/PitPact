# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — src/ui namespace stub.
#
# The src/ui module is the presentation layer. Per ADR-0002,
# it is the ONLY module allowed to import from the rest of
# src/ for gameplay data (via src/realm), AND it is the
# module the game-domain modules are forbidden to import
# from. The mechanical check that enforces both directions
# of that rule lives in
# tools/check_module_dependencies.sh.
#
# The real UI (scenes, controllers, input map, camera)
# lands with the M1 cycle 2 commit. This stub establishes
# the public entry point required by §17 of
# docs/requirements.md.
class_name RealmUiController
extends RefCounted


## Realm UI controller. The full API (camera, input
## bindings, scene wiring) lands with M1 cycle 2. Until
## then, this stub holds the `class_name` and the public
## version string so the dependency check has a real symbol
## to inspect.
static func version() -> String:
	return "0.1.0-m1-stub"
