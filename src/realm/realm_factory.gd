# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — src/realm namespace stub (RealmFactory).
#
# The realm factory is a separate `class_name` so that the
# construction-vs-use distinction is visible at the type
# level: code that depends on a `Realm` (a use) is one
# dependency edge, code that depends on the factory
# (construction) is a second. This keeps the public surface
# of `Realm` itself small and stable.
#
# Per ADR-0002, src/realm MUST NOT import from src/ui. The
# mechanical check that enforces that rule lives in
# tools/check_module_dependencies.sh.
class_name RealmFactory
extends RefCounted


## Constructs and tears down `Realm` instances. The full
## factory API (`new_realm(seed, content_set, options)`,
## `load_realm(path)`, `dispose(realm)`) lands with M1
## cycle 2.
static func version() -> String:
	return "0.1.0-m1-stub"
