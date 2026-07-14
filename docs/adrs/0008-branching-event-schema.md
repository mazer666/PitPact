---
status: accepted
date: 2026-07-14
deciders: project leads
consulted: contributors
informed: all contributors
---

# 8. Branching-event schema

## Context and problem statement

`docs/requirements.md` §11 requires the game to ship
*branching events* in M3: "Players face branching
decisions during crises and key moments. Choices have
short- and long-term consequences that shape the
realm." §11 also names the *First Inspection* crisis as
the M2/M3 archetype: a player-influenced event that
threatens the realm and that has a list of choices, each
with consequences.

The M2 Track B commit (already on `main`) shipped the
`Crisis` data carrier in `src/sim/crisis.gd` with a
`Choice` shape that has an `effect: Callable` — a runtime
function the sim invokes when the player picks the
choice. The `effect` is *terminal*: it applies a
consequence (e.g. a morale penalty) and the crisis is
resolved. The M2 contract works for the M2 acceptance
("a crisis with terminal choices") but it does **not**
support the M3 acceptance ("branching events with
short- and long-term consequences"): there is no way for
a choice's consequence to be *another event* (a
follow-up anchor at day 21), and there is no way for
content (a `.tres` file under `data/events/`) to express
the follow-up without writing GDScript.

Two parallel tracks will follow this skeleton: Track A
(world generator; ADR-0007) and Track B (branching
events, this ADR). Track B needs a *content-driven*
schema that:

1. lets a `.tres` file express a choice whose
   consequence is a terminal effect (the M2
   default — e.g. a morale penalty),
2. lets a `.tres` file express a choice whose
   consequence is *another event node* (the M3
   acceptance — e.g. a follow-up anchor at day 21),
3. preserves the M2 contract for the choices
   that do not need to branch (the existing
   `FirstInspection.tres` choices for
   `evade_inspector` and `confront_inspector`
   stay terminal),
4. upgrades one M2 choice — `receive_inspector`
   — to a branching consequence with two
   children (`accept_audit`, `counter_offer`),
   as the M3 acceptance demo,
5. is mechanically checkable: a test loads the
   `FirstInspection` crisis, asserts the
   `receive_inspector` choice's `consequence`
   is a `Variant` of the documented shape, and
   asserts the two children's `consequence` are
   themselves `Dictionary` (terminal) or
   `Resource` (follow-up).

Without a written contract, the M3 cycle 2 Track B
commit will invent a schema under pressure, the
schema will not match the `effect: Callable` shape
the M2 code already uses, and the M2 Track B tests
will break the moment a `.tres` file expresses a
follow-up. The breakage will be invisible in code
review because the schema will be invented in the
`CrisisDef` validator.

## Decision drivers

- **Content-driven follow-ups.** §11. A branching
  event is a *player-picked path through a tree of
  consequences*. The tree is content; the runtime
  walks it. A schema that requires GDScript to
  express a follow-up (a custom `Callable` for
  every branch) defeats the purpose of having a
  content-driven crisis system.
- **M2 compatibility.** The M2 Track B commit on
  `main` already exposes `Crisis.choices[*].effect`
  as a `Callable` and the sim's per-tick
  crisis-resolution rule invokes the `effect`. A
  schema that breaks the M2 contract forces a
  rewrite of the M2 sim, the M2 tests, and the
  M2 content. The M3 schema is an *extension* of
  the M2 schema, not a replacement.
- **One-inhabitant-per-crisis, one-follow-up-per-
  choice.** A choice's consequence is either a
  terminal effect (one value, applied once) or a
  follow-up event node (one resource, scheduled
  once). The schema's type system must distinguish
  the two cleanly: a `Dictionary` is a terminal
  effect; a `Resource` is a follow-up node. The
  distinction is structural, not nominal; a
  follow-up that is also a terminal effect is a
  misuse of the schema and is rejected at load
  time.
- **Determinism.** §16, ADR-0005. The M2
  crisis-resolution rule is a pure function on
  the sim's RNG state; the M3 follow-up rule
  must be the same. A follow-up node's
  `trigger_at_day` is content-defined; the
  per-tick rule consults it the same way it
  consults the root crisis's
  `trigger_at_day`. The determinism contract
  is preserved without changes to ADR-0005.
