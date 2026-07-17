# ADR-0016 — M5: Echte UI mit prozeduralen Assets

- Status: Accepted
- Date: 2026-01
- Authors: PitPact contributors
- Phase: 2.5 (echte UI mit wirklichen Assets)
- Supersedes: none
- Related: ADR-0015 (M5-Foundation), ADR-0005 (Determinismus), docs/style-bible.md §2.2

## Context

M5-Foundation (ADR-0015) lieferte eine *code-driven* `PlayableShellUI`: alle Panels, Buttons, Labels und der Crisis-Banner wurden zur Laufzeit in `_ready()` aus GDScript-`new()`-Aufrufen aufgebaut. Die M5-Foundation war deterministisch und testbar, aber sie hatte drei Best-in-Class-Lücken:

1. **Keine visuellen Assets.** Die UI zeigte *Text* ("Step", "Auto-tick", "Day 0") statt *Grafik* (Tile-Sprites, Portrait-Frames, Crisis-Icons, Button-Icons). Die Best-in-Class-Player-Experience benötigt ein erkennbares Pixel-Look-and-Feel.
2. **Keine echte `.tscn`.** Die UI lebte nur im Speicher; das `scenes/main/`-Verzeichnis war leer. Das ist ein Repositorium-Smell (kein kanonischer Spielstand-Editor-Entry-Point).
3. **Kein Theme.** `Control`-Defaults sehen aus wie eine leere `default_theme.tres`. Das widerspricht `docs/style-bible.md` §2.2 (Gothic-Fantasy Dark Palette).

## Decision

Phase 2.5 schließt die drei Lücken mit **prozedural generierten Assets** und einer **echten `PlayableShell.tscn`**. Die Best-in-Class-Constraints bleiben:

- **Kein externes IP / keine lizenzpflichtigen Assets.** Per `docs/requirements.md` §20 muss alles im Sandbox-Container ohne Netzwerk-Zugriff auf Asset-Repos generiert werden. Wir nutzen Godots `Image` + `save_png` API.
- **Determinismus.** Per ADR-0005 muss der Asset-Generator SEED-pinned sein. `tools/assets/generate_assets.gd` ruft `seed(SEED)` als erstes auf; das Skript ist idempotent.
- **Editor-Import.** Godot erkennt PNGs erst nach einem `--import`-Lauf und dem Schreiben von `.png.import`-Sidecars. Wir committen die `*.import` Files mit.
- **Gothic-Fantasy Dark.** Die Palette (`ink`, `parchment`, `stone`, `moss`, `ember`, `gold`, `blood`, `bone`, `fog`, `marsh`, `highland`, `violet`) ist in `tools/assets/generate_assets.gd` als `_PAL` Dictionary gepinnt.

### Was Phase 2.5 liefert

| Deliverable | Pfad | Zweck |
|---|---|---|
| Asset-Generator | `tools/assets/generate_assets.gd` | Prozedurale PNG-Generierung, SEED-pinned |
| Tile-Atlas (4x2) | `assets/tiles/atlas_4x4.png` | TileMap-Atlas für `WorldTileMapLayer` |
| TileSet-Resource | `assets/tiles/world_tileset.tres` | `TileSetAtlasSource` mit 8 Cells (floor_stone, floor_marsh, floor_highland, wall_stone, hearth, fog, 2 Varianten) |
| Tile-Singles | `assets/tiles/{floor_stone,floor_marsh,floor_highland,wall_stone,hearth,fog}.png` | 6 PNGs, 16x16 |
| UI-Icons (10) | `assets/ui/{step,auto_tick,save,load,settings,pause,play,power_seal_breach,power_pause_crisis,power_reveal_tile}.png` | Button-Icons |
| Portraits (2) | `assets/inhabitants/{lanternbearer_scribe,settler}.png` | 16x24 Pixel-Portraits |
| Crisis-Icons (2) | `assets/crises/{plague,faction}.png` | 16x16 Crisis-Banner-Icons |
| UI-Theme | `assets/ui/gothic_fantasy_theme.tres` | 7 StyleBoxes (Panel, Button normal/hover/pressed/disabled, Critical-Banner, Hearth-Background) |
| PlayableShell-Scene | `scenes/main/PlayableShell.tscn` | CanvasLayer + TopBar + InhabitantPanel + PactmakerPanel + CrisisBanner + TickControl |
| Asset-README | `assets/README.md` | Pipeline-Doku |

