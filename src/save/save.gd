# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — src/save public entry point.
#
# `SaveService` is the §17 public entry point for the save
# module. It is a thin namespace over the concrete
# implementation in `realm_serializer.gd`; the split exists
# so the public name (`SaveService`) is stable across the
# M1 → M6 path and the implementation can be swapped
# without changing call sites.
#
# Per ADR-0002, `src/save` MUST NOT import from `src/ui` or
# `src/audit`; the save pipeline must be usable from a
# headless test. The mechanical check that enforces that
# rule lives in `tools/check_module_dependencies.sh`.
#
# Per ADR-0003, the save format is a content-agnostic JSON
# object with a SHA-256 integrity check and an explicit
# `engine_version` for migration support. The full format
# is implemented in `save_format.gd`; the realm translation
# is in `realm_serializer.gd`; the migration chain is in
# `migrations.gd`. This file re-exports the stable surface.
class_name SaveService
extends RefCounted


## Process-wide save service version. The literal is the
## version of the save *format* implementation, not the
## engine build; engine build lives in
## `RealmSerializer.ENGINE_VERSION`.
static func version() -> String:
	return "0.1.0-m1"


## Build a `save` `Dictionary` from a realm body. Thin
## wrapper over `RealmSerializer.build_save` that exists
## so the call site reads naturally:
## `SaveService.build_save(body, seed_hex)`.
static func build_save(realm_body: Dictionary, seed_hex: String, extra: Dictionary = {}) -> Dictionary:
	return RealmSerializer.build_save(realm_body, seed_hex, extra)


## Parse a JSON save, run the migration chain, and verify
## the integrity check. Thin wrapper over
## `RealmSerializer.from_json`; the round-trip behaviour
## is documented there.
static func from_json(json_text: String) -> Dictionary:
	return RealmSerializer.from_json(json_text)


## Serialise a `save` `Dictionary` to a JSON string. Thin
## wrapper over `RealmSerializer.to_json`.
static func to_json(save: Dictionary) -> String:
	return RealmSerializer.to_json(save)


## Write a save to a file. Thin wrapper over
## `RealmSerializer.write_to_file`.
static func write_to_file(save: Dictionary, path: String) -> Dictionary:
	return RealmSerializer.write_to_file(save, path)


## Read a save from a file and run the load pipeline. Thin
## wrapper over `RealmSerializer.read_from_file`.
static func read_from_file(path: String) -> Dictionary:
	return RealmSerializer.read_from_file(path)
