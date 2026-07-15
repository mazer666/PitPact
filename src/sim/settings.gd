# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — settings carrier (M4 foundation).
#
# `Settings` is the per-realm data carrier for
# the player's chosen *difficulty and
# preferences* (§12 of `docs/requirements.md`:
# "Narrative, Balanced, Challenging" presets,
# per-rule adjustment, free local save/load).
# The M4 foundation commit ships the carrier
# as a SKELETON: the public surface
# (`difficulty`, `auto_resolve_days`, `locale`,
# `from_dict`, `to_dict`) is a full
# implementation.
#
# The carrier is a *state* carrier, not a
# *content* carrier. The content side of the
# settings (per-difficulty knob definitions,
# per-locale strings) lives in
# `src/content/` (M4 Track A dependency) and
# in `locales/` (the localization layer); the
# `Settings` carrier is the per-realm
# *instance* the realm façade holds and the
# save body round-trips.
#
# Per ADR-0002, this file does not import
# from `src/ui`, `src/realm`, or `src/save`.
# It imports from `src/core` only.
class_name Settings
extends RefCounted

## The difficulty enum values. The M4
## default is three presets: `0`
## (Narrative), `1` (Balanced), `2`
## (Challenging). The enum is the
## canonical integer range; the
## constant names are the readable
## aliases. The M5 content pass can
## add more presets by widening the
## range (the carrier's `difficulty`
## field is an `int`, not an `enum`,
## so a future preset is a new
## integer, not a class change).
const DIFFICULTY_NARRATIVE: int = 0
const DIFFICULTY_BALANCED: int = 1
const DIFFICULTY_CHALLENGING: int = 2

## The canonical "no auto-resolve"
## sentinel. The M2 contract
## (`auto_resolve_days == 0` means
## "no auto-resolve") is preserved;
## the constant is a class-level
## alias for the integer value.
const AUTO_RESOLVE_OFF: int = 0

## The player's chosen difficulty
## preset, in `0..2`. The M4 default
## is `DIFFICULTY_BALANCED` (`1`).
## The save/load pipeline
## (ADR-0003) round-trips the value
## at `body.settings.difficulty`.
var difficulty: int = DIFFICULTY_BALANCED

## The number of in-game days the
## player is willing to wait before
## the per-tick rule auto-resolves a
## player-driven crisis. The M4
## default is `7`; a value of `0`
## disables auto-resolve (the M2
## contract is preserved). The M5
## content pass can override the
## default through the per-realm
## settings file.
var auto_resolve_days: int = 7

## The realm's chosen locale. The
## M4 default is `"en"` (English).
## The locale is the canonical key
## for the localization layer
## (`docs/localization.md`); the
## M2 contract is preserved.
var locale: String = "en"


## Default constructor. Starts with
## the M4 defaults: Balanced
## difficulty, `7` auto-resolve
## days, English locale.
func _init() -> void:
	difficulty = DIFFICULTY_BALANCED
	auto_resolve_days = 7
	locale = "en"


## Static factory. The canonical way
## to construct a `Settings` from a
## save body. The factory copies
## every field; the input `d` is
## not mutated. A `null` or
## non-`Dictionary` argument returns
## a fresh `Settings` with the M4
## defaults (the M4 default is
## "lenient parse": a missing
## settings slot falls back to
## the M4 defaults, the migration
## registry's job is to walk the
## version chain).
##
## The M4 foundation commit ships
## the factory as a full
## implementation; the M4 Track A
## commit's settings UI uses this
## factory to construct the
## per-realm settings from the
## player's choices.
static func from_dict(d: Dictionary) -> Settings:
	var s: Settings = Settings.new()
	if d == null:
		return s
	if not (d is Dictionary):
		return s
	if d.has("difficulty") and d["difficulty"] is int:
		s.difficulty = clampi(int(d["difficulty"]), DIFFICULTY_NARRATIVE, DIFFICULTY_CHALLENGING)
	if d.has("auto_resolve_days") and d["auto_resolve_days"] is int:
		s.auto_resolve_days = maxi(0, int(d["auto_resolve_days"]))
	if d.has("locale") and d["locale"] is String:
		s.locale = String(d["locale"])
	return s


## Serialize the settings to a
## `Dictionary` the save body stores
## at `body.settings`. The result
## has the canonical keys
## (`difficulty`, `auto_resolve_days`,
## `locale`). The `Dictionary` is a
## fresh container; mutating the
## result after `to_dict()` returns
## does NOT mutate the carrier.
##
## The method is the canonical
## "snapshot for save" path; the
## M5 replay feature uses the
## snapshot to rebuild a campaign
## from a saved event log. The M4
## foundation commit ships the
## method as a full implementation;
## the M5 content pass extends the
## carrier with more settings keys
## (and the save body with more
## `body.settings.*` slots).
func to_dict() -> Dictionary:
	return {
		"difficulty": difficulty,
		"auto_resolve_days": auto_resolve_days,
		"locale": locale,
	}
