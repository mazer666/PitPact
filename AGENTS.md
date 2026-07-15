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

## Best-in-Class principle

Every contribution that lands on `main` must be **best in
class** for an offline-first, Godot 4, GDScript
single-player management/simulation game. Concretely:

- **Architecture-grade** — the change honours the relevant
  ADRs, the module-boundary check
  (`tools/check_module_dependencies.sh`), and the
  ADR-driven determinism contract. A change that papers
  over a missing ADR is *not* best in class; the ADR is
  written first.
- **Test-grade** — the change ships tests that fail before
  the fix and pass after. A test that *looks* green but
  silently no-ops (e.g. a missing method call that the
  test harness swallows) is *not* a passing test; the
  reviewer must run the test with a deliberate seed
  failure first.
- **Documentation-grade** — README, roadmap, CHANGELOG,
  ADRs, and module-level READMEs are updated in the same
  commit as the code that makes them stale. A
  documentation drift that survives a milestone closeout
  is *not* best in class.
- **Local-quality-grade** — `./tools/run_quality.sh` is
  green on the integrated whole. A test run that passes
  on a single file but fails the full suite is *not* a
  green light.
- **Content-grade** — every new public symbol has a
  `class_name`, a docstring, and a `## ` block on every
  member; every user-visible string is externalized to
  `locales/source_strings.csv` and translated in both
  `en.po` and `de.po`; every data schema is documented
  in `docs/data-schema.md` and the schema is
  save-format-versioned.
- **Audit-grade** — the milestone closeout is reviewed
  independently by the team lead *before* the closeout
  commit. The audit must enumerate every test, every
  ADR, every doc claim and verify them; vague
  "all green" reports are *not* an audit.

The bar is the bar. If a commit cannot meet it, the
commit is split, the missing piece is shipped first, and
the closeout is retried. The user (a senior product owner)
is the final reviewer; the team lead does not declare
best in class on the team's behalf.

## Code and content style

- Engine: Godot 4. **Minimum supported version: 4.7.**
  The `config/features` array in `project.godot` pins
  the lower bound; contributors who test on a
  pre-4.7 build are responsible for catching the
  regressions themselves (the CI runs on 4.7).
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
