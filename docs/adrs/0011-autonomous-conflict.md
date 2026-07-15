---
status: accepted
date: 2026-07-15
deciders: project leads
consulted: contributors
informed: all contributors
---

# 11. Autonomous conflict and the two M4 crises

## Context and problem statement

`docs/requirements.md` §11 (conflict and crises)
requires that "inhabitants resolve most combat
autonomously through role, behaviour,
relationships, position, and current condition".
The Pactmaker "may exert limited tactical
influence through powers and decrees", but the
default resolution path is *autonomous*: no
Pactmaker input, the conflict resolves itself
through the per-tick rule. §11 also requires
that "the first release includes two major
crises". The M4 row in `docs/milestones.md` (and
§23 of the requirements) is "autonomous conflict,
two crises, difficulty/settings".

The M2 commit on `main` already shipped the
sim-tick pipeline (ADR-0005), the per-tick
crisis-evaluation rule (step 7 of `Sim.tick()`),
and the `Crisis` data carrier
(`src/sim/crisis.gd`). The M2 default crisis
(`FirstInspection`) is *player-driven*: the
player picks a choice and the sim applies it.
The M4 acceptance adds two more crises that are
*autonomous*: no Pactmaker input, the sim
resolves them through the per-tick rule.

Without a written contract, three implicit
choices will surface as bugs in the M4 closeout
review:

1. **What is "autonomous resolution"?** A
   crisis that has no Pactmaker input and that
   resolves through the per-tick rule. The rule
   must be deterministic (ADR-0005), must not
   call into the realm façade, and must emit a
   `crisis.resolved` event to the log with the
   resolution choice's id (a content-defined
   sentinel like `&"resolved.autonomous"`).
2. **What crises are the M4 default?** §11
   names "two major crises" but does not name
   them. The M4 default is `plague_outbreak`
   (a need-collapse crisis: the realm's
   `food` and `safety` needs decay faster
   for the crisis's duration; the per-tick
   rule resolves the crisis when the realm's
   average `safety` need has recovered
   above a content-defined threshold) and
   `faction_dispute` (a faction-relationship
   crisis: a faction's `stance` toward
   another faction drops below a
   content-defined threshold; the per-tick
   rule resolves the crisis when the
   stance recovers above the threshold).
3. **What is the deadline mechanic?** A crisis
   that does not resolve by its `trigger_at_day
   + autonomous_resolution_days` is
   *force-resolved* with a sentinel
   `&"resolved.deadline"` choice and an
   adverse content-defined consequence (e.g.
   a morale penalty, an inhabitant death, a
   faction hostility bump). The deadline is
   the *Pactmaker's last chance to influence
   the crisis*: the player can still pick a
   player-driven choice before the deadline
   fires; once the deadline fires, the
   crisis is *gone* (resolved with the
   adverse sentinel).

The M4 foundation commit ships the data
carriers (`Crisis.autonomous_resolution_days`,
`Faction`, the `Settings` carrier) and the
two M4 default crises' data files
(`data/crises/plague_outbreak.tres`,
`data/crises/faction_dispute.tres`); the M4
Track A commit fills in the per-tick
autonomous-resolution rule and the
deadline rule. This ADR pins the contract the
Track A commit honours.

## Decision drivers

- **Determinism.** §16, ADR-0005. The
  per-tick rule is a pure function on
  the realm's state and the sim's RNG
  state. The deadline mechanic must
  fire on a known tick (the *end-of-tick*
  clock is `time_days + delta_days`,
  the same value the event log stores);
  a deadline that fires on the wrong
  tick is a save/load replay bug.
- **Content-driven.** §10, §17, ADR-0008.
  The two M4 crises are `.tres` files
  under `data/crises/`; the autonomous
  resolution rule is a content-defined
  `Callable` on the crisis data, not a
  GDScript switch on the crisis id. A
  `Callable` is allowed because the
  per-tick rule *invokes* it; the
  content file does not *embed* it
  (the file references a registered
  function in `src/sim/crisis.gd`).
- **One crisis, one resolution rule.**
  The M4 default is "every crisis has
  either a player-driven `choices`
  list (M2 contract) OR an
  `autonomous_resolution: Callable`
  field (M4 contract) OR both". A
  crisis that has both is a *hybrid*;
  the M4 Track A commit pins the
  hybrid behaviour (the player can
  pick a choice before the deadline;
  the deadline fires if the player
  has not picked a choice by the
  deadline tick). The M4 foundation
  commit reserves the field; the M4
  Track A commit fills the rule.
