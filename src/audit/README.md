# src/audit

Event log, diagnostic snapshots, replay/seed manifests.
Read-only on the simulation.

## Purpose

`src/audit` is the diagnostic layer. It receives events
emitted by the simulation and the realm façade, persists
them, and exposes read-only queries that the UI binds to
(event log, replay scrubber, seed manifest inspector).

The audit layer is a **passive observer**. It does not
modify the simulation; it does not call back into the
realm; it does not render. It exists so that the
deterministic-replay guarantee of §16 of the requirements
spec has a faithful, replayable record of what happened,
when, and why.

## Responsibility

`src/audit`:

- receives a structured event stream from the simulation
  and the realm façade,
- persists the event stream to a sidecar log file (lands
  with M2) and/or to a circular in-memory buffer,
- exposes read-only queries (`events_between(from, to)`,
  `events_about(subject)`, `seed_manifest()`),
- emits the seed manifest the save format embeds in
  `body.seed` (see ADR-0003).

`src/audit` does **not** simulate, does **not** render, and
does **not** push state back into the simulation.

## Public entry point

`class_name AuditLog` — one instance per realm. Obtained via
`AuditLog.for_realm(realm)`.

The full API (`record(event)`, `events_between(from, to)`,
`seed_manifest()`, …) will be documented in this section
as the M2 commit lands the real audit log. Until then the
public entry point is the `class_name AuditLog` declared in
`audit.gd`.

## Main dependencies

- `src/core` — for primitives (event-id types, the
  canonical time type, the canonical hashing helper used
  to fingerprint the seed manifest).

## Must NOT depend on

- `src/world`, `src/sim`, `src/realm`, `src/save`, `src/ui`
  — the audit layer must remain a passive observer so
  that simulation determinism is not perturbed by
  diagnostic collection.
- The Godot scene tree.

The mechanical check for this rule lives in
[`tools/check_module_dependencies.sh`](../../tools/check_module_dependencies.sh).

## Files

| File | Public class | Status |
|------|--------------|--------|
| [`audit.gd`](audit.gd) | `AuditLog` (stub) | M1 stub |
| (lands with M2) | the real event log, the seed manifest, the diagnostic snapshot helpers | planned |

## See also

- [`docs/adrs/0002-module-boundaries.md`](../adrs/0002-module-boundaries.md)
- [`docs/adrs/0003-save-format.md`](../adrs/0003-save-format.md)
- [`docs/requirements.md`](../requirements.md) §16, §18
