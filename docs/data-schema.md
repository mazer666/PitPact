# PitPact Data Schema Conventions

> Status: **M16 final** (post M5-M15 content additions). This
> document defines how content data is shaped, named, versioned,
> and extended. The M0 template was filled in across M5-M15 with
> new datatypes (cultures, events, achievements, chapters, mods,
> save-slot). It is the operational companion to ADR-0003 (save
> format) and the §16.3 module boundary for `src/content/`.

## Why a separate document

Content data — creatures, rooms, resources, biomes, origins,
events, research, contracts, the localizable strings — is the
long-lived surface of the project. A typo in a field name in a
`.tres` file breaks the simulation deterministically. A missing
field in a save roundtrip test breaks every player who has a save
from the previous build. These classes of error are the reason
this document exists: the rules below make them cheap to avoid.

## File layout

```
data/
  rooms/         # Room definitions (Hearth, Workshop, ...)
  resources/     # Resource category definitions (Stone, Fungi, Ember, ...)
  biomes/        # Biome definitions (Hollow, Dustmaze, ...)
  cultures/      # Creature culture definitions (six cultures, M5)
  events/        # Event template definitions
  contracts/     # Contract clause and bargain definitions
  research/      # Research / ritual tree definitions
  origins/       # Pactmaker origin definitions
```

Each subdirectory holds `.tres` files (Godot Resource, for engine
integration) and may also hold `.json` files (for engine-agnostic
data; the loader in `src/content/` is responsible for hydrating
the JSON into the engine type).

## File format

### `.tres` files

`.tres` is Godot's text-resource format. PitPact content uses it
because it round-trips through the editor and the headless build.
The conventions:

- The first non-comment line of every `.tres` is
  `[gd_resource type="<ResourceType>" load_steps=N format=3]`
  where `<ResourceType>` is the schema-defined type (e.g.
  `RoomData`, `ResourceCategoryData`).
- The file's `id` field is a `StringName` in `snake_case` and
  uniquely identifies the datum. The id is what the simulation
  references, not the file name.
- All localised strings are stored as `LocalizedString`
  references (key + source) rather than the resolved English or
  German. The runtime resolves them via the locale system.
- All numeric fields are documented in the schema below. The
  schema is the source of truth; the `.tres` files are
  instances of it.

### `.json` files

Engine-agnostic content is stored as JSON with the same schema
as the `.tres` files. The loader in `src/content/` is responsible
for mapping JSON to the engine type at load time. This indirection
lets us:

- Diff content changes in code review (`.tres` diffs are noisy).
- Test the loader independently of Godot.
- Support a future mod format that does not require Godot.

## Versioning

Every content schema carries a `schema_version: int` field at the
top level. The version increments when a **breaking** change
happens:

- Removing a field.
- Changing a field's type.
- Changing a field's semantic meaning in a way that old data
  would silently mis-render.

Adding a new field with a sensible default is **not** a breaking
change. The schema version stays; the loader is updated to read
the new field, and old data files (which do not have it) fall
back to the default. Save files in the wild keep working.

The full set of migrations is recorded in
`src/content/migrations.gd` (planned for M1) and exercised by
`tests/integration/test_content_migrations.gd`.

## Schemas (M0 baseline)

The schemas below are the M0 baseline. M1+ extends them. Every
field is required unless marked **default**. The id field is
always required and is the primary key.

### RoomData (`data/rooms/*.tres`)

| Field | Type | Notes |
|-------|------|-------|
| `id` | `StringName` | `snake_case`; e.g. `"hearth"`. |
| `display_name` | `LocalizedString` | UI name. |
| `description` | `LocalizedString` | UI short blurb. |
| `build_time_days` | `int` | |
| `labour_cost` | `int` | |
| `materials_cost` | `Dictionary[StringName, int]` | Maps resource id to count. |
| `capacity` | `int` | Default 1. |
| `tags` | `PackedStringArray` | Free-form filter tags. |
| `schema_version` | `int` | Default 1. |

### ResourceCategoryData (`data/resources/*.tres`)

| Field | Type | Notes |
|-------|------|-------|
| `id` | `StringName` | |
| `display_name` | `LocalizedString` | |
| `category` | `StringName` | One of `material`, `food`, `medicine`, `comfort`, `knowledge`, `magical_essence`, `influence`. |
| `base_value` | `float` | Default 1.0. |
| `decay_rate` | `float` | Per-day, 0.0–1.0. Default 0.0. |
| `tags` | `PackedStringArray` | Default empty. |
| `schema_version` | `int` | Default 1. |

### BiomeData (`data/biomes/*.tres`)

| Field | Type | Notes |
|-------|------|-------|
| `id` | `StringName` | |
| `display_name` | `LocalizedString` | |
| `palette_hint` | `PackedColorArray` | Length 3, in display order: ambient, surface, deep. |
| `resource_bias` | `Dictionary[StringName, float]` | Maps resource id to spawn weight. |
| `hazard_bias` | `PackedStringArray` | Hazard ids from `data/events/hazards.tres`. |
| `narrative_anchor` | `LocalizedString` | Story hook visible in the realm inspector. |
| `schema_version` | `int` | Default 1. |

### OriginData (`data/origins/*.tres`)

