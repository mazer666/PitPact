# AGENTS.md

Repository guidance for human contributors and AI-assisted development agents.

## Project orientation

Pact & Pit is an original, open-source, offline-first Godot 4 single-player 2.5D management and simulation game. The authoritative product baseline is `docs/requirements.md`.

## Safe commands

- Inspect files with `rg`, `find`, `sed`, and `git status`.
- Do not use `ls -R` or `grep -R` in this repository.
- Prefer local validation commands documented in `tools/README.md` when they become available.
- Do not run destructive commands such as `rm -rf`, `git reset --hard`, or broad formatters unless explicitly requested.

## Working rules

- Keep changes small, reviewable, and aligned with the milestone plan.
- Do not silently perform broad refactors.
- Update documentation when changing architecture, data formats, workflows, or contributor expectations.
- Add or update tests when changing behaviour where practical.
- Preserve offline-first behaviour: no mandatory account, telemetry, launcher, analytics SDK, or external gameplay service.

## Code and content style

- Engine: Godot 4.
- Primary language: GDScript with static typing where it improves clarity.
- Separate deterministic game-domain logic from scene/UI code wherever practical.
- Keep gameplay content data-driven so rooms, cultures, contracts, events, research, resources, biomes, and localization can evolve without unrelated code edits.
- Externalize every user-visible string into localization data from the first implementation commit.
- Comments should explain intent, invariants, constraints, and trade-offs, not obvious syntax.

## Documentation expectations

- Architecture decisions that affect module boundaries or contributor workflow require an ADR in `docs/adrs/`.
- Public planning lives in `docs/roadmap.md`, `docs/milestones.md`, and release notes/changelog files.
- Style, IP, and asset provenance requirements live in `docs/style-bible.md`, `docs/ip-license-checklist.md`, `assets/README.md`, and `licenses/README.md`.

## Pull request expectations

- Summarize player-facing, developer-facing, and documentation changes.
- List exact local checks run and their results.
- Mention any deferred tests or environment limitations.
- Call out licensing, localization, save-format, or architecture implications.