### Architekturentscheidungen

- **TileSet via `TileSetAtlasSource`:** die 8 Cells (4 Spalten x 2 Zeilen) sind im 16x16-Raster. `WorldTileMapLayer.tile_id_to_atlas_coord(id)` mappt `id ∈ [0..7]` deterministisch auf `(id % 4, id / 4)`. Der Test `test_world_tile_map_layer_uses_tileset_resource` pinnt das Mapping.
- **Icon-Pfade sind Power-ID-spezifisch:** `res://assets/ui/power_<id>.png` (z.B. `power_seal_breach.png`). Die UI lädt das Icon per `ResourceLoader.exists()`-Check, sodass fehlende Icons gracefully degradiert werden.
- **Build-once Guard `_built: bool`** schützt vor Doppel-Aufrufen von `build_ui()` (`_ready` + `bind` können beide triggern). Der Test `test_playable_shell_renders_in_viewport` pinnt den "exakt 3 Inhabitant-Rows" Invariant.
- **`format_day_label(day)`** ist die kanonische "Day N" Entry-Point. Der Test `test_playable_shell_format_day_label` pinnt das Format.

## Consequences

### Positive

- Die M5-UI rendert mit echten Sprites + Theme. Der Spieler sieht einen erkennbaren Gothic-Fantasy-Look.
- Die `.tscn` ist der kanonische Editor-Entry-Point. Designer können im Godot-Editor die Scene anpassen, ohne GDScript zu ändern.
- Der Asset-Generator ist deterministisch (SEED-pinned) — Re-Runs produzieren Byte-identische PNGs.
- Der Test-Net ist robust: 6/6 PlayableShell-Scene-Mutationen sind REAL (0 silent-pass).

### Negative / Tradeoffs

- Prozedurale Assets sind nicht "schön" — sie sind funktional. Ein pixelartist-illustrator kann den M5-Closeout mit hand-drawn Assets ersetzen, ohne den Code zu ändern.
- Das TileSet hat nur 8 Cells; das deckt nicht alle M5-Closeout-Features ab (six cultures, ten rooms, fifteen events). Der M5-Closeout erweitert den Atlas.

## Validation

- **Quality gate**: `tools/run_quality.sh` → ALL CHECKS PASSED ✓
- **GUT headless**: 184/184 tests, 1007 Asserts (vorher 172, +12 tests, +41 asserts)
- **Mutation sweep (M5-Scene)**: 6/6 REAL, 0 silent
- **Mutation sweep (M5-Foundation, vor Phase 2.5)**: 7/7 REAL, 0 silent
- **Mutation sweep (M0-M3)**: 16/16 REAL, 0 silent

## Alternatives considered

- **Externe Assets kaufen/licensieren.** Verworfen: §20 verbietet IP/Lizenz-Risiko. Prozedural ist die saubere Lösung.
- **Inline-`Image`-Calls in `PlayableShellUI._ready()`.** Verworfen: würde die UI mit Generator-Code vermischen. Trennung: Generator läuft einmal, UI lädt statische PNGs.
- **SVG-Assets + `SVGTexture`.** Verworfen: Godot 4.7 hat keinen nativen SVG-Loader ohne `godot-svg` Plugin. PNG ist nativ.

## References

- ADR-0005 — Determinismus
- ADR-0015 — M5-Foundation
- ADR-0013 — M4-Hardening
- docs/style-bible.md §2.2 — Gothic-Fantasy Dark Palette
- docs/requirements.md §20 — Asset-/IP-Regeln
- tools/assets/generate_assets.gd — der prozedurale Asset-Generator
- tools/audit/mutation_sweep_m5_scene.gd — der M5-Scene-Mutation-Sweep