| Field | Type | Notes |
|-------|------|-------|
| `id` | `StringName` | |
| `display_name` | `LocalizedString` | |
| `starting_powers` | `PackedStringArray` | Power ids from `data/research/*.tres`. |
| `preferred_cultures` | `PackedStringArray` | Culture ids from `data/cultures/*.tres`. |
| `weakness` | `StringName` | A `DataTag` or a content id describing the origin's drawback. |
| `narrative_anchor` | `LocalizedString` | |
| `schema_version` | `int` | Default 1. |

### CultureData (`data/cultures/*.tres`, M5)

Defined in the M5 pass. The field set is the same shape as
`OriginData` plus `body_form`, `movement`, `social_rules`,
`conflict_pattern`. The M0 template reserves the path; the M5
commit populates the actual data and the schema.

### EventData (`data/events/*.tres`, M5-Closeout)

| Field | Type | Notes |
|-------|------|-------|
| `id` | `StringName` | `snake_case`; e.g. `"famine"`. |
| `display_name` | `LocalizedString` | UI name. |
| `description` | `LocalizedString` | UI short blurb. |
| `severity` | `int` | 1-5, default 1. |
| `tags` | `PackedStringArray` | Default empty. |
| `cooldown_days` | `int` | Default 0. |
| `schema_version` | `int` | Default 1. |

### AchievementData (`data/achievements/*.tres`, M14)

| Field | Type | Notes |
|-------|------|-------|
| `id` | `StringName` | `snake_case`; e.g. `"first_hearth"`. |
| `display_name` | `LocalizedString` | UI name. |
| `description` | `LocalizedString` | UI short blurb. |
| `condition_callable` | `StringName` | Path to a static function returning bool. |
| `icon` | `String` | Path to icon. |
| `schema_version` | `int` | Default 1. |

### ChapterData (`data/chapters/*.tres`, M14)

| Field | Type | Notes |
|-------|------|-------|
| `id` | `StringName` | `snake_case`; e.g. `"awakening"`. |
| `display_name` | `LocalizedString` | UI name. |
| `description` | `LocalizedString` | UI short blurb. |
| `required_achievements` | `PackedStringArray` | Achievement ids. |
| `biomes` | `PackedStringArray` | Biome ids. |
| `schema_version` | `int` | Default 1. |

### SaveSlotData (`saves/slot_*.json`, M15)

| Field | Type | Notes |
|-------|------|-------|
| `format_version` | `String` | `"1.0.0"` (per M15) |
| `slot` | `int` | 0-4 (5 slots) |
| `timestamp` | `int` | Unix timestamp |
| `state_hash` | `String` | SHA-256-like hash via M9 CoopProtocol |
| `state` | `Dictionary` | Game state (Map, inhabitants, resources) |
| `metadata` | `Dictionary` | Free-form (player_name, day_count, etc.) |

### HelpTopicData (`help/topics/*.tres`, M16)

| Field | Type | Notes |
|-------|------|-------|
| `id` | `StringName` | `snake_case`; e.g. `"getting_started"`. |
| `title` | `LocalizedString` | UI name. |
| `body` | `LocalizedString` | Body text. |
| `related_topics` | `PackedStringArray` | Topic ids. |
| `context` | `StringName` | e.g. `"gameplay"`, `"co_op"`, `"settings"`. |
| `schema_version` | `int` | Default 1. |

## Forbidden patterns

These are enforced by `tools/check_module_dependencies.sh`,
`tools/format.sh`, and `tools/validate_locale.sh`, plus code
review.

- **No hard-coded resource / biome / origin / culture ids in
  code.** The names appear only in `data/` and in locale files.
  If a piece of code needs the value, it reads it from the
  resource loader.
- **No concatenated-fragment strings in `.tres`.** The
  `display_name` of `"Hearth" + " (V2)"` is not a valid value.
  Use a separate `LocalizedString` per variant.
- **No untyped `Array` or `Dictionary` fields.** If a field
  needs a list, it is a typed `Array[T]` or
  `Dictionary[StringName, T]`.
- **No literal biome names in code.** The simulation reads the
  biome id from the tile and looks up the `BiomeData`; it does
  not have an `if biome == "hollow"` branch.
- **No edits to the `schema_version` of a published schema
  without a migration entry.** Old saves must keep loading.

## Adding a new content type

1. Add a `src/content/<type>.gd` schema with the typed fields
   documented in the M0 template above.
2. Create the directory under `data/<type>/`.
3. Add at least one instance file in `data/<type>/`.
4. Add a test in `tests/integration/test_<type>_load.gd` that
   loads the file and asserts the fields parse to the documented
   types.
5. Update [`docs/requirements.md`](requirements.md) if the
   type is part of the M1+ content list, or the
   [`docs/milestones.md`](milestones.md) if it is part of a
   later milestone's Definition-of-Done.

## See also

- [`docs/code-style.md`](code-style.md) — file format, naming,
  and the no-magic-numbers rule.
- [`docs/localization.md`](localization.md) — how
  `LocalizedString` is stored and resolved.
- [`docs/adrs/0002-module-boundaries.md`](adrs/0002-module-boundaries.md) —
  why `src/content/` is its own module.
- [`docs/adrs/0003-save-format.md`](adrs/0003-save-format.md) —
  the save-format side of the content story.
