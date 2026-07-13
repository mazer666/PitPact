---
status: accepted
date: 2026-07-13
deciders: project leads
consulted: contributors
informed: all contributors
---

# 3. Save format and versioning

## Context and problem statement

`docs/requirements.md` §12 requires "free local save/load", §12
also requires that players can "export and import saves", §16 says
"save formats must be versioned and migration-tested", and §19
says "save files remain local and exportable/importable in
documented formats" and "imported saves/mods must validate formats
and fail safely; untrusted content must not execute arbitrary
code".

§25 of the same document lists "save-file format and mod-data
schema versioning detail" as an open design decision to be
resolved during M0/M1.

Without a written contract, save format decisions will be made
implicitly during M1 (local saving) and M3 (mod-data), and the
implicit decisions will conflict: the M1 format will not be
forward-compatible with M3's mod-data, the migration story will
be invented under pressure, and the "imported saves must validate
and fail safely" requirement will be honoured in name only.

We need a format decision that:

1. is forward- and backward-compatible across the M1 → M6 path,
2. survives being opened in a text editor (so a player can read
   and diff their own save, and so we can write migration tests
   in Python or shell),
3. does not require Godot to *read* (only to *write*),
4. has a tamper-detection story,
5. has a migration contract that can be regression-tested as the
   format evolves,
6. and is content-agnostic — the save body does not know about
   Godot `Resource` internals.

## Decision drivers

- **Player ownership.** §12, §19: "Generated worlds and saves remain
  player-owned." A binary blob is not a file the player can
  meaningfully own.
- **Forward compatibility.** The M6 release will load M1 saves
  (modulo documented migrations). The format must support that
  without a "v2" rewrite.
- **Migration-testability.** §16, §18: migration is a
  load-bearing rule, not a nice-to-have. The format must be
  migratable from CI without a Godot runtime (or with a
  deterministic, headless one).
- **Tamper detection.** A save file is, by definition, an
  attacker-controlled file once it leaves the player's disk. The
  format must reject tampering without becoming an obfuscation
  system (we are GPL-3.0-or-later — obfuscation is also legally
  awkward).
- **Mod-friendliness.** §25 lists "mod-data schema versioning
  detail" alongside save format. The two must agree.

## Considered options

1. **Human-readable JSON, versioned, content-agnostic, with a
   SHA-256 integrity check** (this). Top-level keys for
   `format_version`, `save_version`, `engine_version`, and the
   canonical body.
2. **Godot `Resource`-serialised binary (`.tres` / `.res`).**
   Rejected: requires Godot to read, ties the format to the
   engine version, makes the file opaque to the player, and makes
   migration-testable format evolution hard.
3. **Custom binary with a header and length-prefixed records.**
   Rejected: not human-readable, harder to migrate, harder to
   mod. None of the "must" requirements demand it.
4. **SQLite or another embedded database.** Rejected: a database
   is overkill for a single-player, single-player, no-concurrent-
   write use case, and it pushes the format into a binary
   dependency that the player would have to install separately
   to inspect their save.

## Decision outcome

Chosen option: **Human-readable JSON, versioned, content-agnostic,
with a SHA-256 integrity check and an explicit `engine_version`
string for migration support.**

### Canonical shape

A PitPact save file is a single JSON object with the following
top-level keys. Every key is required. Loading code must reject
saves that are missing any required key.

```jsonc
{
  // Integer. The save-format schema version. Bumped only when the
  // shape of `body` changes in a way that needs migration.
  // ADR-0003 pins format_version 1.
  "format_version": 1,

  // Integer. The save-content version, owned by `src/save/`. Bumped
  // whenever the contents of `body` change meaning. Independent of
  // the engine version and the game data version.
  "save_version": 1,

  // String. The engine build identifier that wrote the save
  // (e.g. "0.1.0+gc82f655"). Used for migration support: a save
  // from an older engine can be loaded by a newer engine, and a
  // save from a *newer* engine can be rejected with a friendly
  // "this save is from a newer version of the game" message.
  "engine_version": "0.1.0+gc82f655",

  // String. The content-data version that this save was authored
  // against. Independent of `save_version` so that content patches
  // do not invalidate old saves.
  "content_version": "1.0.0",

  // String. Lowercase ISO 8601 UTC timestamp at which the save
  // was written. Informational only; never used for migration.
  "written_at": "2026-07-13T11:30:00Z",

  // String. The seed used to start the campaign. The same seed
  // MUST reproduce the same generator output. This is the bridge
  // to §7 (procedural generation) and §16 (deterministic
  // replay).
  "seed": "57829837811946439648b635be231549c2dc6f06",

  // Object. The canonical game-state body, content-agnostic. The
  // shape of `body` is the only thing `format_version` describes.
  // See "The body contract" below.
  "body": { /* … */ },

  // String. Lowercase hex SHA-256 of the canonical-JSON form of
  // every key EXCEPT `checksum`, with keys sorted lexicographically
  // and no whitespace. See "Integrity check" below.
  "checksum": "9f2b…(64 hex chars)"
}
```

