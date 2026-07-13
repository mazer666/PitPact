# src/save

Versioned save/load plus the migration chain.

## Purpose

`src/save` is the persistence layer. It serialises a realm
(and its dependencies) to the format pinned in
[`docs/adrs/0003-save-format.md`](../adrs/0003-save-format.md),
reads that format back, runs the migration chain, and returns
a `Realm` (or a save-load error).

`src/save` knows nothing about *what* a realm is. It just
round-trips a canonical JSON payload through the registered
adapters. The realm façade knows the gameplay semantics; the
save layer knows the wire format.

## Responsibility

`src/save`:

- serialises a `Realm` to the canonical save shape (see
  ADR-0003),
- deserialises a save file, runs the migration chain, and
  hands the result back to the realm factory,
- computes the canonical SHA-256 integrity check
  (see ADR-0003),
- owns the migration table (`src/save/MIGRATIONS.md` plus
  the `migrate_<from>_to_<to>.gd` scripts).

`src/save` does **not** simulate, does **not** render, and
does **not** read the Godot scene tree.

## Public entry point

`class_name SaveService` — a single process-wide service.
Obtained via `SaveService.get_default()`.

The full API (`save(realm, path)`, `load(path)`,
`compute_canonical_hash(save)`, …) will be documented in
this section as the M1 cycle 2 commit lands the real
service. Until then the public entry point is the
`class_name SaveService` declared in `save.gd`.

## Main dependencies

- `src/core` — for the canonical hashing helpers and the
  `JSON`-style canonical serialiser.

At the call site, the realm factory is involved (it
constructs the `Realm` from the deserialised body), but
`src/save` itself only sees the canonical payload shape.

## Must NOT depend on

- `src/ui`, `src/audit` — the save pipeline must work in a
  headless test.
- The Godot scene tree.

The mechanical check for this rule lives in
[`tools/check_module_dependencies.sh`](../../tools/check_module_dependencies.sh).

## Files

| File | Public class | Status |
|------|--------------|--------|
| [`save.gd`](save.gd) | `SaveService` (stub) | M1 stub |
| (lands with M1 cycle 2) | the canonical JSON serialiser, the SHA-256 helper, the migration loader | planned |
| (lands with M1 cycle 2) | [`MIGRATIONS.md`](MIGRATIONS.md) | planned (initially empty) |

## See also

- [`docs/adrs/0003-save-format.md`](../adrs/0003-save-format.md)
- [`docs/adrs/0002-module-boundaries.md`](../adrs/0002-module-boundaries.md)
- [`docs/requirements.md`](../requirements.md) §12, §16, §18, §19