- **Mechanical checkability.** §18. A schema
  that can be exercised by a unit test ("load
  the FirstInspection crisis; assert the
  receive_inspector choice is a `Variant` whose
  runtime type is a `Resource`; assert the two
  children are themselves `Dictionary` and
  `Dictionary`") is what makes the schema
  load-bearing. The test is the M3 cycle 2
  Track B commit's responsibility; this ADR
  pins the schema the test asserts.

## Considered options

1. **Variant consequence — `Dictionary` is
   terminal, `Resource` is follow-up, and the
   M2 `FirstInspection` `receive_inspector`
   choice is upgraded to a branching
   consequence with two children
   (`accept_audit`, `counter_offer`)** (this).
2. **Two-field consequence: `effect` (the M2
   `Callable` for terminal effects) and
   `follow_up` (a new `Resource` reference for
   follow-ups).** Rejected: the two-field
   shape forces callers to check both fields,
   and a misuse (both fields set, or neither
   set) is a runtime error rather than a
   load-time validation error. A `Variant`
   with a clean "Dictionary means terminal,
   Resource means follow-up" rule is
   unambiguous and load-time-checkable.
3. **Tree-as-`Resource` everywhere — every
   node is a `Resource`, and the root crisis
   is a `Resource` that the sim's per-tick
   rule walks.** Rejected: forces a
   re-shape of the M2 `Crisis` class (the
   per-tick rule currently walks
   `Crisis.choices` directly, not a tree),
   and the upgrade would touch every M2
   crisis test. The M3 contract is an
   *extension*: the root crisis is still a
   `Crisis` (a `RefCounted`, not a
   `Resource`), and only the *consequence*
   side of a choice becomes a `Resource` (or
   stays a `Dictionary` for terminal
   effects).
4. **Tree-as-callable graph — every node is
   a `Callable`, content packs ship
   `.gd` files alongside `.tres` files.**
   Rejected: §17 (code quality) and §25
   (open design decisions) forbid content
   packs from shipping executable code; the
   `Callable` shape is the M2 contract for
   the *terminal* consequence only. A
   `Resource` follow-up is a data-only
   expression of a follow-up event.
5. **No `Variant` — every consequence is
   always a `Resource`, and a "terminal
   effect" is a `Resource` of type
   `EffectDef` that the sim's effect-walker
   applies.** Rejected: forces every M2
   choice to be re-shaped into a Resource,
   and the M2 tests' `effect: Callable` shape
   is replaced. A `Variant` keeps the M2
   shape for terminal effects and adds the
   M3 shape for follow-ups.

## Decision outcome

Chosen option: **Variant consequence —
`Dictionary` is terminal, `Resource` is
follow-up, and the M2 `FirstInspection`
`receive_inspector` choice is upgraded to a
branching consequence with two children
(`accept_audit`, `counter_offer`).**

### The event-node tree shape

A branching event is a tree of `EventNode`s. The
root of the tree is a `Crisis` (a `RefCounted`
in `src/sim/crisis.gd`). Each `Crisis` has a
`trigger: Condition` and a list of `Choice`s.
Each `Choice` has a `consequence` which is
itself an `EventNode`. A consequence can be:

- a **terminal `Effect`** — a `Dictionary` of
  effect-tag / effect-value pairs, applied
  once when the player picks the choice; the
  crisis is then resolved (the M2 default).
- a **non-terminal `EventNode`** — a
  `Resource` of type `BranchNodeDef` (defined
  in `src/content/branch_node_def.gd`,
  planned for the M3 cycle 2 Track B commit)
  that the sim schedules as a follow-up; the
  root crisis is resolved and the follow-up
  is added to the sim's `crises` set (or to a
  parallel `pending_branches` set; the M3
  cycle 2 commit pins the exact home).

