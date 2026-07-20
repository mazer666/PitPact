# PitPact Style Bible

> Status: **M16 final** (post M11 Art Rework + M12 UI Rework + M13 Visual Polish).
> This is the canonical visual, audio, and writing style guide for
> PitPact. The M0 skeleton was filled in across M11/M12/M13/M15/M16.
> Edits to terminology, tone, and palette below require an ADR-style
> review even before content lands.

## Why this document exists

§14 of `docs/requirements.md` requires "a visual, audio, and writing
style bible" that defines:

- terminology (so the team uses the same words for the same things)
- tone (so a UI popup, an event log line, and a creature quote feel
  like the same game)
- palette (so 50 placeholder assets don't paint the project in 50
  directions before the art director says a word)
- silhouette principles (so the six cultures are recognisable at a
  glance on a tiny minimap)
- sound motifs (so every hearth, ritual, and crisis has an
  audio identity, not 30 placeholder bleeps)
- **forbidden reference points** (so we don't accidentally clone
  protected expression, terminology, character designs, or lore from
  any existing game)

This file is the live, authoritative copy. Anything that contradicts
it is a bug.

## Visual style: Gothic Dark Fantasy + Storybook Watercolor

The PitPact visual style is a **hybrid** of two reference frames,
established in **M11** (per ADR-0023):

- **Gothic Dark Fantasy** — the moody, atmospheric base
  (dark palette, dramatic lighting, ornate details)
- **Storybook Watercolor** — the soft, painterly overlay
  (gentle brushwork, soft edges, hand-drawn feel)

**References** (M11 closeout):
- Darkest Dungeon (Gothic base)
- Hades (Watercolor overlay)
- Slay the Spire (UI style)

### Palette

The PitPact palette is anchored on dark indigo backgrounds with
gold + rose + cream accents. All M11-M13 assets use this palette.

| Role | Hex | RGB | Notes |
|------|-----|-----|-------|
| Background (deep) | `#1a1a2e` | (26, 26, 46) | Canvas background |
| Background (charcoal) | `#2d2d3a` | (45, 45, 58) | Secondary background |
| Mid (dusty rose) | `#a86b6b` | (168, 107, 107) | Mid-tone accent |
| Mid (tarnished gold) | `#b8924a` | (184, 146, 74) | Mid-tone gold |
| Accent (pale gold) | `#d4af37` | (212, 175, 55) | Highlights, buttons |
| Accent (bone white) | `#e8e3d8` | (232, 227, 216) | Text, borders |
| Highlight (soft cream) | `#f4ebd0` | (244, 235, 208) | Special highlights |
| Crisis (warning red) | `#a02020` | (160, 32, 32) | Crisis banner |
| Victory (gold) | `#d4af37` | (212, 175, 55) | Victory banner |

### Silhouette principles (M11 / M12 / M15)

Each of the six cultures has a recognisable silhouette on the
minimap (a 24x24 tile). The silhouettes are:
- **lanternbearer** — hooded, carrying a glowing lantern
- **bellows** — muscular, with forge tools
- **ember** — fire-touched robes, glowing embers
- **ledger** — scholarly robes, scroll + quill
- **silvershroud** — silver cloak, daggers
- **tide** — sea-salt robes, conch shell

The M11 closeout ships AI-generated portraits (CC0) for all 6
cultures + 13 role variants.

### Animation principles (M13 / M16)

The M13 closeout ships the canonical animation system. Animations
are **60 FPS-friendly** (per ADR-0023 performance budget).

| Animation | Cycle | Use |
|-----------|-------|-----|
| `idle_breathing` | 2.0s (3 frames: 1.0/1.05/0.95 scale) | Inhabitant portraits |
| `hover_tween` | 0.15s (9 frames @ 60 FPS) | Button hover states |
| `title_fade_in` | 1.5s (90 frames) | Title screen |
| `particle_lifetime` | 1-2s per spawn | Crises, powers |
| `day_night_cycle` | 0.5s/tick (30 frames) | Background brightness |
| `step_button_pulse` | 0.3s (18 frames) | Step-button feedback |
| `crisis_flash` | 0.3s (18 frames) | Crisis feedback |
| `power_glow` | 0.3s (18 frames) | Power feedback |

**Reduce-Motion** (M16): Players can disable `idle_breathing`,
`particles`, `day_night_cycle`, `hover_tween`, `title_fade_in`
via `GameSettings.accessibility.reduce_motion`.

## Sound motifs (M5-Closeout Bucket 6)

The M5 closeout ships 6 procedurally-generated SFX + 1 ambient
track (16-bit PCM @ 22050 Hz). All SFX are CC0.

| Sound | Use | Duration |
|-------|-----|----------|
| `step.wav` | Step button (game tick) | 0.2s |
| `power_seal.wav` | Power: Seal Breach | 0.5s |
| `power_pause.wav` | Power: Pause Crisis | 0.5s |
| `power_reveal_tile.wav` | Power: Reveal Tile | 0.5s |
| `crisis_horn.wav` | Crisis event | 0.8s |
| `game_over.wav` | Game over | 1.5s |
| `ambient_loop.wav` | Background ambient | 30s loop |

**Per-Culture-Theme** (planned for M17+): Each culture has a
unique ambient track (planned but not yet implemented).

## Tone

PitPact is **earnest but not grim**. The game is about scarcity,
mortality, and difficult choices, but the writing style is:

- **Warm** — inhabitants are people, not stats
- **Specific** — "the third hearth has been cold for two days" beats
  "your hearth is broken"
- **Mystical but grounded** — magic exists but follows rules
- **Tactile** — words evoke texture, weight, temperature

The Crisis-Banner writing is more formal, the event-log
writing more conversational, and the achievement descriptions
more terse.

## Forbidden reference points

- **Specific franchise terminology** — no "Hearthstone", "Darkest",
  "Dota", "Baldur's", etc. in our text
- **Specific character designs** — no re-skinned versions of
  copyrighted characters
- **Lore** — no direct quotes or paraphrases of any existing game's
  worldbuilding
- **Sound effects** — all SFX must be procedurally generated
  (per ADR-0005) or CC0-licensed (per M6 licensing audit)

## References

- ADR-0023 — M11 Art Rework (visual style brief)
- ADR-0024 — M12 UI Grafical Rework
- ADR-0025 — M13 Visual Polish & Animation
- ADR-0026 — M14 Engine Performance & Content
- ADR-0027 — M15 Final Polish, UX & Real Co-op
- ADR-0028 — M16 Final Documentation + Ease of Life
- M11 assets: `assets/ai/` (CC0)
- M12 theme: `assets/ui/gothic_fantasy_theme_v2.tres`
- M13 animation carriers: `src/ui/idle_animator.gd`,
  `src/effects/particle_spawner.gd`,
  `src/ui/audio_reactive_visual.gd`
