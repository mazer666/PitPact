# src/content

Data-driven content definitions. Pure data adapters over
`src/core`.

## Purpose

`src/content` is the home of *content*: the data-driven
definitions that describe the world without simulating it.
Biomes, resources, room definitions, inhabitant cultures,
contracts, research, origins, and event templates all live
here. The simulation reads them; the realm façade exposes
them; the save format round-trips them.

`src/content` is a thin data adapter over `src/core` — it
loads, validates, and serves content definitions, and does
nothing else. There is no behaviour beyond validation and
lookup.

## Responsibility

`src/content`:

- loads versioned content sets from `res://data/` (and from
  future mod directories, with a documented load order),
- validates each definition against its schema and rejects
  invalid content with a logged error,
- serves definitions to the world, the simulation, the
  realm façade, and the audit layer via a single registry
  API,
- emits a content manifest (`ContentRegistry.manifest()`)
  for the save format's `content_version` field (see
  ADR-0003).

`src/content` does **not** simulate, does **not** render,
and does **not** own any game state beyond the loaded
content set.

## Public entry point

`class_name ContentRegistry` — a single process-wide
registry. Obtained via `ContentRegistry.get_default()`.

The full API (`get_room_def(id)`, `get_biome_def(id)`,
`list_contracts()`, …) will be documented in this section
as the M1 cycle 2 commit lands the real registry. Until
then the public entry point is the `class_name
ContentRegistry` declared in `content.gd`.

## Main dependencies

- `src/core` — for primitives (e.g. schema-version types,
  validation helpers).

## Must NOT depend on

- `src/world`, `src/sim`, `src/realm`, `src/save`, `src/ui`,
  `src/audit` — content is data; it does not know which
  world it is being loaded into.
- The Godot scene tree.

The mechanical check for this rule lives in
[`tools/check_module_dependencies.sh`](../../tools/check_module_dependencies.sh).

## Files

| File | Public class | Status |
|------|--------------|--------|
| [`content.gd`](content.gd) | `ContentRegistry` (stub) | M1 stub |
| (lands with M1 cycle 2) | the real content registry and per-content-type adapters | planned |

## See also

- [`docs/adrs/0002-module-boundaries.md`](../adrs/0002-module-boundaries.md)
- [`data/README.md`](../../data/README.md) — the data files
  the registry loads.
- [`docs/requirements.md`](../requirements.md) §3, §9, §10, §16, §17
