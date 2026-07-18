# ADR-0017 — M5-Closeout: Six Cultures, Ten Rooms, Fifteen Events, Success/Failure/Restart, en/de, Audio

- Status: Accepted
- Date: 2026-01
- Authors: PitPact contributors
- Phase: M5-Closeout (vertical campaign completion)
- Supersedes: ADR-0015 (M5-Foundation), ADR-0016 (M5-Real-UI-Assets)
- Related: ADR-0005 (Determinismus), ADR-0010 (M3-Closeout), docs/style-bible.md

## Context

M5-Foundation (ADR-0015) lieferte die *kanonische* PlayableShell mit Sim, World, Inhabitants, Crises, Pactmaker, Factions, Settings. M5-Real-UI-Assets (ADR-0016) lieferte die *echte* .tscn mit prozeduralen Tiles, UI-Theme, Portraits, Crisis-Icons, Power-Icons. Beide Phasen zusammen ergeben ein *technisch* spielbares Skelett: 2 Inhabitants, 1 Power-Pfad, 2 Crises, 1 TileSet-Atlas mit 8 Cells.

**M5-Closeout** bringt das Skelett auf den M5-Scope: **six cultures, ten rooms, fifteen events, complete success/failure/restart loop, English/German, audio pass**. Die Definition-of-Done steht in `docs/milestones.md` §"M5". Diese ADR pinnt den Scope *konkret* und testbar — sonst ist "M5-Closeout" ein moving target.

## Decision

M5-Closeout wird in **sechs orthogonalen Buckets** geliefert. Jeder Bucket hat eine Definition-of-Done mit *testbaren* Kriterien. Die Buckets sind nach Leverage sortiert: erst Game-Feel (Cultures + Crises), dann Content (Rooms + Events), dann Polish (i18n + Audio), dann Loop (Success/Failure/Restart).

### Bucket 1 — Six Cultures

M4 hat zwei Inhabitant-Rollen (settler, lanternbearer_scribe) mit zwei Portrait-Assets. M5-Closeout erweitert auf **sechs Kulturen** mit je einer Rolle und einem Portrait-Asset. Die 6 Kultur-IDs sind die etablierten `src/sim/cultures/*.gd` IDs (M2 Track A + M3-Closeout Track B Setup):

| # | Kultur | Rolle | Portrait | Special |
|---|---|---|---|---|
| 1 | Lanternbearer | scribe | `lanternbearer_scribe.png` | night-vision bonus |
| 2 | Bellows | bellows-tender | `bellows.png` | forge-boost |
| 3 | Ember | fire-keeper | `ember.png` | hearth-stability |
| 4 | Ledger | scribe-archivist | `ledger.png` | research-boost |
| 5 | Silvershroud | oath-keeper | `silvershroud.png` | pact-stability |
| 6 | Tide | tide-reader | `tide.png` | marsh-navigation |

**Definition-of-Done**:
- `data/cultures/` listet 6 .tres Files mit `id`, `display_name`, `body_form`, `values`.
- 4 neue Portrait-PNGs prozedural generiert (bellows, ember, ledger, silvershroud, tide — 5 neue, lanternbearer existiert).
- `PlayableShell.build()` zieht 6 Inhabitants (eine pro Kultur), SEED-pinned.
- Test `test_six_cultures` pinnt die kanonische Anzahl + alle 6 IDs.

### Bucket 2 — Ten Rooms

M4 hat 1 Tile (`hearth`). M5-Closeout erweitert den Tile-Atlas auf **10 Räume**:

| # | Raum | Tile-Asset | Effect |
|---|---|---|---|
| 1 | floor_stone | `floor_stone.png` | baseline floor |
| 2 | floor_marsh | `floor_marsh.png` | slow movement |
| 3 | floor_highland | `floor_highland.png` | fast movement |
| 4 | wall_stone | `wall_stone.png` | barrier |
| 5 | hearth | `hearth.png` | rest bonus |
| 6 | fog | `fog.png` | vision-blocker |
| 7 | shrine | `shrine.png` | ritual site |
| 8 | forge | `forge.png` | crafting speedup |
| 9 | well | `well.png` | water source |
| 10 | trap | `trap.png` | crisis-amplifier |

**Definition-of-Done**:
- `data/rooms.json` listet 10 Räume mit `id`, `tile_id`, `effect`.
- 4 neue Tile-PNGs prozedural generiert (shrine, forge, well, trap).
- `assets/tiles/world_tileset.tres` TileSet-Atlas erweitert von 4x2 auf 4x3 (12 Cells, 2 Reserved).
- `WorldTileMapLayer.tile_id_to_atlas_coord()` Map-Update: tile 8..11 → (col, row 2).
- Test `test_ten_rooms` pinnt die kanonische Anzahl + alle 10 IDs.

### Bucket 3 — Fifteen Events

M4 hat 2 Crises (plague_outbreak, faction_dispute). M5-Closeout erweitert auf **15 zufällige Events**:

| # | Event | Type | Effect |
|---|---|---|---|
| 1 | plague_outbreak | crisis | -HP per inhabitant |
| 2 | faction_dispute | crisis | -cohesion |
| 3 | fog_rolls_in | crisis | -vision |
| 4 | marsh_bubbles | crisis | slow movement |
| 5 | highland_rockslide | crisis | -masonry |
| 6 | shrine_smoke | narrative | reveal hint |
| 7 | forge_spark | narrative | crafting boost |
| 8 | well_dry | crisis | -water |
| 9 | trap_sprung | crisis | -HP |
| 10 | pactmaker_whispers | narrative | -power |
| 11 | settler_arrives | good | +inhabitant |
| 12 | trader_passes | good | +resources |
| 13 | oathkeeper_returns | good | -crisis risk |
| 14 | marsh_heals | good | marsh recovery |
| 15 | highland_path_opens | good | navigation |

