# IP and License Checklist

> Status: **M0 baseline**. To be applied at every public release per
> §20.3 of `docs/requirements.md`. The checklist is opinionated and
> exhaustive by design; if an item feels redundant, that is a sign
> the previous review missed it.

## How to use this file

1. Open a tracking issue named "Pre-release IP/license review for
   `<version>`" and copy this checklist into the issue body.
2. Walk every item, fill in the answer and the evidence link.
3. The release is acceptable only if every required item is "yes"
   with evidence. "Probably" is not a release sign-off.
4. Archive the completed checklist under
   `archive/releases/<version>/ip-license-checklist.md` after the
   release is published.

## Identity

- [ ] Project public name has a separate trademark / name-availability
      check recorded. (Working title: *Pact & Pit*. §25.)
- [ ] Game title used in `project.godot` matches the trademarked name.
- [ ] No internal codename leaks into shipped text.

## Writing

- [ ] All narrative text reviewed for protected character names,
      phrases, titles, or distinctive lore from existing works.
- [ ] Recurring character names checked against trademark and
      character databases used by the team.
- [ ] No song lyrics, book excerpts, screenplay lines, or
      recognisable limericks / jokes / memes embedded in shipped
      text. Quoting in PR discussions is fine.
- [ ] No real-person names used for in-game characters or
      institutions, alive or dead within the last 75 years, without
      explicit written permission on file.
- [ ] Translation source strings avoid idioms that cannot survive
      localisation (§15).

## Visuals

- [ ] Every asset path under `assets/` is listed in
      `assets/MANIFEST.md` with author, source, license, and
      modification status.
- [ ] Original silhouette, palette, and design rules match
      `docs/style-bible.md` for every shipped creature, room, item,
      and UI element.
- [ ] No reference to protected creature designs (e.g. recognisable
      fantasy IP creature silhouettes) even when redrawn.
- [ ] No reference imagery from copyrighted sources used in the
      `docs/art-direction/` moodboards without an exception record.

## UI

- [ ] UI layouts, iconography, and HUD patterns are not
      pixel-reproductions of any existing game's UI.
- [ ] The interaction metaphor (priority panels, contract cards,
      inhabitant inspectors) is documented in
      `docs/architecture/ui.md` and departs from copy-paste
      conventions where they would imply copying a protected
      product.

## Gameplay presentation

- [ ] The core game loop is original; any resemblance to existing
      management / colony / dungeon games is at the genre level
      only.
- [ ] The six cultures' body forms, values, professions, social
      rules, and conflict patterns are not thinly-veiled copies of
      protected fantasy IP cultures.
- [ ] Contract, decree, and ritual taxonomies are not recognisable
      re-labellings of an existing game's spell or tech tree.

## Music and audio

- [ ] Every audio file under `assets/audio/` is listed in
      `assets/MANIFEST.md` with author, source, license, and
      modification status.
- [ ] No melodic, harmonic, or rhythmic phrase recognisable as a
      protected song or score, even when re-recorded.
- [ ] No voice samples of named real people without written
      permission on file.

## Dependencies

- [ ] Every runtime and build-time dependency is listed in
      `licenses/THIRD-PARTY.md` with version, source, license, and
      attribution.
- [ ] Dependency license is compatible with GPL-3.0-or-later for
      code and CC BY-SA 4.0 for assets.
- [ ] Pinned versions are recorded; no "floating" or `*` versions
      in production manifests.
- [ ] Transitive dependencies of any native extension are listed
      and licensed. Native extensions are gated by §16.1 — an ADR
      is required before adding one.

## Third-party assets

- [ ] No asset from a source whose license is incompatible with
      CC BY-SA 4.0 (assets) or GPL-3.0-or-later (code) is shipped.
- [ ] Required attribution text is present and unmodified.
- [ ] License texts are stored in `licenses/` with the project's
      SPDX identifier as filename.
- [ ] For any Creative Commons share-alike asset, the project's
      overall license is also CC BY-SA 4.0 (for that asset only);
      this is satisfied by the project split-license model.

## AI-generated assets

For every AI-assisted asset shipped in the release:

- [ ] Creation tool or service recorded in
      `assets/MANIFEST.md`.
- [ ] Human modifications recorded (what was changed, when, by
      whom).
- [ ] The prompt intent and the source / training-data provenance
      recorded where the tool's license requires it.
- [ ] The asset has been individually reviewed for originality
      against this checklist's writing / visual / audio rules.
- [ ] No copyrighted material was used as a seed, reference image,
      or training input for the AI tool.

## Trademarks and names

- [ ] No third-party trademark, logo, or service mark is used
      in-game or in marketing without an explicit written
      permission record.
- [ ] The references in this checklist are not themselves
      protected expression; the project cites them only as
      forbidden reference points.

## Sign-off

- [ ] Maintainer 1 (name + date + commit SHA)
- [ ] Maintainer 2 (name + date + commit SHA)
- [ ] Project lead (name + date + commit SHA) — required for the
      first public release of any milestone.

## See also

- `docs/requirements.md` §20 (open source, assets, and IP compliance).
- `docs/style-bible.md` (forbidden reference points and tone rules).
- `assets/MANIFEST.md` (asset provenance).
- `licenses/THIRD-PARTY.md` (dependency and third-party asset
  records).
- `licenses/` (license texts).
