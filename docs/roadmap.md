# PitPact Roadmap

> Status: **live**. This file is the M0-Closeout version of the
> roadmap; it reflects the repository as of the M0 closeout commit
> on `main`. The next update lands with the M1 closeout.
>
> See also: [`docs/milestones.md`](milestones.md) for the milestone
> Definition-of-Done, [`docs/requirements.md`](requirements.md) for
> the product requirements this roadmap is derived from, and
> [`CHANGELOG.md`](../CHANGELOG.md) for the live log of merged
> changes.

## Current state

The M0 Foundation milestone is **complete** on `main`. The four
M0-Closeout commits landed:

1. Repository governance (LICENSE, CODE_OF_CONDUCT, CONTRIBUTING,
   .gitignore).
2. Godot 4 project skeleton (project.godot, icon.svg, .gdignore
   markers).
3. CI workflow, issue/PR templates, and the local quality command
   (tools/run_quality.sh).
4. Style bible, IP/license checklist, security policy, changelog,
   and ADR-0001.

The M1 architectural foundation (ADRs 0002/3/4, src/ module stubs,
GUT 9.2.1 setup, expanded run_quality.sh) and the first vertical
slice (Track A spatial, Track B camera+UI, Track C content+save+locale)
are **also on main** as of this writing, but they are part of the
M1 work, not the M0-Closeout. They will be reported in the M1
closeout commit and the corresponding changelog entry.

## M0 → M6 at a glance

The milestone plan in [`docs/milestones.md`](milestones.md) defines
six milestones. Each milestone has a Definition-of-Done that must
hold before the next one opens. The milestones, in order:

| # | Milestone | Status (this roadmap) |
|---|-----------|------------------------|
| M0 | Foundation | **Done** — see [`CHANGELOG.md`](../CHANGELOG.md). |
| M1 | Playable realm core | In progress — foundation and first vertical slice merged; smoke-test integration gate pending. |
| M2 | Simulation core | Next. Inhabitant needs, contracts, tasks, relationships, memory, event log, resources. |
| M3 | World and campaign | Constrained generator, two biomes, exploration, fixed narrative anchors, branching events. |
| M4 | Knowledge and crisis | Research/ritual progression, Pactmaker powers, autonomous conflict, two crises, difficulty/settings. |
| M5 | Vertical campaign completion | Six cultures, ten rooms, fifteen events, complete success/failure/restart loop, English/German, audio pass. |
| M6 | Public release readiness | Performance target, accessibility review, licensing/IP audit, reproducible builds, release notes, known-issues list. |

Post-release work (balancing, additional content, mod/content
interfaces, iPadOS preparation, eventual co-op) is out of scope for
M0-M6 and tracked separately.

## What "in progress" means for M1

The M1 Definition-of-Done is in [`docs/milestones.md`](milestones.md).
At a glance, M1 needs:

- Camera/UI shell, isometric tile map, zoning, one room lifecycle,
  local saving, diagnostics.

M1 is being built in three parallel vertical slices (spatial,
camera+UI, content+save+locale) on top of the architectural
foundation. The smoke-test integration gate verifies the integrated
whole. See the M1-Closeout entry in `CHANGELOG.md` for the detailed
status when M1 lands.

## What the M0-Closeout delivers

The M0-Closeout is the smallest, sharpest slice of work that
makes the repository internally consistent and contributor-ready.
Specifically, the M0-Closeout commits:

- Put formal licenses (GPL-3.0-or-later for code, CC BY-SA 4.0 for
  assets) on every file that needs them.
- Documented the contributor and community expectations
  (`CODE_OF_CONDUCT.md`, `CONTRIBUTING.md`, `SECURITY.md`).
- Stood up the local quality command
  (`tools/run_quality.sh`) and the GitHub Actions confirmation
  suite, so that "is this build green?" has a single, documented
  answer.
- Wrote the style bible, IP/license checklist, and the first ADR
  (the ADR practice itself), so that future decisions have a
  template.
- Wrote this roadmap and updated the changelog so that a new
  contributor can answer "where is the project right now?" from
  the repo alone.

## What the M0-Closeout does not deliver

M0-Closeout is **not** a release. It is the launch pad for M1.
Specifically, the M0-Closeout does not include:

- Working gameplay. M1 and later milestones add gameplay.
- Performance benchmarks. M6 adds them.
- A polished style bible. The M0 style bible is a framing document;
  the full palette, silhouette rules, and sound motifs land with
  the M1 art pass and the M3 audio pass.
- Translations. English is the only complete source language at M0.
  German is the first additional language and is added at M5.

These are not gaps; they are the explicit scope of the milestone
plan.

## How this roadmap evolves

- M0 is done. M1 is in progress. The M1-Closeout commit will add a
  new section here that reflects the M1 state.
- Each milestone closeout adds a section below; the older sections
  stay as historical record.
- Architectural changes to the milestone plan itself (e.g. adding
  a milestone, splitting one) require an ADR in
  [`docs/adrs/`](adrs/README.md).

## See also

- [`docs/milestones.md`](milestones.md) — the milestone plan and
  Definitions-of-Done.
- [`docs/requirements.md`](requirements.md) — the product
  requirements this roadmap is derived from.
- [`docs/repository-structure.md`](repository-structure.md) — the
  directory map.
- [`CHANGELOG.md`](../CHANGELOG.md) — the live log of merged
  changes.
