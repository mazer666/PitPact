# PitPact — Asset Manifest (M6 Audit)

> Per ADR-0018 §Bucket 5. This file
> records every asset shipped in the
> M6 release with its license, source,
> and audit status. The manifest is
> the canonical "what assets are in
> the build" entry point; the M6 closeout
> audit script (`tools/audit/check_licenses.sh`)
> reads this file.

## Summary

- **Total assets**: 30
  (12 PNG tiles + 10 PNG UI + 7 PNG
  inhabitants + 2 PNG crises + 6 WAV
  audio + 2 .tres resources).
- **External assets**: 0 (all procedural).
- **CC0 (procedural)**: 31 PNG + WAV.
- **GPL-3.0-or-later (code resources)**:
  2 .tres files.
- **CC BY-SA 4.0 (locales)**: 2 .po files.

## Tiles (12)

| File | License | Source | Audit |
|------|---------|--------|-------|
| `atlas_4x4.png` | CC0 | `generate_assets.gd` | ✅ procedural |
| `floor_stone.png` | CC0 | `generate_assets.gd` | ✅ procedural |
| `floor_marsh.png` | CC0 | `generate_assets.gd` | ✅ procedural |
| `floor_highland.png` | CC0 | `generate_assets.gd` | ✅ procedural |
| `wall_stone.png` | CC0 | `generate_assets.gd` | ✅ procedural |
| `hearth.png` | CC0 | `generate_assets.gd` | ✅ procedural |
| `fog.png` | CC0 | `generate_assets.gd` | ✅ procedural |
| `shrine.png` | CC0 | `generate_assets.gd` | ✅ procedural |
| `forge.png` | CC0 | `generate_assets.gd` | ✅ procedural |
| `well.png` | CC0 | `generate_assets.gd` | ✅ procedural |
| `trap.png` | CC0 | `generate_assets.gd` | ✅ procedural |
| `world_tileset.tres` | GPL-3.0-or-later | checked-in | ✅ code resource |

## UI (10)

| File | License | Source | Audit |
|------|---------|--------|-------|
| `step.png` | CC0 | `generate_assets.gd` | ✅ procedural |
| `auto_tick.png` | CC0 | `generate_assets.gd` | ✅ procedural |
| `save.png` | CC0 | `generate_assets.gd` | ✅ procedural |
| `load.png` | CC0 | `generate_assets.gd` | ✅ procedural |
| `settings.png` | CC0 | `generate_assets.gd` | ✅ procedural |
| `pause.png` | CC0 | `generate_assets.gd` | ✅ procedural |
| `play.png` | CC0 | `generate_assets.gd` | ✅ procedural |
| `power_seal_breach.png` | CC0 | `generate_assets.gd` | ✅ procedural |
| `power_pause_crisis.png` | CC0 | `generate_assets.gd` | ✅ procedural |
| `power_reveal_tile.png` | CC0 | `generate_assets.gd` | ✅ procedural |
| `gothic_fantasy_theme.tres` | GPL-3.0-or-later | checked-in | ✅ code resource |

## Inhabitants (7)

| File | License | Source | Audit |
|------|---------|--------|-------|
| `lanternbearer_scribe.png` | CC0 | `generate_assets.gd` | ✅ procedural |
| `settler.png` | CC0 | `generate_assets.gd` | ✅ procedural |
| `bellows.png` | CC0 | `generate_assets.gd` | ✅ procedural |
| `ember.png` | CC0 | `generate_assets.gd` | ✅ procedural |
| `ledger.png` | CC0 | `generate_assets.gd` | ✅ procedural |
| `silvershroud.png` | CC0 | `generate_assets.gd` | ✅ procedural |
| `tide.png` | CC0 | `generate_assets.gd` | ✅ procedural |

## Crises (2)

| File | License | Source | Audit |
|------|---------|--------|-------|
| `plague.png` | CC0 | `generate_assets.gd` | ✅ procedural |
| `faction.png` | CC0 | `generate_assets.gd` | ✅ procedural |

## Audio (6)

| File | License | Source | Audit |
|------|---------|--------|-------|
| `step.wav` | CC0 | `generate_audio.gd` | ✅ procedural |
| `power_seal.wav` | CC0 | `generate_audio.gd` | ✅ procedural |
| `power_pause.wav` | CC0 | `generate_audio.gd` | ✅ procedural |
| `crisis_horn.wav` | CC0 | `generate_audio.gd` | ✅ procedural |
| `game_over.wav` | CC0 | `generate_audio.gd` | ✅ procedural |
| `ambient_loop.wav` | CC0 | `generate_audio.gd` | ✅ procedural |

## Localization (2)

| File | License | Source | Audit |
|------|---------|--------|-------|
| `locales/en.po` | CC BY-SA 4.0 | hand-written | ✅ original |
| `locales/de.po` | CC BY-SA 4.0 | hand-written | ✅ original |

## Total

- **33 assets** total.
- **0 external assets** (all procedural
  or hand-written original).
- **0 license violations**.
- **Audit status**: PASS.

## References

- ADR-0018 §Bucket 5 (M6 Licensing/IP Audit)
- `LICENSES/README.md` (overview)
- `docs/ip-license-checklist.md` (the
  M0-baseline audit checklist)
- `tools/audit/check_licenses.sh`
  (the M6 closeout audit script)

## M11-Art-Rework additions

| Asset | Type | License | Source | M11 status |
|-------|------|---------|--------|------------|
| `assets/ai/inhabitants/*.png` | AI-generated portraits (6) | CC0 | `mavis image_synthesize` | ✅ shipped |
| `assets/ai/tiles/*.png` | AI-generated tiles (6) | CC0 | `mavis image_synthesize` | ✅ shipped |
| `assets/ai/ui/*.png` | AI-generated UI icons (4) | CC0 | `mavis image_synthesize` | ✅ shipped |
| `assets/ai/crises/*.png` | AI-generated crisis icons (2) | CC0 | `mavis image_synthesize` | ✅ shipped |
| `shaders/post_process.gdshader` | Custom Godot shader | CC0 (per ADR-0023) | hand-written | ✅ shipped |
| `tools/benchmarks/run_perf_v2.gd` | Performance benchmark v2 | GPL-3.0+ | hand-written | ✅ shipped |
| `tools/assets/ai_asset_manifest.json` | AI asset manifest | CC0 | hand-written | ✅ shipped |

**Style brief**: Gothic Dark Fantasy + Storybook Watercolor
(reference: Darkest Dungeon + Hades + Slay the Spire).

**Total AI-generated assets**: 18 (6 portraits + 6 tiles + 4 ui + 2 crises).
**All CC0** per M6 licensing (no copyright on AI-generated art).