**Definition-of-Done**:
- `data/events.json` listet 15 Events mit `id`, `type` (crisis|good|narrative), `effect`.
- `CrisisSystem` und `EventSystem` getrennt: Crises sind negative random events; Events sind alle Typen.
- `M5Events` Carrier mit `roll_event(sim) -> Event`-Methode.
- Test `test_fifteen_events` pinnt die kanonische Anzahl + alle 15 IDs + SEED-pinned Outcome.

### Bucket 4 — Success/Failure/Restart Loop

M4 hat keinen Game-Over-Pfad. M5-Closeout liefert:

- **Win condition**: 30 Tage überleben, 1 hearth + 1 shrine + 1 forge + 1 well + 1 trap, mind. 4 Inhabitants.
- **Lose condition**: 0 Inhabitants, 0 hearth, oder 30 Tage nicht überlebt.
- **Restart loop**: Game-Over-Banner mit "Restart" + "Quit" Buttons; Restart ruft `PlayableShell.build()` mit neuem SEED.

**Definition-of-Done**:
- `M5GameState` Carrier mit `check_win_condition(sim) -> bool`, `check_lose_condition(sim) -> bool`.
- `GameOverBanner` UI-Element (Panel mit rotem Background, Title + Summary + 2 Buttons).
- `PlayableShellUI._on_restart_pressed()` ruft `build()` mit neuem SEED.
- Test `test_game_over_loop` pinnt Win + Lose + Restart-Behavior.

### Bucket 5 — English/German Localization

M4 hat keine i18n. M5-Closeout liefert:

- `addons/i18n/` Setup (oder Godot's built-in `Localization`/`Translation`).
- `i18n/en.po` und `i18n/de.po` mit allen UI-Strings.
- `PlayableShellUI` liest Strings via `tr("KEY")` statt hard-coded.

**Definition-of-Done**:
- `i18n/en.po` und `i18n/de.po` haben mind. 30 Schlüssel.
- `ProjectSettings` aktiviert `internationalization/locale/translations_pot_files`.
- Test `test_localization_keys_complete` prüft, dass alle `tr()`-Keys in beiden `.po`-Dateien vorhanden sind.

### Bucket 6 — Audio Pass

M4 hat keinen Audio. M5-Closeout liefert:

- `tools/assets/generate_audio.gd` prozeduraler SFX-Generator (Godot 4.7 hat keinen built-in synth; wir nutzen `AudioStreamGenerator` mit PCM-Daten).
- 5 SFX: `step.wav`, `power_seal.wav`, `power_pause.wav`, `crisis_horn.wav`, `game_over.wav`.
- 1 Ambient-Track: `ambient_loop.wav` (10 sec, looping).

**Definition-of-Done**:
- 5 SFX + 1 Ambient-Track prozedural generiert, SEED-pinned.
- `AudioStreamPlayer` Nodes in `PlayableShell.tscn` für Step + Crisis + Ambient.
- Test `test_audio_assets_present` prüft, dass alle 6 .wav Files existieren und non-zero size.

## Consequences

### Positive

- M5-Scope ist *konkret* testbar — kein moving target mehr.
- 6 Buckets sind unabhängig: ein Coder pro Bucket, parallel testbar.
- Best-in-Class bleibt enforced: jeder Bucket hat DoD + tests + mutation-sweep.

### Negative / Tradeoffs

- M5-Closeout ist *groß* — 6 Buckets, 50+ neue Files, 50+ neue Tests. Erwartete Commits: 3-4 (einer pro 2 Buckets).
- i18n + Audio sind high-effort, low-payout (für ein pre-release Spiel). Wenn der User priorisiert, kann Bucket 5+6 auf M6 verschoben werden.

## Validation (pro Bucket)

- **Quality gate**: `tools/run_quality.sh` → ALL CHECKS PASSED ✓
- **GUT headless**: 184 + 50-80 neue Tests = 240+ Tests, 1500+ Asserts (Schätzung)
- **Mutation sweep (M5-Closeout)**: ≥ 20/20 mutations REAL, 0 silent
- **Build**: `godot --headless --path . --import` exit 0, alle PNGs + WAVs non-zero size

## Prio-Order

1. **Bucket 4 (Success/Failure/Restart)** — DONE (commit 4d206a0).
2. **Bucket 1 (Six Cultures)** — high content, gives the inhabitants variety.
3. **Bucket 3 (Fifteen Events)** — high replayability, reuses M4 crisis-mechanics.
4. **Bucket 2 (Ten Rooms)** — atlas extension, low cost (just sprites + mapping).
5. **Bucket 5 (en/de i18n)** — important for EU audience, but more work.
6. **Bucket 6 (Audio)** — nice-to-have, can defer to M6.

## References

- ADR-0015 — M5-Foundation
- ADR-0016 — M5-Real-UI-Assets
- ADR-0010 — M3-Closeout (similar structure)
- docs/milestones.md §"M5"
- docs/style-bible.md §2.2 (Gothic-Fantasy Dark Palette)
