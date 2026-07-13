# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — src/audit namespace stub.
#
# The src/audit module is the diagnostic layer. Per
# ADR-0002, it MUST NOT import from src/world, src/sim,
# src/realm, src/save, or src/ui; the audit layer is a
# passive observer. The mechanical check that enforces
# that rule lives in
# tools/check_module_dependencies.sh.
#
# The real event log lands with the M2 commit. This stub
# establishes the public entry point required by §17 of
# docs/requirements.md and gives downstream code a symbol
# to preload against.
class_name AuditLog
extends RefCounted


## Per-realm audit log. Obtained via
## `AuditLog.for_realm(realm)`. The full API (`record`,
## `events_between`, `seed_manifest`, …) lands with M2.
static func version() -> String:
	return "0.1.0-m1-stub"
