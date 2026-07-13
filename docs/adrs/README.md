# Architecture Decision Records

This directory holds the project's Architecture Decision Records
(ADRs). See [0001-record-architecture-decisions.md](0001-record-architecture-decisions.md)
for the format, lifecycle, and the rule for when an ADR is required.

## When to write an ADR

You should write an ADR when a decision:

- Changes a module boundary, public API, or data schema
  (e.g. save format, locale key schema, content data schema).
- Adopts or replaces an engine feature, dependency, build tool,
  or distribution channel.
- Sets a new contributor workflow rule (e.g. branching model,
  required CI checks).
- Locks in a non-trivial technology or platform choice
  (e.g. renderer, input model, i18n framework).
- Sets a project-wide license, branding, or trademark posture.
- Is likely to be re-litigated by a future contributor.

You do **not** need an ADR for:

- Internal refactors that do not change public behaviour.
- Routine content additions governed by an existing ADR.
- One-off bug fixes.
- Style nits and copy edits in docs (file a PR directly).

## Index

| Number | Title | Status | Date |
|-------:|-------|--------|------|
| [0001](0001-record-architecture-decisions.md) | Record architecture decisions | accepted | 2026-07-13 |
| [0002](0002-module-boundaries.md) | Module boundaries and data flow | accepted | 2026-07-13 |
| [0003](0003-save-format.md) | Save format and versioning | accepted | 2026-07-13 |
| [0004](0004-spatial-model.md) | Spatial model | accepted | 2026-07-13 |

## Conventions

- Filename: `NNNN-short-kebab-case-slug.md`, zero-padded.
- Frontmatter is required: `status`, `date`, `deciders`,
  `consulted`, `informed`.
- Status values: `proposed`, `accepted`, `superseded by NNNN`,
  `rejected`.
- ADRs are immutable once accepted. To change a decision, write a
  new ADR that links back to the one it supersedes and update the
  status of the old one.
- The PR description for the new ADR must explicitly call out
  supersession.
