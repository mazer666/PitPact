# PitPact Roadmap

> Status: **live**, best-in-class. The roadmap reflects the
> repository as of the M4-Closeout commit on `main`. The
> next update lands with the M5 closeout. Every closeout
> is held to the best-in-class bar defined in
> [`AGENTS.md`](../AGENTS.md): architecture-grade,
> test-grade, documentation-grade, local-quality-grade,
> content-grade, audit-grade.
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
| M1 | Playable realm core | **Done** — foundation and first vertical slice merged; 32/32 GUT tests passing on Godot 4.7+ headless; the local quality command is green end-to-end. |
| M2 | Simulation core | **Done** — see the M2-Closeout entry in [`CHANGELOG.md`](../CHANGELOG.md); 69/69 GUT tests passing in ~0.42s on Godot 4.7+ headless. |
| M3 | World and campaign | **Done** — see the M3-Closeout entry in [`CHANGELOG.md`](../CHANGELOG.md); 106/106 GUT tests in ~0.63s / 727 Asserts on Godot 4.7+ headless (GUT 9.4.0); constrained 24x24 generator + Marshlands/Highlands + ExplorationMap (fog-of-war) + 4 fixed narrative anchors + 3-node branching-event tree (FirstInspection → accept_audit / counter_offer with `terminal_effect` schema). |
| M4 | Knowledge and crisis | **Done + hardened + audited** — see the M4-Closeout, M4-Hardening, and M0-M3-Audit entries in [`CHANGELOG.md`](../CHANGELOG.md); 172/172 GUT tests in ~0.85s / 966 Asserts on Godot 4.7+ headless (GUT 9.4.0). M4-Hardening: 22/22 mutations REAL (two silent-pass bug fixes: Settings `_init()`, Pactmaker debit-on-success). M0-M3-Audit: 16/16 mutations REAL (M0-M3 carriers are clean). M5-Foundation: PlayableShell factory + PlayableShellUI code-driven controller + 13 new end-to-end tests; 7/7 mutations REAL. |
| M4 | Knowledge and crisis | Research/ritual progression, Pactmaker powers, autonomous conflict, two crises, difficulty/settings. |
| M5 | Vertical campaign completion | Six cultures, ten rooms, fifteen events, complete success/failure/restart loop, English/German, audio pass. |
| M6 | Public release readiness | Performance target, accessibility review, licensing/IP audit, reproducible builds, release notes, known-issues list. |

Post-release work (balancing, additional content, mod/content
interfaces, iPadOS preparation, eventual co-op) is out of scope for
M0-M6 and tracked separately.

## What "done" means for M1

The M1 Definition-of-Done is in [`docs/milestones.md`](milestones.md).
At a glance, M1 needs:

- Camera/UI shell, isometric tile map, zoning, one room lifecycle,
  local saving, diagnostics.

M1 is **done** on `main`. The three parallel vertical slices
(spatial, camera+UI, content+save+locale) and the architectural
foundation (ADRs 0002/0003/0004, src/ module stubs, GUT 9.2.1
setup, SplitMix64 RNG, expanded run_quality.sh) are merged. The
local quality command `./tools/run_quality.sh` runs end-to-end
and is fully green: 7 scripts, 32 tests, 299 asserts, 0 failures,
~0.27s. See the M1-Closeout entry in `CHANGELOG.md` for the
detailed status.

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

- M0 is done. M1 is done. M2 is done. The M3-Closeout commit
  will add a new section here that reflects the M3 state.
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
