---
status: accepted
date: 2026-07-13
deciders: project leads
consulted: contributors
informed: all contributors
---

# 1. Record architecture decisions

## Context and problem statement

PitPact will accumulate non-trivial architectural decisions over its
lifetime: which engine, which scripting language, which module
boundaries, which save format, which dependency license posture,
which renderer, etc. Many of these decisions are made once and then
constrain the project for years.

Without a written record, we lose the *why* of those decisions. New
contributors either re-litigate old choices, or quietly re-invent
them. The result is design drift disguised as progress.

§16.3 and §17 of `docs/requirements.md` make the ADR practice
explicit: "Architecture Decision Record (ADR) … when they affect
module boundaries or contributor workflow."

We need a lightweight, low-friction way to record these decisions
in-tree so they live with the code.

## Decision drivers

- **Traceability.** A new contributor can find out *why* a choice
  was made without asking the original author.
- **Reversibility.** A decision is recorded as a snapshot, not a
  tombstone. Superseded decisions are explicitly marked.
- **Low overhead.** If recording a decision is expensive, people
  stop doing it. The format must fit in a single small file.
- **Discoverability.** ADRs live in the repo, in a known directory,
  numbered, with a clear index.

## Considered options

1. **MADR 4.x** (this) — Markdown Any Decision Record. Small, single
   file per decision. YAML frontmatter for tooling. Mature ecosystem.
2. **"Lightweight" prose in a `decisions/` folder.** Lower process,
   higher drift. No status field, no consistency.
3. **External wiki / Google Doc.** Discoverable only by people who
   already know it exists. Goes stale.
4. **GitHub Discussions / Issues.** Search-friendly, but easy to
   bury and hard to keep in version with the code.

## Decision outcome

Chosen option: **MADR 4.x** (Markdown Any Decision Records).

The project will use MADR-flavoured ADRs:

- One file per decision, kept under `docs/adrs/`.
- Filename format: `NNNN-short-kebab-case-slug.md`, zero-padded
  four-digit number, no extension gymnastics.
- Frontmatter with `status`, `date`, `deciders`, `consulted`,
  `informed` so future tooling can index decisions.
- Status values: `proposed`, `accepted`, `superseded by NNNN`,
  `rejected`.
- ADRs are immutable once accepted; supersession is recorded by
  changing the status of the old ADR and writing a new one that
  links back.

### Consequences

- Good, because decisions live with the code in version control.
- Good, because the format is small enough that recording is cheap.
- Good, because the frontmatter lets future tooling (search,
  status reports) index ADRs without parsing prose.
- Bad, because a heavy ADR culture can become process for
  process's sake. We mitigate by keeping the format tiny and
  requiring an ADR only for choices that affect module boundaries
  or contributor workflow, not for every code review nit.
- Bad, because the index is implicit. We will add a generated
  `docs/adrs/README.md` index in the M0 closeout PR.

### Confirmation criteria

This ADR is considered effective when:

- [ ] `docs/adrs/` contains a MADR-0001 file using this format.
- [ ] The next architectural decision is recorded as MADR-0002.
- [ ] `AGENTS.md` references the ADR practice in its
      "documentation expectations" section.

## Pros and cons of the options

### MADR 4.x

- Good, small.
- Good, mature convention.
- Good, frontmatter is grep- and tool-friendly.
- Neutral, requires a tiny bit of contributor education.
- Bad, slightly more overhead than free-form prose.

### Free-form prose in `decisions/`

- Good, lowest possible overhead.
- Bad, status drift; no supersession model.
- Bad, no tooling can index.

### External wiki / Google Doc

- Good, easy to edit for non-developers.
- Bad, not in version control.
- Bad, goes stale.

### GitHub Discussions / Issues

- Good, search-friendly, public.
- Bad, easy to bury.
- Bad, hard to keep in sync with the code at the relevant commit.

## More information

- MADR project: <https://adr.github.io/madr/>
- §16.3 of `docs/requirements.md` (planned repository structure).
- §17 of `docs/requirements.md` (documentation expectations).
- `AGENTS.md` (documentation expectations section).