- **Deadline is a Pactmaker's last
  chance.** A deadline that fires
  before the player has had a turn to
  pick a choice is a UX bug; the M4
  Track A commit pins the deadline
  tick as `trigger_at_day +
  autonomous_resolution_days` and the
  per-tick rule's deadline check
  happens *after* the per-tick
  step that consults the player's
  choice (the M2 contract is
  preserved: the player's choice is
  consulted first; the deadline is
  the fallback). A deadline that
  fires before the player has had a
  chance to pick a choice is a
  content error and is rejected at
  load time with `autonomous_resolution_days
  < 1.0` raising `CrisisDefError`.
- **Mechanical checkability.** §18. A
  contract that can be exercised by a
  unit test ("load the two M4 crises,
  assert `autonomous_resolution_days`
  is at least `1.0`; tick the sim
  through the crisis's `trigger_at_day`
  + `autonomous_resolution_days`; assert
  the `crisis.resolved` event's
  `choice_id` is the
  `resolved.deadline` sentinel")
  is what makes the contract
  load-bearing. The M4 foundation
  smoke test exercises the
  *carrier*; the M4 Track A test
  exercises the *per-tick rule* and
  the *deadline mechanic*.

## Considered options

1. **`autonomous_resolution: Callable`
   field on the `Crisis` data
   carrier, two M4 default crises
   (`plague_outbreak`,
   `faction_dispute`), deadline
   mechanic pinned to
   `trigger_at_day +
   autonomous_resolution_days`
   with `resolved.deadline`
   sentinel** (this). The
   `autonomous_resolution: Callable`
   is the per-tick rule the sim
   invokes; the `autonomous_resolution_days`
   is the deadline; the
   `resolved.deadline` sentinel is
   the choice id the event log
   records when the deadline
   fires.
2. **No `Callable`; the sim
   switch-cases on the crisis id.**
   Rejected: §17 and §25 forbid
   content packs from shipping
   executable code; an id-based
   switch is a per-crisis `if` in
   the sim, which is exactly the
   "executable code in the sim"
   pattern the §17 rule
   prohibits. A `Callable` is
   allowed because the *rule
   itself* lives in the sim (the
   `Callable` is a registered
   function on `Crisis`, not a
   content-defined GDScript
   function).
3. **No deadline mechanic; the
   crisis resolves when the
   realm's state meets the
   autonomous condition.** Rejected:
   the M4 acceptance is "two
   crises", and a crisis that
   never resolves is not a
   crisis; a crisis that resolves
   only when the realm's state
   happens to meet a condition
   is not *autonomous* (the
   player has no signal that the
   crisis is "about to resolve").
   The deadline is the *signal*.
4. **Deadline mechanic with
   `resolved.timeout` sentinel.**
   Rejected: `timeout` is a
   programming term; `deadline`
   is the game's term. The
   sentinel is `resolved.deadline`
   to match the player's mental
   model (the player is not
   waiting for a timeout; the
   player is racing a deadline).
5. **Two M4 default crises are
   `plague_outbreak` and
   `first_inspection`; the
   M2 crisis is the M4 second
   default.** Rejected: `first_inspection`
   is already shipped (M2); the
   M4 acceptance is "two NEW
   crises" that are *autonomous*
   (the M2 default is
   *player-driven*). The M4
   foundation commit ships the
   two NEW crises
   (`plague_outbreak` and
   `faction_dispute`); the
   M2 crisis is left untouched.

## Decision outcome

Chosen option: **`autonomous_resolution:
Callable` field on the `Crisis` data
carrier, two M4 default crises
(`plague_outbreak`, `faction_dispute`),
deadline mechanic pinned to
`trigger_at_day +
autonomous_resolution_days` with
`resolved.deadline` sentinel.**

### The `Crisis` extensions

The M2 `Crisis` data carrier
(`src/sim/crisis.gd`) gains three new
fields:

| Field | Type | Meaning |
|-------|------|---------|
| `autonomous_resolution` | `Callable` | The per-tick rule the sim invokes to test "is this crisis autonomously resolved?". The signature is `func(time_days: float, sim: Sim, inhabitants: Array) -> bool`. The default is `Callable()` (no autonomous rule). A non-empty `Callable` is the M4 signal "this crisis resolves itself". |
| `autonomous_resolution_days` | `float` | The deadline, in in-game days from `trigger_at_day`. The default is `-1.0` (no deadline; the crisis is either player-driven or has no deadline). A positive value is the M4 signal "this crisis has a Pactmaker's last chance". |
| `deadline_consequence` | `Dictionary` | The content-defined consequence the sim applies when the deadline fires. The default is `{}`. A non-empty dictionary's keys are effect tags the sim applies (the schema is the same as `BranchNode.terminal_effect` in ADR-0008: `morale_delta: float`, `needs_food_delta: float`, `follow_up_anchor_id: StringName`). |

The M2 contract is preserved: a crisis
that does not set the three new fields
behaves exactly as the M2 tests expect.
The M4 Track A commit is the first commit
that reads the three new fields; the M4
foundation commit reserves the slots.

### The two M4 default crises

`data/crises/plague_outbreak.tres` and
`data/crises/faction_dispute.tres` are
the M4 default crises. The M4 foundation
commit ships the data files; the M4
Track A commit ships the per-tick rule
that consumes them.

#### `plague_outbreak`

A need-collapse crisis. The crisis
triggers when the realm's average
`safety` need drops below a
content-defined threshold (the M4
default is `0.3`). The crisis is
*autonomous*: no Pactmaker choice. The
per-tick rule resolves the crisis when
the realm's average `safety` need has
recovered above the threshold
(default `0.6`). The deadline is
`autonomous_resolution_days = 14.0`;
the consequence is a per-inhabitant
`needs_food_delta = -0.2` (a two-week
food shortage that the realm must
absorb). The M4 default `choices` list
is empty (the M2 contract's
"player-driven" path is disabled); the
autonomous rule and the deadline are
the only resolution paths.

#### `faction_dispute`

A faction-relationship crisis. The
crisis triggers when a faction's
`stance[other_faction] <= -0.5`
(hostility threshold). The crisis is
*autonomous*: no Pactmaker choice. The
per-tick rule resolves the crisis when
the faction's `stance[other_faction]`
has recovered above `-0.2` (a
content-defined reconciliation
threshold). The deadline is
`autonomous_resolution_days = 10.0`;
the consequence is
`morale_delta = -0.1` (a per-inhabitant
morale hit; the dispute is unresolved
when the deadline fires). The M4
default `choices` list is empty; the
autonomous rule and the deadline are
the only resolution paths.

### The deadline mechanic

The per-tick rule's deadline check
runs *after* the player-choice check
(the M2 contract is preserved: the
player's choice is consulted first).
The deadline check is:

```
if (not cr.resolved) and cr.autonomous_resolution_days > 0.0:
    var deadline_day: float = cr.trigger_at_day + cr.autonomous_resolution_days
    if post_tick_day >= deadline_day:
        # Deadline fires.
        cr.resolve(post_tick_day, &"resolved.deadline")
        cr._apply_deadline_consequence(post_tick_day, inhabitants)
```

The `cr.resolve(post_tick_day,
&"resolved.deadline")` call is a
*resolution with a sentinel choice*.
The M2 `resolve` method is unchanged
(ADR-0008's branching-event
extensions to `resolve_branch` are
preserved); the sentinel is a
`StringName` the event log records
as the `crisis.choice_made` event's
`choice_id`. The M4 default
`choice_id` is `&"resolved.deadline"`.

The `cr._apply_deadline_consequence(...)`
helper applies the
`deadline_consequence` dictionary's
keys to the inhabitants (the helper
is a thin wrapper over
`Crisis.apply_pending_effects` in
ADR-0008). The M4 default
`deadline_consequence` for
`plague_outbreak` is
`{"needs_food_delta": -0.2}`; the M4
default for `faction_dispute` is
`{"morale_delta": -0.1}`.

### The deterministic-replay invariant

> For any seed `s`, any crisis `c` with
> `c.autonomous_resolution_days > 0.0`,
> and any per-tick `delta_days`, two
> `Sim` instances constructed with the
> same seed and ticked through the
> same `delta_days` produce deep-equal
> `crisis.resolved` event entries with
> the same `choice_id` (`&"resolved.deadline"`)
> and the same
> `deadline_consequence` application
> tick.

The invariant is what
`tests/integration/test_autonomous_conflict.gd`
(M4 Track A) will assert: two `Sim`
instances with the same seed and the
same `plague_outbreak` and
`faction_dispute` crises ticked through
the same `delta_days` produce
deep-equal `crisis.resolved` events
with the same `choice_id` and the
same `deadline_consequence` tick. A
regression in the per-tick rule or
in the deadline mechanic will fail
that test.

### The `Faction` carrier

The M4 foundation commit ships the
`Faction` data carrier
(`src/sim/faction.gd`). The carrier is
a per-realm data structure that
records the realm's relationship
with a *non-inhabitant* faction
(rival realm, surface polity, cult,
academy, etc. — the §6 list). The
M4 acceptance uses the carrier for
`faction_dispute`; the M5 content
pass extends the carrier with more
content (e.g. faction-specific
stance keys, faction-specific
crisis triggers).

| Field | Type | Meaning |
|-------|------|---------|
| `id` | `StringName` | The faction's stable identity. The id is the dictionary key in the realm's faction set. |
| `display_name` | `StringName` | A locale key. The UI's "this faction is called …" panel reads the key. |
| `stance` | `Dictionary[StringName, int]` | The faction's per-target stance. The key is the target faction's id; the value is the stance in `[-100, 100]` (the M4 default integer range; an M5 content pass can widen the range to `[-1.0, 1.0]` if the M5 content needs finer granularity). The stance is *symmetric* in the M4 default: a positive `stance[a][b]` is the same as a positive `stance[b][a]` (the M4 Track A commit asserts the symmetry at save time). |
| `update_stance(other, delta)` | `void` | Nudges the `stance[other]` value by `delta`, clamped to `[-100, 100]`. The method is the canonical way for the per-tick rule to apply a stance change. |
| `is_hostile_to(other) -> bool` | `true` if `stance[other] <= -50` (the M4 default hostility threshold; content-tunable). |

The M2 contract is preserved: a
realm that has never had a `Faction`
registered continues to behave
exactly as the M2 tests expect. The
M4 foundation commit ships the
*carrier*; the M4 Track A commit
fills the per-tick rule that
consumes it.

### The `Settings` carrier

The M4 foundation commit ships the
`Settings` data carrier
(`src/sim/settings.gd`). The
carrier is a per-realm data
structure that records the
player's chosen *difficulty and
preferences* (§12 of
`docs/requirements.md`:
"Narrative, Balanced, Challenging"
presets, per-rule adjustment,
free local save/load). The M4
acceptance uses the carrier for
the difficulty knob; the M5
content pass extends the carrier
with more settings.

| Field | Type | Meaning |
|-------|------|---------|
| `difficulty` | `int` | The difficulty preset, in `0..2`. The M4 default is `1` (Balanced). `0` is Narrative; `2` is Challenging. |
| `auto_resolve_days` | `int` | The number of in-game days the player is willing to wait before the per-tick rule auto-resolves a player-driven crisis. The M4 default is `7`. The M2 contract (`auto_resolve_days == 0` means "no auto-resolve") is preserved. |
| `locale` | `String` | The realm's chosen locale. The M4 default is `"en"`. The M2 contract (`locale == "en"` means English; the locale is the canonical key for the localization layer) is preserved. |

The M2 contract is preserved: a
realm that has never had a
`Settings` registered continues
to behave exactly as the M2 tests
expect (the M2 default
`Settings.from_dict({})` is the
M4 default
`Settings.from_dict({})` is
the M2 default).

### Module-boundary impact

Per ADR-0002, `src/sim` is forbidden
from importing `src/ui`, `src/realm`,
or `src/save`. This ADR reinforces
that rule for the M4 autonomous
conflict: the per-tick rule does
not call into the realm façade to
fetch the player's choice, does not
read from the save layer to reload
crisis state mid-tick, and does not
project anything onto the screen.

The M4 carriers
(`KnowledgeState`, `ResearchNode`,
`Pactmaker`, `Power`, `Faction`,
`Settings`, `M4Skeleton`) live in
`src/sim/`. The M4 Track A commit
extends `Sim.tick()` with the
per-tick rule; the foundation
commit reserves the slots.

### Mechanical enforcement

The autonomous-conflict contract
is mechanically enforced by a test
in
`tests/integration/test_m4_skeleton.gd`
(M4 foundation, this commit) and a
fuller test in
`tests/integration/test_autonomous_conflict.gd`
(M4 Track A). The foundation test
asserts:

- `Crisis.autonomous_resolution`
  defaults to `Callable()`.
- `Crisis.autonomous_resolution_days`
  defaults to `-1.0`.
- `Crisis.deadline_consequence`
  defaults to `{}`.
- `Faction.stance` defaults to
  `{}`.
- `Faction.update_stance(other,
  delta)` clamps the value to
  `[-100, 100]`.
- `Faction.is_hostile_to(other)`
  returns `true` when
  `stance[other] <= -50`.
- `Settings.difficulty` defaults
  to `1` (Balanced).
- `Settings.auto_resolve_days`
  defaults to `7`.
- `Settings.locale` defaults to
  `"en"`.
- `Settings.from_dict(d)` and
  `Settings.to_dict()` round-trip
  (deep-equal on all three fields).

A regression in the M4 carrier
defaults, in the `Faction` stance
clamp, in the `Faction.is_hostile_to`
threshold, or in the `Settings`
round-trip will fail the foundation
smoke test.

The M4 Track A test
(`test_autonomous_conflict.gd`)
asserts the per-tick rule: load
`plague_outbreak.tres` and
`faction_dispute.tres`, tick the
sim through
`trigger_at_day +
autonomous_resolution_days`, assert
the `crisis.resolved` event's
`choice_id` is
`&"resolved.deadline"`, and assert
the
`deadline_consequence` was applied.

A regression in the per-tick
autonomous rule, in the deadline
mechanic, in the
`resolved.deadline` sentinel, or
in the `deadline_consequence`
application will fail the M4 Track
A test.

The module-dependency check
(`tools/check_module_dependencies.sh`)
enforces the boundary mechanically
today; the foundation smoke test is
the companion mechanical check for
this ADR.

### Consequences

- Good, because the autonomous
  resolution is *content-driven*. A
  crisis's `autonomous_resolution`
  rule is a registered `Callable` on
  `Crisis`; the content file
  references the registered
  function by `StringName` (the M4
  default is `&"plague_outbreak.resolve"`
  and
  `&"faction_dispute.resolve"`).
- Good, because the deadline is a
  *signal*. The player has a known
  number of in-game days to pick a
  choice; the deadline fires
  *after* the player has had a
  turn. The deadline is the
  *Pactmaker's last chance*.
- Good, because the
  deterministic-replay invariant
  is preserved. The deadline fires
  on a known tick; the sentinel
  choice id is the same in two
  realms seeded with the same seed
  and ticked with the same
  `delta_days`.
- Good, because the `Faction`
  carrier is *one map read*.
  `is_hostile_to(other)` is a
  constant-time lookup; the
  per-tick rule is O(n) in the
  number of factions.
- Good, because the `Settings`
  carrier is *load-bearing*. The
  difficulty knob and the
  auto-resolve days are the
  canonical place the M5 content
  pass extends.
- Bad, because the deadline
  sentinel is a `StringName`
  load-bearing constant. A future
  content author who reads the
  schema and reaches for "let me
  use `&"timeout"` instead of
  `&"resolved.deadline"`" will be
  confused by the test's
  assertion. The sentinel is
  documented here; the test is
  the safety net.
- Bad, because the
  `autonomous_resolution: Callable`
  is a `Callable` in a content
  file. The §17 rule says "no
  executable code in content
  packs"; the M4 exception is
  documented in this ADR: the
  `Callable` is a *reference* to
  a registered function on
  `Crisis`, not an embedded
  GDScript function. The
  exception is the smallest
  possible footprint that lets
  the M4 acceptance be
  *content-driven*.

### Confirmation criteria

This ADR is considered effective when:

- [ ] `docs/adrs/0011-autonomous-conflict.md`
      exists with this frontmatter and
      this decision outcome.
- [ ] `src/sim/crisis.gd` is extended
      with the three new fields
      (`autonomous_resolution`,
      `autonomous_resolution_days`,
      `deadline_consequence`).
- [ ] `src/sim/faction.gd` exists
      with the documented fields and
      methods (`id`, `display_name`,
      `stance`, `update_stance`,
      `is_hostile_to`).
- [ ] `src/sim/settings.gd` exists
      with the documented fields and
      static methods (`difficulty`,
      `auto_resolve_days`, `locale`,
      `from_dict`, `to_dict`).
- [ ] `src/sim/m4_skeleton.gd`
      re-exports the M4 carriers
      (`Faction`, `Settings`,
      `Crisis`) for the M4 closeout
      smoke test.
- [ ] `data/crises/plague_outbreak.tres`
      and
      `data/crises/faction_dispute.tres`
      exist with the documented
      fields.
- [ ] `tests/integration/test_m4_skeleton.gd`
      instantiates every skeleton
      and asserts the public surface
      (10+ asserts, no silent-pass).
- [ ] `tools/check_module_dependencies.sh`
      is green against the new
      `src/sim/` files.
- [ ] `./tools/run_quality.sh` is
      green at the end of the
      M4-foundation commit.

## Pros and cons of the options

### `autonomous_resolution: Callable` field on the `Crisis` data carrier, two M4 default crises, deadline mechanic pinned to `trigger_at_day + autonomous_resolution_days` with `resolved.deadline` sentinel

- Good, content-driven.
- Good, deadline is a signal.
- Good, deterministic-replay
  invariant preserved.
- Good, `Faction` is one map read.
- Good, `Settings` is load-bearing.
- Bad, deadline sentinel is
  load-bearing.
- Bad, `Callable` in a content
  file (the smallest possible
  exception; documented in this
  ADR).

### No `Callable`; the sim switch-cases on the crisis id

- Good, no `Callable` in a
  content file.
- Bad, §17 forbids executable
  code in content packs.
- Bad, an id-based switch is a
  per-crisis `if` in the sim.

### No deadline mechanic; the crisis resolves when the realm's state meets the autonomous condition

- Good, simpler.
- Bad, "two crises" with no
  deadline is not "two crises"
  (the player has no signal).
- Bad, the M4 acceptance is
  "autonomous conflict"; an
  unresolvable crisis is not
  autonomous.

### Deadline mechanic with `resolved.timeout` sentinel

- Good, `timeout` is a familiar
  term.
- Bad, `deadline` is the game's
  term; the sentinel should
  match the player's mental
  model.

### Two M4 default crises are `plague_outbreak` and `first_inspection`

- Good, one less new crisis
  to ship.
- Bad, the M2 crisis is
  already shipped; the M4
  acceptance is "two NEW
  crises".
- Bad, `first_inspection` is
  *player-driven*; the M4
  acceptance is "autonomous
  conflict".

## More information

- `docs/requirements.md` §6 (world,
  narrative, and tone), §11
  (conflict and crises), §12
  (difficulty and saving), §16
  (technical architecture), §17
  (code quality), §18 (testing
  and local quality gates), §23
  (M4 milestone DoD).
- ADR-0001 (record architecture
  decisions).
- ADR-0002 (module boundaries) —
  the `src/sim` boundary this
  ADR reinforces.
- ADR-0003 (save format) — the
  save body that stores the
  `Settings` carrier under
  `body.settings` and the
  `Faction` set under
  `body.factions`.
- ADR-0005 (sim-tick determinism) —
  the per-tick crisis-evaluation
  rule this ADR extends (the
  deadline check is a new branch
  in step 7).
- ADR-0008 (branching-event
  schema) — the
  `deadline_consequence`
  dictionary borrows the
  `BranchNode.terminal_effect`
  schema.
- ADR-0010 (research-tree and
  knowledge-state schema) — the
  M4 companion ADR for the
  research/ritual progression.
- `src/sim/sim.gd` — the sim
  façade this ADR extends
  (deadline check in step 7,
  planned for the M4 Track A
  commit).
- `src/sim/crisis.gd` — the M2
  `Crisis` data carrier this
  ADR extends.
- `src/sim/faction.gd`,
  `src/sim/settings.gd`,
  `src/sim/m4_skeleton.gd` (lands
  with this ADR; skeletons
  only).
- `data/crises/plague_outbreak.tres`,
  `data/crises/faction_dispute.tres`
  (lands with this ADR; M4
  default crises).
- `tests/integration/test_m4_skeleton.gd`
  (lands with this ADR;
  foundation smoke test).
- `tests/integration/test_autonomous_conflict.gd`
  (M4 Track A; the full
  autonomous-resolution and
  deadline test).
