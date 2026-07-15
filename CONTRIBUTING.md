# Contributing to PitPact

Thank you for your interest in PitPact — Pact & Pit: An Underworld of
Terms and Terrors. PitPact is an open-source project: original code is
GPL-3.0-or-later, original art, audio, writing, and data is CC BY-SA
4.0. By contributing, you agree that your contributions will be
licensed under the same terms.

This file covers the *how* of contributing. The *what* and *why* live
in `docs/ROADMAP.md` and the Requirements Specification. Read both
before opening a substantial change.

---

## Code of Conduct

Everyone participating in PitPact is expected to follow
[`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md). Be excellent to each other.

---

## Where to start

- Browse the [issue board](../../issues) and the
  [milestones](../../milestones). Look for issues labelled
  `good first issue` and `help wanted` first.
- Read `AGENTS.md` for the contributor rules that apply to *every*
  change — humans and AI assistants alike.
- Read the style guide in `docs/style-bible.md` for tone, terminology,
  and presentation rules that bind writing, art, and code.
- Skim the most recent release notes in `CHANGELOG.md` so you know
  what just shipped.

If you are about to make a change that touches:

- module boundaries (`src/*` ↔ `scenes/*` ↔ `data/*`)
- the public project name or branding
- the save format, locale key schema, or content data schema
- any third-party license posture

…open an issue (or draft a proposal in `docs/architecture/`) **before**
writing code. These changes need an Architecture Decision Record (ADR)
in `docs/adr/`.

---

## Reporting bugs

Use the **Bug report** issue template. Include:

- Steps to reproduce (load this seed, build this room, wait N days…).
- Expected vs. actual behaviour.
- Platform and Godot version.
- A copy of the relevant event-log excerpt, save file (if shareable),
  and a stack trace if one exists.

---

## Suggesting features and balance feedback

Use the **Feature idea** or **Balance feedback** templates. For
balance changes, attach a save and a seed when possible — that lets
maintainers reproduce the situation.

---

## Translation contributions

Use the **Translation** issue template. PitPact is built with all
visible strings externalized from day one (see §15 of the
Requirements Specification). Translators edit files in `locales/`
without touching code; an automated check verifies that all keys and
placeholders are present.

---

## Performance reports

Use the **Performance** template. Include platform, Godot version,
realm size, simulation time, and the output of the local benchmark
(`./tools/run_benchmark.sh`). Reproducible reports are far more
valuable than anecdotal ones.

---

## Security and privacy concerns

Use the **Security / privacy** template. **Do not** file public
issues for suspected vulnerabilities that put users at risk. Follow
the private disclosure instructions in the template.

PitPact is offline-first and collects no data, so the surface is
limited — but save-file handling, save import from untrusted sources,
and any future optional error reporting still deserve scrutiny.

---

## Pull requests

### Workflow

1. **One logical change per PR.** Bug fix + refactor + feature flag in
   the same PR will be sent back.
2. **Open or reference an issue.** Drive-by PRs without a tracked
   motivation are hard to integrate.
3. **Branch from `main`.** Long-lived feature branches accumulate
   conflicts and surprise reviewers. For larger work, use a draft PR
   as the conversation hub.
4. **Run the local quality suite before pushing:**
   ```sh
   ./tools/run_quality.sh
   ```
   The suite must be green. If you cannot run it locally, explain why
   in the PR description.

### Engine version

PitPact targets **Godot 4.7+**. The minimum version is
pinned in `project.godot`'s `config/features` array
(`"4.7"`). The local quality suite assumes a 4.7+ headless
binary on `PATH` (overridable via
`PITPACT_GODOT=/path/to/godot`). Contributors on an older
Godot 4.x build may see import or typing warnings; the
suite is the source of truth.
5. **Update the relevant docs in the same PR.** New module? Add a
   README in that directory per §17. New content type? Update the
   style bible. New dependency? Update `licenses/THIRD-PARTY.md`.
6. **Fill in the PR template** (`.github/PULL_REQUEST_TEMPLATE.md`)
   completely. Reviewers will read the *What & Why* first, then the
   *Risk & Rollback*, then the diff.

### Commit messages

We use a lightweight Conventional Commits style. Format:

```
<type>(<scope>): <imperative summary>

<body explaining the why, not the what>

<footer with references, e.g. Closes #42, BREAKING CHANGE: ...>
```

Types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `perf`,
`build`, `ci`, `revert`, `style`, `data`. Scopes are short module
names from the planned repo structure: `world`, `sim`, `realm`,
`content`, `save`, `ui`, `gen`, `loc`, `audit`.

The body should answer: why was this needed, what alternatives were
considered, what is intentionally *not* done here.

### Review

- At least one approving review is required before merge.
- For changes touching `data/`, `scenes/`, or any public API, request
  review from a maintainer in that area.
- For changes touching security, privacy, save format, or licensing,
  request review from a project lead.

### After merge

- The author is responsible for the PR landing in the next milestone
  or for the milestone to be re-scoped.
- Squash-merge is the default; the PR title becomes the commit
  summary, and the PR body becomes the commit body.

---

## File ownership and module boundaries

See `AGENTS.md` for the rule. In short: a module's README defines
what is public; everything else is local to the module and may change
without coordination. Cross-module edits require an ADR.

---

## AI-assisted contributions

AI-generated code, art, and writing are welcome, but the *human
contributor* is responsible for the change. That means:

- The contributor must be able to explain and defend every line.
- All AI-assisted material must be disclosed in the relevant
  manifest (`licenses/THIRD-PARTY.md`, `assets/MANIFEST.md`, or the
  data file header) — tool/source used, prompt intent, human
  modifications.
- AI-assisted material must still pass the originality and style
  review defined in §20.2 of the Requirements Specification.
- No copyrighted material may be used as a seed, reference, or
  training input for AI-assisted contributions (see §20 and §1 of
  the Requirements Specification).

---

## Recognition

Contributors are credited in `CREDITS.md` (maintained for each
release) and in the in-game "Compacts and Codicils" screen. Please
open a PR to `CREDITS.md` if your contribution is not yet listed.

---

## Private contact

For private matters (Code of Conduct reports, security disclosures,
licence or trademark questions), open a private issue or contact the
maintainers through the channels listed on the project page.

Thanks for helping build the Pit. May your contracts be readable and
your pits well-paved.
