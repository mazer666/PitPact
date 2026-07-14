# PitPact Localization Conventions

> Status: **M0 template**, enforced from M1 onward. This document
> defines how user-visible strings are externalized, named,
> versioned, and validated. It is the operational companion to
> §15 of [`docs/requirements.md`](requirements.md) and to the
> `src/audit/` event-log conventions in ADR-0002.

## Why a separate document

Every user-visible string is a localization key, not an English
literal. Strings concatenated in code, hard-coded English in
scenes, and ad-hoc translations all become debts the project pays
later: a translated game with missing German, a renamed menu
that breaks the German build, a content cut that lands in only
half the locales. The rules below make that debt zero.

## File layout

```
locales/
  source_strings.csv   # the single source of truth, English
  en.po                # the compiled English catalogue
  de.po                # the compiled German catalogue
  *.pot                # (optional) translation template
```

The runtime loads `en.po` and `de.po` (or whichever catalogue the
project ships) via Godot's built-in `TranslationLoaderPO`. The
key set is the union of keys in `source_strings.csv` and the
catalogue files; `tools/validate_locale.sh` enforces the
correspondence.

## The source of truth

`locales/source_strings.csv` is the canonical list of all
user-visible strings, with the columns:

| Column | Type | Notes |
|--------|------|-------|
| `id` | `String` | The locale key. `SCREAMING_SNAKE_CASE`, with a section prefix. |
| `source` | `String` | The English text. |
| `context` | `String` | One short sentence on where the string is shown, who says it, or what tone it carries. Used by translators to disambiguate. |

The CSV is the **only** place where English text lives. Catalogue
files are derived from it. The flow:

1. A contributor adds or edits a string in
   `source_strings.csv`. The `id` is set or reused.
2. `tools/validate_locale.sh` regenerates `en.po` and
   `de.po` from the CSV (using `msgcat` or a small Python
   helper).
3. CI fails if any key in the CSV is missing from a catalogue,
   or any catalogue has a key that is not in the CSV, or any
   placeholder `{x}` differs between source and target.

The CSV is the contract. The catalogues are an artifact.

## Naming

- Keys are `SCREAMING_SNAKE_CASE`.
- A two- or three-letter section prefix anchors the key to a
  region of the game:
  - `UI_*` — menu labels, tooltips, dialog buttons.
  - `EVENT_*` — event-log lines and event headlines.
  - `CREATURE_*` — creature names and one-line descriptions.
  - `ROOM_*` — room names, room short blurbs.
  - `RES_*` — resource category names and short hints.
  - `BIOME_*` — biome names and narrative hooks.
  - `ORIGIN_*` — Pactmaker origin names and one-liners.
  - `ADVISOR_*` — recurring character voice lines.
- Within a section, sub-groups use a second underscore:
  `UI_MENU_START`, `EVENT_RAID_TITLE`, `EVENT_RAID_BODY`,
  `CREATURE_LANTERNBEARER_NAME`, `CREATURE_LANTERNBEARER_DESC`.

## Placeholders

Strings can carry placeholder tokens, using `{}`-style syntax.
The order is positional, but **named placeholders** are
preferred where ordering matters to translators:

- Positional: `"You have {0} workers and {1} food."`
- Named: `"You have {workers} workers and {food} food."`

The validator checks:

- Every `{...}` token in the source string is present verbatim
  in every catalogue translation.
- The set of placeholders is identical across locales. A
  translation that drops a placeholder is rejected.

## Concatenation and string fragments

Concatenated fragments are not allowed:

```gdscript
# Bad: produces an untranslatable runtime string.
label.text = "You have " + str(workers) + " workers."
```

The fix is one string with a placeholder:

```gdscript
# Good: the key is a single translation unit.
label.text = tr("UI_STATUS_WORKERS_COUNT") % {"workers": workers}
```

The `tr()` call returns the localized string; the `%` operator
substitutes the placeholder. The same call works for the German
catalogue without code change.

This rule is enforced by `gdlint` and code review. The
`tools/validate_locale.sh` script cross-checks the `source_strings.csv`
coverage: if a key is referenced via `tr("FOO")` in code, the
`FOO` key must be in the CSV, and the CSV's English must match
the `tr("FOO")` argument.

## Pluralization

Godot's `tr_n()` function handles plural categories via the
catalogue's `Plural-Forms` header. The convention:

```gdscript
# Good: the function picks the right form by count.
label.text = tr_n("UI_STATUS_WORKER_COUNT_S", "UI_STATUS_WORKER_COUNT_P", workers)
```

The `_S` suffix marks the singular form, `_P` the plural. Both
keys live in `source_strings.csv` with their own `source`
strings.

## Gender and formality

PitPact avoids gendered assumptions in the source strings. Where
a culture has gendered vocabulary (planned for M5), the
catalogue has separate keys per gender:

- `CREATURE_LANTERNBEARER_GREET_MASC`
- `CREATURE_LANTERNBEARER_GREET_FEM`
- `CREATURE_LANTERNBEARER_GREET_NEUTRAL`

The runtime picks the right key by the speaker's gender, not by
branches in code. The CSV records the gender context in the
`context` column.

## Voice and character names

- Recurring character names are `LocalizedString`s, not string
  literals. The catalogue's `ADVISOR_FENWICK_NAME` carries the
  display name.
- The `advisor_quotes/` directory (planned for M1) holds
  per-character line files. The runtime picks a line by quote
  key; the key is what gets localized, not the line itself.

## Translation workflow

1. A developer changes English. The change is to
   `source_strings.csv` first, then the catalogue.
2. A translator changes German. The change is to `de.po` only.
   The CSV is updated as a follow-up if the English text
   changed at the same time.
3. CI fails if the CSV and the catalogues disagree.

For a new language (planned for M5 and beyond), the workflow is:

1. Add a new column or per-language CSV in `source_strings.csv`.
2. Generate the empty `xx.po` from the CSV.
3. Translate the strings in `xx.po`.
4. Wire the new locale into the project's locale settings
   (`project.godot` `[internationalization]` section).

## Validation

`tools/validate_locale.sh` runs as part of the local quality
suite. It checks:

- Every key in `source_strings.csv` is present in `en.po` and
  `de.po`.
- Every key in `en.po` and `de.po` is in `source_strings.csv`
  (the catalogues do not silently drop or add strings).
- Placeholders are preserved verbatim.
- No concatenated-fragment pattern is detected in the source
  strings (e.g. a string ending in ` ` followed by a key whose
  English starts in lowercase is flagged for human review).
- `msgfmt -c` confirms the PO files are valid.

## Removing a string

Removing a string from `source_strings.csv` is a breaking change
for the locales. The rule:

1. Mark the key as `deprecated` in the CSV's `context` column
   for at least one release cycle.
2. Remove the key from the CSV in the next milestone.
3. The `de.po` and `en.po` continue to load the deprecated key
   for at least one milestone; the loader logs a warning when
   a deprecated key is referenced at runtime.
4. The deprecated keys are removed in the milestone after that.

This is the project's analogue of Java's `@Deprecated` or
Rust's `#[deprecated]`. The goal is to give translators time
to see the deprecation before the string is gone.

## See also

- [`docs/code-style.md`](code-style.md) — the `tr()` rule in
  context.
- [`docs/style-bible.md`](style-bible.md) — tone rules that
  apply to the English source strings.
- [`docs/data-schema.md`](data-schema.md) — the
  `LocalizedString` field type used throughout the content
  schema.
- [`docs/requirements.md`](requirements.md) §15 — the
  product-level localization commitment.
