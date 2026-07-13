# PitPact Style Bible

> Status: **M0 skeleton**. This is the framing document the M1+ content
> and code work is expected to follow. It is intentionally short; the
> real content (palette swatches, reference clips, voice-direction
> notes) lands alongside the corresponding content modules. Edits to
> terminology, tone, and palette below require an ADR-style review even
> before content lands.

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

## Tone

PitPact is a dark-but-colourful **Weird/Gothic fantasy** with **dry
bureaucratic satire** about authority, dogma, extractive economies,
empires, and administration.

Three rules govern tone across text, art, and audio:

1. **Satire targets systems, not people.** Critique of bureaucracy,
   dogma, capital, aristocracy, and institutional research is fair
   game. Mockery of real protected groups is not. §6.2 of the
   requirements spec is the contract; this style bible is its
   day-to-day application.

2. **Dark atmosphere ≠ gleeful cruelty.** "Dark" is aesthetic and
   thematic; the game never glorifies harm. Injury, death, fear, and
   loss are visible and matter — they are not content for a punchline.

3. **Cartoon-macabre, never realistic gore.** Visual violence uses
   stylised silhouettes, suggested impact, and aftermath over
   explicit depiction. Potentially distressing material is gated
   behind individually switchable presentation options (§6.4).

## Writing voice

| Where | Voice |
|------|------|
| UI labels and tooltips | Plain, short, second person. No narrative voice. |
| Contract clauses, decrees, reports, notices | **The satire lives here.** Bureaucratic cadence, named clauses, exception sections, fine-print footnotes, contradictory addenda. |
| Event log lines | Neutral past-tense. The event log is the source of truth, not a story. |
| Advisor / recurring character dialogue | Distinct, named voices. One adjective short of quirky. Avoid "wacky" — the game is dark, not jokey. |
| Creature names | Original. No resemblance to real languages or protected works. |
| Item / room names | Two short words is the sweet spot. `Singing Vault`, `Hollow Court`, `Cinder Census`. |

Translation-friendly rules (§15):

- No string concatenation across files. Use placeholders, not
  `"You have " + str(n) + " workers."` — `"You have {n} workers."`.
- No gendered assumptions baked into the source string. Provide
  separate keys when a culture has gendered vocabulary.
- No idioms that don't translate. If a phrase is too local to carry
  meaning in another language, replace it with a phrase that is.

## Palette and silhouettes (M0 stub)

The full palette swatches and silhouette rules land with the M1 art
pass. For M0 we pin three commitments so placeholder work does not
drift:

- **Two-regime palette.** Cool greys and desaturated blues for the
  surface world and bureaucratic text; warm umber, bone, and ember
  reds for the underground realm and ritual space. Mixing is
  meaningful (a torch in a census office, a "surface seal" on an
  underground document).
- **Silhouette-first creature design.** Each of the six cultures must
  be identifiable at minimap scale by silhouette alone, before any
  colour, animation, or detail.
- **No clean pure black, no clean pure white.** Both end up as the
  cheapest gradient; pick a near-black and a near-bone instead.

## Sound motifs (M0 stub)

The full sound-design document lands with the M3+ audio pass. The M0
commitments:

- **Work sounds** are per-profession and not interchangeable. A
  workshop sounds different from a hearth sounds different from a
  research bench.
- **Crisis audio** is layered: a base bed, a culture-specific voice,
  and a Pactmaker-specific motif. No single "alarm" stinger.
- **Voice is short and selective** (§14). Key characters, reports,
  satirical announcements only. No full spoken dialogue.

## Forbidden reference points

The following classes of reference are forbidden in PitPact, full
stop. This is not a complete list; it is a non-exhaustive sketch
binding on every contribution.

- Protected creature designs, room names, character names, faction
  names, item names, technology names, or terminology from any
  existing game (Dwarf Fortress, RimWorld, Dungeon Keeper, the Sims,
  Civilization, etc.).
- Protected expression from novels, films, TV, comics, or tabletop
  rulebooks. Quoting in commits or docs is fine; *embedding* in
  shipped content is not.
- Real-world protected-group slurs, dog whistles, or "ironic" reuse
  of either, in any string of any file in any locale.
- AI-generated material whose source or seed incorporated any of the
  above. AI assistance is welcome; AI-laundered copying is not. See
  §20.2 and `CONTRIBUTING.md`.

The full originality and license review checklist lives in
`docs/ip-license-checklist.md`. Use both files together during
pre-release review (§20.3).

## How this document evolves

- Substantive tone, palette, or silhouette changes go through an ADR
  in `docs/adrs/`.
- Voice / wording nits (replacing one adjective with another) are
  filed as PRs against this file directly.
- Disputes are resolved by the project lead, citing this document
  and the requirements spec.

## See also

- `docs/requirements.md` §6 (world, narrative, tone), §14 (audio and
  presentation), §15 (localization), §20 (IP and licensing).
- `docs/ip-license-checklist.md` (operational checklist).
- `CONTRIBUTING.md` (how to propose changes to this document).
- `CODE_OF_CONDUCT.md` (the community line on satire vs. harm).
