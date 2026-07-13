# Changelog

> Format loosely follows [Keep a Changelog](https://keepachangelog.com/),
> adapted for a pre-release project. Each release entry lists
> player-facing, developer-facing, and documentation changes.
>
> Until the first public release (M6), this file is the live log of
> merged changes. After M6, a "Release notes" file is generated from
> the entries below and the GitHub Release.

## [Unreleased] — M0 Foundation in progress

### Added

- `LICENSE` (split-license: GPL-3.0-or-later for code, CC BY-SA 4.0
  for art/audio/writing/data) and the corresponding full license
  texts under `licenses/`.
- `CODE_OF_CONDUCT.md` (Contributor Covenant 2.1, adapted for the
  satire-vs-harm boundary in §6.2).
- `CONTRIBUTING.md` (workflow, PR rules, AI-assist disclosure,
  review expectations).
- `SECURITY.md` (private disclosure channel, threat model,
  hardening commitments).
- `.gitignore` (Godot 4, Python, IDEs, OS, secrets, build artifacts).
- Godot 4.3 project skeleton: `project.godot`, `icon.svg`, and
  `.gdignore` markers in directories Godot should not scan.
- Single local quality command `tools/run_quality.sh` and the
  `tools/run_benchmark.sh` stub.
- GitHub Actions confirmation suite at
  `.github/workflows/ci.yml`.
- Issue templates for bugs, feature ideas, balance feedback,
  translation, performance, and security/privacy concerns.
- Pull request template at `.github/PULL_REQUEST_TEMPLATE.md`.
- `docs/style-bible.md` (M0 framing; full content lands with M1
  art / M3 audio passes).
- `docs/ip-license-checklist.md` (per §20.3 pre-release review).
- `docs/adrs/0001-record-architecture-decisions.md` (MADR-based
  ADR template).
- `CREDITS.md` (contributor recognition skeleton).
- `archive/README.md` policy.

### Changed

- Removed now-redundant root `.gitkeep` and the
  `licenses/.gitkeep` placeholder now that those directories
  contain real content. Other directory `.gitkeep` files are kept
  in directories that will grow content in M1+ (data, assets,
  locales, scenes, src).

### Fixed

- _None._

### Security

- No security fixes in M0. The first private-vulnerability report
  is expected post-M0; see `SECURITY.md`.

### Notes

- The full Requirements Specification lives in `docs/requirements.md`.
- The milestone plan and the M0 Definition-of-Done live in
  `docs/milestones.md`.
- License posture is split: code is GPL-3.0-or-later; original
  art, audio, writing, and data are CC BY-SA 4.0. Third-party
  material is recorded in `licenses/THIRD-PARTY.md`.

## Earlier

_Repository bootstrapped. The "Initialize repository" commit
established the empty repository; the "Add initial project
documentation structure" PR (codex #1) added the directory
scaffolding, `AGENTS.md`, `README.md`, and the `docs/` skeleton
including the mirrored requirements spec._