### The body contract

The `body` key holds the canonical game-state payload. Its shape
is described by `format_version`:

- The body is a JSON object.
- The body is **content-agnostic**: it does not know about Godot
  `Resource`, `PackedScene`, `Image`, or any other engine
  type. Concrete types live behind a serialization layer in
  `src/save/`. When the body is serialised, Godot types are
  flattened to their canonical JSON representation; when the
  body is deserialised, the canonical JSON is re-hydrated back
  into Godot types by the adapter that produced it.
- The body's top-level keys are namespaced by subsystem. The
  namespace is owned by the subsystem that wrote it. For M1 the
  body is a single `{"world": {…}, "sim": {…}}` pair; later
  milestones may grow it without bumping `format_version` as
  long as the existing keys keep their shape and meaning.
- Optional subsystems are absent from the body, not present
  with a null value. This keeps the diff small and the migration
  table simple.

### Integrity check

The `checksum` is a lowercase-hex SHA-256 over the canonical-JSON
form of the save *with `checksum` removed and with keys sorted
lexicographically and no insignificant whitespace*. The canonical
form is computed by:

1. Building a `Dictionary` of every key in the save *except*
   `checksum`.
2. Serialising that dictionary with `JSON.stringify(dict, "", 0)`
   (no indentation, no insignificant whitespace).
3. Hashing the resulting string with SHA-256.

`src/save/` exposes a single function
`compute_canonical_hash(save: Dictionary) -> String` that
implements this exactly. Both the writer and the reader call it,
so a round-trip write → read produces an identical checksum.

The check is **integrity, not authenticity**: a player can still
edit their save in a text editor. That is the point. What the
check buys is:

- Detection of accidental corruption (truncated downloads,
  disk-full writes, file-system corruption).
- A single, mechanically-checkable field that downstream tools
  (sav-editor scripts, modding pipelines) can rely on.
- A free migration test: the test serialises a fixture save,
  loads it, mutates one field, and asserts the checksum no
  longer matches.

We do **not** use the checksum as a DRM mechanism, an
obfuscation layer, or a signature scheme. Players own their
saves; if they want to edit them, that is their right
(§12, §19).

### Versioning rules

- `format_version` is bumped *only* when the shape of `body`
  changes in a way that is not backward-compatible at the JSON
  level (a key removed, a key's type changed, a structural
  re-organisation). Bumping `format_version` is a breaking
  change and requires a new ADR.
