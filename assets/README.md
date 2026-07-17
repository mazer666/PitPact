# PitPact — Assets

This directory holds the M5-Foundation visual
assets. All assets are **procedurally generated**
by `tools/assets/generate_assets.gd` (a
Godot 4.7 headless script that uses
`Image.fill_rect` / `set_pixel` to draw the
assets and saves them as PNGs).

The procedural approach is the canonical
"open-source asset pipeline" for PitPact
(per `docs/requirements.md` §20 — "no
protected expression, no third-party IP,
no external asset dependencies"). Every
asset is data-driven: a small GDScript draws
the asset from a list of color stops and
shapes. A future content pass can swap the
procedural generator for a hand-drawn
pipeline (per ADR-0009 content-grade: every
asset has a docstring + license + provenance
+ reproducible seed).

## Layout

```
assets/
  tiles/        # 16x16 isometric tiles (floor, wall, hearth, fog, marsh, highland)
  ui/           # 32x32 UI icons (step, auto-tick, save, load, settings, pause)
  inhabitants/  # 16x24 inhabitant portraits (lanternbearer, settler, scribe)
  crises/       # 32x32 crisis icons (plague, faction, breach)
```

## Regenerating

```
godot --headless --path . --script res://tools/assets/generate_assets.gd
```

The generator is idempotent: re-running it
overwrites the PNGs. The generator's
`SEED` is pinned (per ADR-0005 determinism)
so the output is byte-identical across
runs.
