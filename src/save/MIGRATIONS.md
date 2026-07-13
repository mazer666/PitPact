# Save migrations

This file is the human-readable index of the migration chain
that the save loader runs (see ADR-0003 §"The migration
contract"). The chain lives in `migrations.gd`; this index
exists so a future contributor can answer "what migrations
do we ship?" without reading the code.

## Format

Each entry below is a row in a four-column table:

| From | To | Function | Notes |
|---:|---:|---|---|
| `save_version` | `save_version` | (callable name) | (one-line description) |

## Index

| From | To | Function | Notes |
|---:|---:|---|---|
| 1 | 1 | `migrate_1_to_1` | No-op. M1 ships a single smoke-test migration so the registry is live and the chain is exercisable. |

## How to add a migration

1. Bump `SaveFormat.SAVE_VERSION` in `save_format.gd` to the
   new target version.
2. Write the pure function `migrate_<from>_to_<to>(body: Dictionary) -> Dictionary` in `migrations.gd`. Keep it pure
   (no I/O, no global state).
3. Register it at the bottom of `migrations.gd` inside
   `_static_init()` via `register(<from>, <to>, Callable(self, "migrate_<from>_to_<to>"))`.
4. Add a row to the index above.
5. Add a regression test under `tests/save/` that loads a
   fixture save from `<from>` and asserts the post-migration
   body matches the expected shape.
6. Bump the engine version in `realm_serializer.gd`'s
   `ENGINE_VERSION` so a player opening a migrated save sees
   the new build in the file metadata.