- `save_version` is bumped when the *meaning* of a value
  changes (a room's `state` enum gains a new variant, a
  resource's units change). Bumping `save_version` does not
  require a new ADR but does require a new entry in
  `src/save/MIGRATIONS.md`.
- `engine_version` and `content_version` are informational and
  are *never* used to gate loading. They are written for
  diagnostics and for the player-facing "this save is from a
  different version of the game" message.

### The migration contract

Every load goes through a migration chain. The chain is a list
of pure functions, each shaped
`migrate_<from>_to_<to>(body: Dictionary) -> Dictionary`,
stored in `src/save/migrations/`. The loader:

1. Reads `format_version` and `save_version`.
2. Looks up the chain that takes the read versions to the
   versions the running code understands.
3. Applies each migration in order, asserting that the output
   is a valid body for the target version.
4. Re-checks the checksum *after* the chain. If the chain
   changed the body, the writer is responsible for the new
   checksum; the reader does not enforce that the checksum
   matches the *post-migration* body. This is by design: a save
   that has been migrated is, by definition, no longer byte-
   identical to the one that was written.

A migration that fails (throws, returns a non-Dictionary,
returns a body that fails schema validation) aborts the load
with a player-facing error. The load is *not* partially
applied: a half-migrated realm is a worse outcome than no
realm at all.

### What is rejected

The following are explicitly **not** allowed:

- **Any binary-only format.** Saves are text. A player can open
  them in any editor. A grep can find anything in them. This is
  a hard rule.
- **Any format without explicit versioning.** A save without
  `format_version` and `save_version` is rejected. There is no
  "v0" implicit format.
- **Any format that requires Godot to read.** The migration
  tests run in CI; the migration table is a list of pure
  functions. A format that can only be parsed by Godot forces
  the migration tests to be end-to-end Godot runs, which
  violates §18's "fast local suite" rule.
- **Any format that embeds Godot `Resource` internals.** The
  body is a JSON object whose keys are subsystem-namespaced
  strings, numbers, booleans, arrays, and nested objects. A
  Godot `Resource` is not a JSON object. If we need to store
  one, the `src/save/` adapter flattens it.
- **Any format that uses the checksum as obfuscation or DRM.**
  The checksum is an integrity check, not a secret. The hash
  function is SHA-256 with no key.
- **Any format that silently drops unknown keys on load.**
  Unknown keys are preserved on round-trip, so that a future
  tool can read an older save without losing data. The loader
  warns on unknown keys but does not fail.

### Consequences

- Good, because the format is text. A save is a file the player
  can read, diff, back up, version-control, and migrate with
  shell tools.
- Good, because migration is a list of pure functions in
  `src/save/migrations/`. Every migration gets a regression
  test that loads a fixture save from the previous version
  and asserts the post-migration body.
- Good, because the content-agnostic body contract means a save
  from a modded content set is structurally identical to a save
  from a vanilla content set. The mod layer is a separate
  concern (see ADR-0002 — `src/content` is a thin data
  adapter over `src/core`).
- Good, because the integrity check catches the boring failure
  modes (truncated downloads, partial writes) without becoming
  an obfuscation system.
- Bad, because human-readable JSON is larger than a binary
  format. For a single-player game with one save per slot this
  is irrelevant; the M5 worst-case save is well under 1 MB.
- Bad, because the migration chain is a contract we have to
  honour forever. That is the point of the contract, and we
  accept the cost.
- Bad, because `JSON.stringify` in GDScript 4.3 does not have
  a built-in "sort keys" option. We implement the canonical
  serialiser ourselves in `src/save/canonical_json.gd` and
  unit-test it.

### Confirmation criteria

This ADR is considered effective when:

- [ ] `src/save/` exists with a `README.md` following the §17
      contract and a `canonical_json.gd` whose `stringify` is
      unit-tested for key-ordering and whitespace.
- [ ] `src/save/migrations/` exists, even if it currently
      contains only a no-op `migrate_1_to_1.gd`.
- [ ] `tests/save/test_save_format.gd` exists, with at least:
      (a) a round-trip write/read test,
      (b) a checksum-mismatch rejection test, and
      (c) a "future version is rejected with a friendly error"
      test.
- [ ] The shape documented above is implemented exactly. Any
      deviation requires a new ADR.

## Pros and cons of the options

### Human-readable JSON, versioned, content-agnostic, SHA-256 integrity

- Good, human-readable.
- Good, forward- and backward-compatible.
- Good, migration-testable from a shell script.
- Good, content-agnostic.
- Good, integrity check.
- Bad, larger than a binary format. (Acceptable.)

### Godot `Resource`-serialised binary

- Good, smallest on disk.
- Good, reuses engine machinery.
- Bad, requires Godot to read.
- Bad, opaque to the player.
- Bad, ties the format to the engine version.
- Bad, migration-testable only with a headless Godot, which
  slows the local suite.

### Custom binary with a header and length-prefixed records

- Good, compact.
- Good, no Godot dependency for the writer.
- Bad, not human-readable.
- Bad, harder to migrate; harder to mod.
- Bad, has no integrity check that survives being open-coded.

### SQLite or another embedded database

- Good, queryable.
- Good, transactional.
- Bad, a database engine is a binary dependency the player has
  to install to inspect their save.
- Bad, overkill for a single-player, single-writer use case.
- Bad, opaque on disk.

## More information

- `docs/requirements.md` §12 (difficulty and saving),
  §16 (technical architecture), §18 (testing and local quality
  gates), §19 (security, privacy, and data handling),
  §20 (open source, assets, and IP compliance),
  §25 (open design decisions).
- ADR-0001 (record architecture decisions).
- ADR-0002 (module boundaries) — the `src/save` module boundary.
- `src/save/README.md` (lands with this ADR).
- `src/save/canonical_json.gd` (lands with this ADR).
- `tests/save/test_save_format.gd` (lands with this ADR).
- `src/save/MIGRATIONS.md` (lands with this ADR; initially
  empty).
