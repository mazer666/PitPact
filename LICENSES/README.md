# PitPact — Asset Licenses

> Per ADR-0018 §Bucket 5 and §20.3 of
> `docs/requirements.md`. This directory
> records the license for every asset
> shipped in the M6 release. All assets
> are **procedurally generated** (per
> ADR-0017) and **public-domain / CC0**
> unless otherwise noted.

## Code

| Component | License | File |
|-----------|---------|------|
| All `.gd` files under `src/` | GPL-3.0-or-later | header on each file |
| All `.gd` files under `tests/` | GPL-3.0-or-later | header on each file |
| All `.gd` files under `tools/` | GPL-3.0-or-later | header on each file |

## Visual assets

| Asset | License | Source |
|-------|---------|--------|
| `assets/tiles/*.png` | CC0 (procedural) | `tools/assets/generate_assets.gd` |
| `assets/ui/*.png` | CC0 (procedural) | `tools/assets/generate_assets.gd` |
| `assets/inhabitants/*.png` | CC0 (procedural) | `tools/assets/generate_assets.gd` |
| `assets/crises/*.png` | CC0 (procedural) | `tools/assets/generate_assets.gd` |
| `assets/ui/gothic_fantasy_theme.tres` | GPL-3.0-or-later | `tools/` |
| `assets/tiles/world_tileset.tres` | GPL-3.0-or-later | `tools/` |

## Audio assets

| Asset | License | Source |
|-------|---------|--------|
| `assets/audio/step.wav` | CC0 (procedural) | `tools/assets/generate_audio.gd` |
| `assets/audio/power_seal.wav` | CC0 (procedural) | `tools/assets/generate_audio.gd` |
| `assets/audio/power_pause.wav` | CC0 (procedural) | `tools/assets/generate_audio.gd` |
| `assets/audio/crisis_horn.wav` | CC0 (procedural) | `tools/assets/generate_audio.gd` |
| `assets/audio/game_over.wav` | CC0 (procedural) | `tools/assets/generate_audio.gd` |
| `assets/audio/ambient_loop.wav` | CC0 (procedural) | `tools/assets/generate_audio.gd` |

## Localization

| Asset | License | Notes |
|-------|---------|-------|
| `locales/en.po` | CC BY-SA 4.0 | English source |
| `locales/de.po` | CC BY-SA 4.0 | German translation |

## M6 audit

The M6 closeout ships a self-audit at
`LICENSES/asset-manifest.md`. The audit
asserts that every asset is:
1. Procedurally generated (no external
   IP, no hand-drawn art).
2. SEED-pinned (re-runs produce
   byte-identical output).
3. GPL-3.0-or-later (code) or CC0
   (assets).

A regression that introduces an
external asset is caught by
`tools/audit/check_licenses.sh`
(M6 Bucket 5).
