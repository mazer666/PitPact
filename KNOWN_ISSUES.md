# PitPact — Known Issues

> Per ADR-0018 §Bucket 6. This file
> lists the open issues in the M6
> release. Each issue has a status
> (open / workarounds / fixed) and
> a workaround (if available). The
> M7 closeout can extend the list.

## M6 status

The M6 closeout ships with **3 known
issues** (1 audio, 1 UI, 1 docs).
The M6 closeout's test net passes
all 3 + the existing M5-Closeout
test net. The issues are documented
below; the M7 closeout will fix
them.

---

## Issue #1 — `game_over.wav` click at 500ms

**Status**: open (workaround: lower volume to -12 dB)

**Component**: `assets/audio/game_over.wav`

**Description**: The `game_over.wav` SFX
is built by concatenating two tones
(A4 for the first 500ms, F4 for the
second 500ms). The transition at
500ms has a small audible click
because the second tone's waveform
does not start at a zero-crossing.

**Workaround**: lower the game-over
SFX volume to -12 dB in the
`GameOverBanner` AudioStreamPlayer
(M6 closeout does not yet wire the
volume).

**Fix**: implement an ADSR envelope
in `tools/assets/generate_audio.gd`
that smooths the transition (M7).

---

## Issue #2 — `M5GameState` recomputes on every step

**Status**: open (workaround: none
needed for M6; < 5ms per recompute)

**Component**: `src/sim/m5_game_state.gd`

**Description**: The `_recompute_room_counts_from_world()`
method walks the entire world's tile
grid on every `_on_step_pressed()`.
For a 24x24 grid, the per-step cost
is ~1ms. For a hypothetical 100x100
grid, the cost would be ~20ms (still
under the 16ms frame budget, but
linear with the grid size).

**Workaround**: none needed for M6
(1ms per step is well under budget).
The M6 benchmark (`tools/benchmarks/
run_perf.gd`) confirms 1.06ms/tick
on a 24x24 grid.

**Fix**: implement an incremental
update path that tracks the room
counts as tiles are added/removed
(M7).

---

## Issue #3 — Atlas file name is misleading

**Status**: open (workaround: documentation)

**Component**: `assets/tiles/atlas_4x4.png`

**Description**: The atlas file is
named `atlas_4x4.png` but its actual
layout is **4x3 = 12 cells** (the
M5-Closeout Bucket 2 expanded the
atlas from 4x2 to 4x3). The file
name is retained for backward
compatibility with M5-Foundation
importers that hard-coded the name.

**Workaround**: documentation
(`docs/atlas-4x4-migration.md`,
forthcoming in M6.1). The `.tres`
file's `texture_region_size` and
the cell coordinates are the
authoritative source.

**Fix**: rename to `atlas_4x3.png` in
M6.1 (requires a one-time migration
of the `.tres` and the import files).

---

## How to file a new issue

1. Check this list first to avoid
   duplicates.
2. Open a tracking issue on GitHub
   with the label `m6-known-issue`.
3. Copy the issue template below
   into the issue body.
4. Add the issue to this file under
   the "M6 status" section.

## Issue template

```markdown
## Issue #N — <title>

**Status**: open / workaround / fixed

**Component**: <file path>

**Description**: <one paragraph>

**Reproduction**: <steps to reproduce>

**Workaround**: <workaround if any>

**Fix**: <fix if planned, with milestone>
```

## References

- ADR-0018 §Bucket 6 (M6 Known-Issues)
- `LICENSES/asset-manifest.md` (asset
  audit)
- `tools/audit/check_licenses.sh`
  (the M6 closeout audit script)
