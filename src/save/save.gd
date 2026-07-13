# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — src/save namespace stub.
#
# The src/save module hosts the versioned save/load pipeline
# defined in ADR-0003. Per ADR-0002, this module MUST NOT
# import from src/ui or src/audit; the save pipeline must be
# usable from a headless test. The mechanical check that
# enforces that rule lives in
# tools/check_module_dependencies.sh.
#
# The real service (canonical JSON serialiser, SHA-256
# helper, migration loader) lands with the M1 cycle 2
# commit. This stub establishes the public entry point
# required by §17 of docs/requirements.md and gives
# downstream code a symbol to preload against.
class_name SaveService
extends RefCounted


## Process-wide save service. Obtained via
## `SaveService.get_default()`. The full API (`save`,
## `load`, `compute_canonical_hash`, …) lands with M1
## cycle 2.
static func version() -> String:
	return "0.1.0-m1-stub"