The tree's leaves are always terminal `Effect`s
(the player cannot keep branching forever; the
M3 acceptance is "short- and long-term
consequences", not "infinite branching"). The
tree's branching factor is content-defined
(the M3 default is two; M5 content can use
more).

### The schema

`Choice.consequence` is a `Variant` that is
either a `Dictionary` or a `Resource`. The
type-driven rule is:

| Runtime type | Meaning | Load-time validation |
|--------------|---------|----------------------|
| `Dictionary` | Terminal effect. Applied once when the player picks the choice. The dictionary's keys are effect tags (`&"morale_penalty"`, `&"reputation_loss"`, `&"resource_grant"`, …) and the values are effect values (floats, ints, StringNames). The M2 contract is preserved: a `Dictionary` consequence is applied by the M2 sim's per-tick crisis-resolution rule, exactly the way the M2 `effect: Callable` was applied. | The dictionary MUST be non-empty (a terminal effect with zero effect-tags is a content error and is rejected at load time with `CrisisDef.validate` returning an error). |
| `Resource` (of type `BranchNodeDef`) | Follow-up event node. The `BranchNodeDef` is scheduled as a follow-up; the root crisis is resolved. The follow-up has its own `trigger_at_day`, its own `display_name`, its own `summary`, and its own `children` (a list of `Choice` records, each with its own `consequence`). | The resource MUST be a `BranchNodeDef` (the type check is the runtime `is BranchNodeDef` predicate; the validator runs the check at load time). |

A consequence that is neither a `Dictionary` nor
a `Resource` of type `BranchNodeDef` is a
content error and is rejected at load time.

### The upgrade rule for `FirstInspection`

The M2 Track B `data/events/first_inspection.tres`
already has three choices:

- `receive_inspector` — terminal
  (M2 default).
- `evade_inspector` — terminal (stays
  terminal in M3).
- `confront_inspector` — terminal (stays
  terminal in M3).

The M3 foundation commit upgrades
`receive_inspector` from a terminal
consequence to a branching consequence with
two children:

- `accept_audit` — terminal effect
  (`{"morale_penalty": 0.1, "reputation_loss":
  0.05}`). The player accepts the audit; the
  realm pays a short-term morale and
  reputation hit but escapes follow-up.
- `counter_offer` — non-terminal follow-up
  (a `BranchNodeDef` resource of type
  `BranchNodeDef` with `trigger_at_day =
  21.0`, `display_name =
  &"CRISIS_FOLLOWUP_COUNTER_OFFER"`, and
  a list of two child choices, each terminal).
  The player counters; the realm schedules a
  follow-up event 21 in-game days later.

The upgrade is a *content* change
(`data/events/first_inspection.tres` is
re-shaped; the M2 `effect: Callable` shape is
replaced by a `consequence` field that is a
`Variant` of the documented shape). The M2
`Crisis` class does **not** change; the M2
sim's per-tick crisis-resolution rule is
*extended* to recognise the `Resource` shape
and schedule the follow-up.

The upgrade lands in the M3 foundation
commit's companion data file; the M2
`first_inspection.tres` is updated in place.
The M2 Track B tests
(`tests/integration/test_crisis_trigger.gd`)
continue to pass because the
`evade_inspector` and `confront_inspector`
choices' terminal consequences are preserved
as `Dictionary` effects.

### The deterministic-replay invariant

The branching-event schema does not change
the determinism contract. The per-tick
crisis-resolution rule (ADR-0005, step 7) is
extended with a single new branch: when a
choice's `consequence` is a `Resource`, the
sim resolves the choice (sets `resolved =
true`, appends a `crisis.choice_made` event
to the log) and schedules the follow-up
(creates a new `Crisis` from the
`BranchNodeDef`'s children and adds it to
`sim.crises`). The follow-up's `id` is the
`BranchNodeDef.id`; its `trigger_at_day` is
the `BranchNodeDef.trigger_at_day`; its
`choices` are the `BranchNodeDef.choices`.

The extension is a pure function on the
sim's RNG state. The per-tick rule still
runs in the same order (step 7 of ADR-0005);
the extension is *inside* step 7, not a
new step. The deterministic-replay invariant
("same seed + same input events ⇒ same
state at every tick") is preserved.

### What the schema does *not* pin

The contract pins the *shape* of `Choice.consequence`
and the *type* of the follow-up resource. It does
not pin:

- the **effect-tag set** the terminal
  `Dictionary` may contain. The M2 default is
  `morale_penalty`, `reputation_loss`, and
  `resource_grant`; M5 content can add more.
  The validator accepts any non-empty
  `Dictionary` whose keys are `StringName` and
  whose values are JSON-friendly primitives.
- the **follow-up's `Condition`**. The follow-up
  is a `BranchNodeDef`; the M3 cycle 2 Track B
  commit pins the `Condition` field. The
  foundation commit reserves the field but
  does not pin its shape.
- the **follow-up's depth**. The M3 default
  caps the tree depth at 2 (root + one
  follow-up level); the validator asserts the
  cap. M5 content can override the cap by
  shipping a deeper tree, but the override
  requires a new ADR.
- the **per-inhabitant follow-ups**. A
  follow-up that affects a single inhabitant
  is a content choice; the schema does not
  distinguish single-inhabitant from
  realm-wide follow-ups.

### Module-boundary impact

Per ADR-0002, `src/sim` is forbidden from
importing `src/ui`, `src/realm`, or `src/save`.
This ADR reinforces that rule for the M3
follow-ups: the per-tick rule that schedules
a follow-up does not call into the realm
façade to fetch the time, does not read from
the save layer to reload follow-up state
mid-tick, and does not project anything onto
the screen.

The follow-up's `BranchNodeDef` resource lives
in `src/content/` (data only). The M3 cycle 2
Track B commit owns the `branch_node_def.gd`
schema. The M3 foundation commit lands the
*shape* (the ADR); the schema file lands
in the Track B commit.

### Mechanical enforcement

The branching-event schema is mechanically
enforced by a test in
`tests/integration/test_branching_event.gd`
(M3 cycle 2, Track B). The test:

1. loads `data/events/first_inspection.tres`
   via `ContentRegistry`,
2. asserts the `receive_inspector` choice's
   `consequence` is a `Variant` whose
   runtime type is a `Resource` of type
   `BranchNodeDef`,
3. asserts the two children's `consequence`
   are themselves `Dictionary` (terminal)
   and `Resource` (follow-up),
4. asserts the `evade_inspector` and
   `confront_inspector` choices' consequences
   are `Dictionary` (terminal, M2 contract
   preserved),
5. runs the M2 sim through the M2 tick
   sequence with the upgraded
   `FirstInspection` crisis and asserts the
   follow-up is scheduled at the right tick
   (the M3 cycle 2 Track B commit owns the
   per-tick rule; the foundation commit
   preserves the M2 behaviour).

A regression in the schema (a
`receive_inspector` consequence that is
neither `Dictionary` nor `Resource`), in the
type-driven rule (a `Resource` consequence
that is not a `BranchNodeDef`), or in the
M2 contract (a terminal consequence that is
no longer a `Dictionary`) will fail this
test.

The module-dependency check
(`tools/check_module_dependencies.sh`) enforces
the boundary mechanically today; the
branching-event test is the companion
mechanical check for this ADR.

### Consequences

- Good, because the schema is *content-driven*.
  A follow-up anchor at day 21 is a
  `.tres` file under `data/events/`; no
  GDScript is required to express it.
- Good, because the M2 contract is
  *preserved*. The M2 Track B tests continue
  to pass; the M2 `Crisis` class does not
  change; the M2 sim's per-tick
  crisis-resolution rule is *extended*, not
  *replaced*.
- Good, because the type-driven rule is
  *load-time-checkable*. A consequence that
  is neither `Dictionary` nor `Resource` is
  rejected at load time, not at runtime.
- Good, because the determinism contract
  is *preserved*. The M5 replay feature can
  rebuild a campaign from a seed and an
  event log without ever reading the
  follow-up's residual state.
- Good, because the upgrade is *localised*.
  The `data/events/first_inspection.tres`
  file is re-shaped; the M2 code is not.
- Bad, because `Variant` is a
  load-bearing constraint. A future
  content author who reads the schema and
  reaches for "let me make
  `consequence` always be a `Resource`"
  will be confused by the type-driven rule.
  The rule is documented in this ADR; the
  load-time validation is the safety net.
- Bad, because the schema is one more
  concept to teach a new contributor. The
  cost is small (one table, one rule, one
  example); the benefit is that the M3
  acceptance ("branching events with
  short- and long-term consequences") is a
  *data* contract, not a *code* contract.

### Confirmation criteria

This ADR is considered effective when:

- [ ] `docs/adrs/0008-branching-event-schema.md`
      exists with this frontmatter and this
      decision outcome.
- [ ] `data/events/first_inspection.tres` is
      re-shaped: `receive_inspector`'s
      consequence is a `Resource` of type
      `BranchNodeDef` with two children;
      `evade_inspector` and `confront_inspector`'s
      consequences are `Dictionary` (terminal,
      M2 contract preserved).
- [ ] `src/content/crisis_def.gd` is
      extended with a `consequence: Variant`
      field on each choice and a
      `validate()` rule that rejects choices
      whose `consequence` is neither
      `Dictionary` nor `Resource` of type
      `BranchNodeDef`.
- [ ] The M2 `Crisis` class in
      `src/sim/crisis.gd` continues to
      expose `choices` as an `Array` of
      `Dictionary` records with the canonical
      keys (`id`, `display_name`,
      `consequence_summary`, `effect`); the
      `consequence` field is *additive* and
      is consulted by the M3 per-tick
      crisis-resolution rule.
- [ ] `tools/check_module_dependencies.sh`
      is green against the new content
      files.
- [ ] `./tools/run_quality.sh` is green at
      the end of the M3-foundation commit
      and the M3 cycle 2 Track B commit.

## Pros and cons of the options

### Variant consequence — `Dictionary` is terminal, `Resource` is follow-up, M2 `FirstInspection` `receive_inspector` upgraded to branching consequence with two children

- Good, content-driven.
- Good, M2 contract preserved.
- Good, type-driven rule is load-time-
  checkable.
- Good, determinism contract preserved.
- Good, upgrade is localised.
- Bad, `Variant` is load-bearing.
- Bad, one more concept to teach.

### Two-field consequence: `effect` and `follow_up`

- Good, fields are explicit.
- Bad, two-field shape forces callers to
  check both fields.
- Bad, a misuse (both set, or neither set)
  is a runtime error.
- Bad, no clean "Dictionary means terminal,
  Resource means follow-up" rule.

### Tree-as-`Resource` everywhere

- Good, uniform shape.
- Bad, forces a re-shape of the M2
  `Crisis` class.
- Bad, the M2 per-tick rule would have to
  walk a tree, not a flat list.
- Bad, the M2 Track B tests would have to
  be re-shaped.

### Tree-as-callable graph

- Good, flexible.
- Bad, content packs ship GDScript.
- Bad, §17 and §25 forbid executable code
  in content packs.

### No `Variant` — every consequence is a `Resource`

- Good, uniform shape.
- Bad, forces every M2 choice to be
  re-shaped.
- Bad, the M2 `effect: Callable` shape is
  replaced.

## More information

- `docs/requirements.md` §11 (conflict and
  crises), §16 (technical architecture),
  §17 (code quality), §18 (testing and local
  quality gates), §25 (open design decisions).
- ADR-0001 (record architecture decisions).
- ADR-0002 (module boundaries) — the `src/sim`
  and `src/content` boundaries this ADR
  reinforces.
- ADR-0005 (sim-tick determinism) — the
  per-tick crisis-resolution rule this ADR
  extends.
- `src/sim/crisis.gd` — the M2 `Crisis` class
  this ADR extends.
- `src/content/crisis_def.gd` — the M2
  `CrisisDef` schema this ADR extends.
- `data/events/first_inspection.tres` — the
  M2 crisis data file this ADR re-shapes.
- `tests/integration/test_crisis_trigger.gd`
  — the M2 test that this ADR preserves.
- `tests/integration/test_branching_event.gd`
  (M3 cycle 2, Track B) — the full
  branching-event test.
