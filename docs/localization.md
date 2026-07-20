# PitPact Localization Conventions

> Status: **M16 final** (post M15 Japanese support, per ADR-0027).
> This document defines how user-visible strings are externalized,
> named, versioned, and validated. The M0 template was filled in
> across M5-Closeout Bucket 5 (en/de) and M15 Side-Quest L (ja).

## Why a separate document

Every user-visible string is a localization key, not an English
literal. Strings concatenated in code, hard-coded English in
scenes, and ad-hoc translations all become debts the project pays
later: a translated game with missing German, a renamed menu
that breaks the German build, a content cut that lands in only
half the locales. The rules below make that debt zero.

## Supported locales

The M15 closeout ships **3 locales**:

| Code | Language | Status | Shipped in |
|------|----------|--------|------------|
| `en` | English | ✅ Source language | M0+ |
| `de` | German (Deutsch) | ✅ First translation | M5-Closeout Bucket 5 |
| `ja` | Japanese (日本語) | ✅ Second translation | M15 Side-Quest L |

**Future locales** (planned for M17+):
- `fr` — French
- `zh` — Chinese (Simplified)
- `es` — Spanish
- `ko` — Korean
- `pt` — Portuguese (Brazilian)

## File layout

```
locales/
├── en.po         # English (source)
├── de.po         # German
├── ja.po         # Japanese
└── (more to come)
```

The `*.po` format is **GNU gettext** (`msgctxt`, `msgid`, `msgstr`).
The M15 closeout's `LocalizationManager.translate(key)` uses an
in-memory map; the M17 closeout will integrate the `*.po` files
via Godot's `TranslationServer`.

## Naming conventions

- **Keys** are `SCREAMING_SNAKE_CASE` with hierarchical context
  prefixes:
  - `MENU_*` — menu items (`MENU_START`, `MENU_QUIT`)
  - `GAME_*` — in-game strings (`GAME_DAY`, `GAME_WIN`, `GAME_OVER`)
  - `EVENT_*` — event names + descriptions
  - `CRISIS_*` — crisis names + descriptions
  - `ACH_*` — achievement titles + descriptions
  - `HELP_*` — in-game help topics
  - `ERR_*` — error messages
- **Pluralization** uses the `nplurals=2` gettext standard:
  `msgid_plural` + `msgstr[0]` + `msgstr[1]`.
- **Context** (`msgctxt`) is used to disambiguate strings that
  have the same English form but different translations:
  - `msgctxt "verb"` `msgid "step"` → "step (verb)"
  - `msgctxt "noun"` `msgid "step"` → "step (noun)"

## Format (PO example)

```po
msgid ""
msgstr ""
"Content-Type: text/plain; charset=UTF-8\n"
"Language: de\n"

msgctxt "MENU"
msgid "MENU_START"
msgstr "Start"

msgctxt "MENU"
msgid "MENU_QUIT"
msgstr "Beenden"

msgctxt "GAME"
msgid "GAME_DAY"
msgstr "Tag"
```

## API

The M15 closeout's `LocalizationManager` provides:

```gdscript
var lm: LocalizationManager = LocalizationManager.make()
lm.set_locale("de")
print(lm.translate(&"MENU_START"))  # "Start"
print(lm.translate(&"MENU_QUIT"))   # "Beenden"
print(lm.translate(&"GAME_DAY"))    # "Tag"
```

The M17 closeout will add:

- `tr(key)` integration with Godot's `TranslationServer`
- Auto-detect locale from system (`OS.get_locale_language()`)
- Right-to-Left (RTL) support for Arabic/Hebrew
- Per-line formatting helpers (numbers, dates, plurals)

## Validation

The M15 closeout's `tests/integration/test_m15_localization.gd`
verifies the 3 locales + 18 keys. The M17 closeout will add:

- `tools/i18n_check.py` — validates all `*.po` files have the same
  `msgid` set
- `tools/i18n_lint.py` — flags hard-coded English in scenes
- CI hook — fails the build if a new key is added without translations

## References

- M5-Closeout Bucket 5 — en/de i18n
- M15 Side-Quest L — ja i18n
- ADR-0027 — M15 Final Polish
- `locales/en.po`, `locales/de.po`, `locales/ja.po` (existing)
- `src/i18n/localization_manager.gd` (existing)
- GNU gettext: <https://www.gnu.org/software/gettext/>
- Godot TranslationServer:
  <https://docs.godotengine.org/en/stable/classes/class_translationserver.html>
- `tests/integration/test_m15_localization.gd` (existing)

## Changelog

- **M5-Closeout Bucket 5** — en + de with 36 keys
- **M15 Side-Quest L** — ja added; 18 keys; `LocalizationManager`
- **M16 Doc-Sync** — this document; future-locales roadmap
