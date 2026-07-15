---
status: accepted
date: 2026-07-15
deciders: project leads
consulted: contributors
informed: all contributors
---

# 10. Research-tree and knowledge-state schema

## Context and problem statement

`docs/requirements.md` §10 (resources, knowledge, and
progression) requires the game to ship *research and
rituals* that "unlock powers, decrees, contracts, and
discoveries". §10 also says the economy must include
"knowledge/secrets/memories" as a first-class sink and
source. The M4 milestone definition of done (M4 row in
`docs/milestones.md` and §23 of the requirements) is
"Research/ritual progression, Pactmaker powers,
autonomous conflict, two crises, difficulty/settings."
M4 is the first milestone that ships progression.

The M2 commit on `main` already shipped the
deterministic sim-tick pipeline (ADR-0005). The M3
commit shipped the constrained world generator
(ADR-0007) and the branching-event schema (ADR-0008).
M4 extends the sim-tick pipeline with *knowledge
progression* — the player accumulates research and
ritual progress on a content-defined tree of
`ResearchNode`s, and the per-tick rule consumes the
progress in a deterministic, replayable way.

Without a written contract, two implementers of the M4
parallel tracks (Track A: research tree, ritual tree,
and the per-tick progression rule; Track B: Pactmaker
powers and intervention economy) will invent three
implicit choices:

1. **Where does the knowledge state live?** A
   per-realm carrier? A per-inhabitant carrier? A
   field on `Sim`? Each choice has different
   save-format and replay consequences; ADR-0003 pins
   `body.knowledge` as the canonical save-body slot
   for the knowledge state, but the in-memory shape
   has to be pinned by an M4 ADR.
2. **How is the research tree structured?** A
   flat list? A directed acyclic graph (DAG)? A
   layered graph with cross-layer edges? A tree that
   permits cycles? Each shape has different UI,
   determinism, and content-tooling consequences.
3. **When does research progress?** A
   per-tick rule that consumes a citizen's labour?
   A player-driven allocation? A combination? The
   choice has to be deterministic (ADR-0005) and
   must not require a `Callable` to be embedded in
   a content data file (the §17 code-quality rule
   forbids executable content).

We need a contract that:

1. pins the *payload schema* of a `ResearchNode` (a
   research node and a ritual node share the schema
   with one discriminator field),
2. pins the *carrier* — the in-memory shape of the
   knowledge state and the save-body slot the save
   format round-trips,
3. pins the *per-tick rule* that consumes research
   and ritual progress in the deterministic-tick
   pipeline,
4. pins the *structural invariant* "no two research
   nodes share a prerequisite tree" — i.e. the
   prerequisite relation is a *forest* of trees, never
   a DAG with a join, so the UI's "what unlocks this?"
   query is always a single root-to-leaf path and the
   `KnowledgeState.researched[id] -> int` lookup is
   one map read,
5. is mechanically checkable from a test in
   `tests/integration/test_m4_skeleton.gd` (the M4
   foundation smoke test) and from
   `tests/integration/test_research_tree.gd` (the M4
   Track A test), and
6. leaves room for the M5 content pass to add more
   nodes without changing the schema.

## Decision drivers

- **Determinism.** §16, ADR-0005. The sim-tick
  contract is "same seed + same input events ⇒
  same state at every tick". The M4 knowledge rule
  must extend this contract: two realms seeded with
  the same `(seed, research_input_events)` produce
  deep-equal `KnowledgeState` values at every tick.
  The per-tick rule must be a pure function on
  the carrier and the sim's RNG state.
- **Content-driven.** §10, §17, ADR-0008. A research
  node and a ritual node are *data*, not code.
  Content files under `data/research/*.tres` and
  `data/rituals/*.tres` define the tree; the
  simulator consumes the tree. A `Callable` in a
  content file is forbidden by §17.
- **Single source of truth for the carrier.** ADR-0003
  pins the save format. The save body has a
  `body.knowledge` slot (the M4 ADR pins the
  in-memory shape; the save format references it).
  The carrier is a *per-realm* value (not
  per-inhabitant and not per-room): research is a
  property of the realm, not of any individual, and
  the M5 meta-progression is a separate carrier
  that does not need to interleave with the realm
  state.
- **One prereq-tree per node.** A research node is
  the *root* of a unique prerequisite tree. The
  invariant "no two research nodes share a
  prerequisite tree" is what makes the
  `KnowledgeState.is_researched(id)` lookup
  trivially correct (the answer is the carrier's
  `researched[id]`, full stop) and what makes the
  "what unlocks this?" UI a single root-to-leaf
  walk. A DAG with a join would force the
  `is_researched` rule to walk a closure, which
  breaks the one-map-read contract and the
  determinism-friendly default of "research
  progress is a per-node accumulator".
- **Forest, not list.** The forest shape is
  minimal: every node is a root or has exactly one
  parent, and no two roots have the same
  prerequisite tree. A flat list would force the
  per-tick rule to compute a "what unlocks what"
  closure every tick; a layered graph with
  cross-layer edges would require a topological
  sort at load time; both are heavier than the
  forest and offer no extra expressive power for
  the M4 acceptance.
- **Mechanical checkability.** §18. A schema that
  can be exercised by a unit test ("load the M4
  research tree, assert every node's `prerequisites`
  is an Array of `StringName` ids that exist in
  the tree, assert the prereq-closure is a forest
  with no two roots sharing a closure, assert the
  save body round-trips through `KnowledgeState.
  save/load`") is what makes the contract
  load-bearing. The M4 foundation smoke test
  exercises the carrier; the M4 Track A test
  exercises the full tree.

## Considered options

1. **Forest-of-roots tree, `ResearchNode` payload
   schema with a `kind` discriminator, per-realm
   `KnowledgeState` carrier pinned to
   `body.knowledge`, deterministic per-tick rule
   that consumes research and ritual progress**
   (this). The invariant "no two research nodes
   share a prerequisite tree" is a load-time
   validation rule on the tree's content catalogue.
2. **DAG with joins, per-realm `KnowledgeState`
   carrier.** Rejected: a DAG with joins makes
   `is_researched` a closure walk, breaks the
   "one-map-read" contract, and forces the per-tick
   rule to compute a "what is the new unlock set?"
   closure on every tick. The forest shape is
   strictly less work for strictly more clarity.
3. **Per-inhabitant knowledge carrier.** Rejected:
   research is a property of the realm (the
   player's collective knowledge), not of any
   individual. A per-inhabitant carrier would
   force "share knowledge" mechanics that the M4
   acceptance does not require and that the M5
   content pass can add as an *additive* layer
   without breaking the M4 carrier.
4. **Per-room knowledge carrier.** Rejected: the
   M4 acceptance is "the realm has progressed in
   research X", not "room Y has a research bench".
   A per-room carrier would force "what room is
   the research in?" lookup at every per-tick
   call, which is heavier than the per-realm
   carrier and is not justified by the M4
   surface area.
5. **No per-tick rule — research is a player-driven
   click-to-complete action.** Rejected: the
   per-tick rule is what makes the carrier
   *progression* rather than a
   click-to-unlock UI. A click-to-unlock mechanic
   would be a UI shortcut, not a sim rule, and
   would force the M5 replay feature to record
   the click as an event rather than read the
   carrier's state. The per-tick rule is the
   source of truth; the click is a UI affordance
   that fills the carrier.

## Decision outcome

Chosen option: **Forest-of-roots tree,
`ResearchNode` payload schema with a `kind`
discriminator, per-realm `KnowledgeState`
carrier pinned to `body.knowledge`,
deterministic per-tick rule that consumes
research and ritual progress.**

### The `ResearchNode` payload schema

A research node and a ritual node share the same
schema; the `kind` field is the discriminator.

| Field | Type | Meaning |
|-------|------|---------|
| `id` | `StringName` | The node's stable identity. The id is the dictionary key in the content catalogue and the lookup key in `KnowledgeState.researched`. |
| `kind` | `StringName` | Either `&"research"` (a research node) or `&"ritual"` (a ritual node). The discriminator; it is the only field whose allowed values are constrained. |
| `display_name` | `StringName` | A locale key. The UI's "this node is called …" panel reads the key. The `display_name` is never rendered in code. |
| `summary` | `StringName` | A locale key. The UI's "what does this node do?" tooltip reads the key. |
| `cost` | `Dictionary` | The cost of completing the node. The M4 default keys are `knowledge_points: int` and `time_days: float`; a ritual node also accepts `mana: float` (content-defined). The cost is a content value; the carrier does not enforce it (the per-tick rule consumes the cost and emits a `research.completed` or `ritual.completed` event when the cost is met). |
| `prerequisites` | `Array[StringName]` | The ids of the nodes that must be `is_researched(id) == true` before this node can be progressed. The M4 default is an empty array (a root node); the forest invariant forces the prereq closure to be a single tree. |
| `unlocks` | `Array[StringName]` | The ids of the nodes that *this* node unlocks. The `unlocks` field is the *advisory* inverse of `prerequisites`; the load-time validator cross-checks the two (a node in `unlocks` is a node whose `prerequisites` contains this id). The field is advisory so content authors do not have to keep the two in sync by hand. |
| `effect` | `Dictionary` | The effect applied to the realm when the node completes. The M4 default keys are `pactmaker_power_id: StringName` (unlocks a Pactmaker power), `decree_unlock: StringName` (unlocks a decree), `room_unlock: StringName` (unlocks a room type). A ritual node may also carry `crisis_summon_id: StringName` (a crisis the realm can deliberately trigger by completing this ritual). The effect is a content value; the carrier does not enforce it (the per-tick rule emits an event when the effect fires). |

The schema is a `Dictionary[StringName, Variant]`
in the content `.tres` and a `ResearchNode`
typed carrier in code. The carrier's
`from_content(...)` static method converts the
content `Dictionary` into a typed `ResearchNode`
so the rest of the sim can read the typed
fields.

### The `KnowledgeState` carrier

`KnowledgeState` is a per-realm
`RefCounted`. The realm façade holds one
instance; the per-tick rule reads and writes
its fields. The carrier is **deterministic**:
two carriers constructed with the same
`save()` output are deep-equal.

| Field | Type | Meaning |
|-------|------|---------|
| `researched` | `Dictionary[StringName, int]` | The completion count of every research node. The key is the node's `id`; the value is the number of *times* the node has been completed (the M4 default is `0` or `1`; an M5 content pass can use `> 1` for repeatable nodes like "increase the realm's food yield by 5%"). A non-zero value means the node is "researched" (`is_researched(id)` returns `true`). |
| `active_rituals` | `Array` | The list of *currently active* rituals. An active ritual is a `Dictionary` with the keys `id: StringName`, `node_id: StringName` (the ritual's research-node id), `started_at_day: float`, `duration_days: float`, and `progress_days: float`. The carrier does not own the time math (the per-tick rule does), but it owns the data the rule reads and writes. |
| `pending_effects` | `Array` | A queue of `effect` payloads the per-tick rule has emitted but the realm façade has not yet consumed. The carrier's `consume_pending_effects() -> Array` returns the queue and resets it to `[]`. |

The carrier exposes:

- `is_researched(id: StringName) -> bool` —
  returns `true` if `researched[id] > 0`.
- `is_ritual_active(id: StringName) -> bool` —
  returns `true` if any entry in
  `active_rituals` has `node_id == id`.
- `save() -> Dictionary` — returns a
  `Dictionary` with the keys `version: int`
  (the M4 default is `1`), `researched:
  Dictionary[StringName, int]`,
  `active_rituals: Array`, and
  `pending_effects: Array`. The `version`
  field is the migration hook; ADR-0003's
  migration registry will use it.
- `load(d: Dictionary) -> bool` — restores
  the carrier from a save body. Returns
  `true` on success, `false` on a
  version mismatch (the caller is the
  migration registry, which falls back to
  the previous version's migration step).
- `from_dict(d: Dictionary) -> KnowledgeState`
  — static factory; the canonical way to
  construct a carrier from a save body.
- `consume_pending_effects() -> Array` —
  the realm façade's "what happened this
  tick?" poll.

### The save-body slot

ADR-0003 pins the save body. The M4 carrier's
`save()` output lives at `body.knowledge`. The
save body is the single source of truth for the
M5 replay feature; the M4 foundation commit
reserves the slot and the M4 Track A commit
fills it in.

### The per-tick rule

The sim's `tick()` body (ADR-0005, step 7
*Crisis evaluation* in `src/sim/sim.gd`) gains
a new step **7c — Research/ritual progression**.
The step is a thin wrapper over
`KnowledgeState.advance(time_days, delta_days,
input)`. The wrapper is a no-op when the
carrier is `null` (the M2 contract is preserved:
a sim that has never had a `KnowledgeState`
registered continues to behave exactly as the
M2 tests expect).

The order of operations inside the new step
is fixed and is exactly the following
sequence. Each step is a pure function on
the carrier, the sim's RNG state, and the
`input` argument (a `Dictionary` of
`research_input_events` the player produced
this tick — the M4 default is `{"start_node":
[node_id], "boost_node": [(node_id, points)]}`):

1. **Apply input.** For each `(node_id,
   points)` in `input.boost_node`, increment
   `carrier.researched[node_id]` by `points`.
   For each `node_id` in `input.start_node`,
   append a new `active_rituals` entry (the
   `started_at_day` is the post-tick clock;
   the `duration_days` is the ritual node's
   `cost.time_days`; the `progress_days` is
   `0.0`).
2. **Tick active rituals.** For each entry
   in `active_rituals`, increment
   `progress_days` by `delta_days`. A ritual
   whose `progress_days >= duration_days`
   is *completed* in the same tick: the
   entry is removed, the ritual node's
   `effect` is appended to
   `pending_effects`, and the
   `researched[node_id]` counter is
   incremented by 1.
3. **Tick research progress.** For each
   research node whose `is_researched` is
   `false` and whose `prerequisites` are all
   `is_researched == true`, the rule
   consumes the node's `cost.knowledge_points`
   against the realm's accumulated knowledge
   budget. The budget is a carrier-level
   accumulator (the M4 default is 1 point
   per tick per active inhabitant, content
   tunable). A node whose
   `cost.knowledge_points` is met is
   completed in the same tick (same path as
   the ritual step).
4. **Append effects.** The
   `pending_effects` queue is the per-tick
   output. The realm façade's
   `consume_pending_effects()` call at the
   end of the tick drains the queue; the
   per-effect side effects (Pactmaker power
   unlock, decree unlock, room unlock,
   crisis-summon) are applied by the
   *consumer* (the realm façade for powers
   and decrees; the sim's per-tick step 7
   for crisis-summon).

The per-tick step is *deterministic*: same
seed + same `input` ⇒ same
`KnowledgeState` and same `pending_effects`
at every tick. The invariant is the
companion mechanical check for this ADR.

### The structural invariant

> The research tree is a **forest**: every
> node is a root or has exactly one parent,
> and no two roots share a prerequisite
> closure.

"Enough-but-not-too-much" definition:

- Every node's `prerequisites` array is
  either empty (a root) or a non-empty
  array of ids whose corresponding nodes
  are *not* this node (no self-cycle) and
  whose corresponding nodes are all
  members of the same tree (a join would
  put two nodes in the same closure).
- The load-time validator walks the tree
  and asserts the forest invariant for
  every node. A violation is a content
  error; the validator raises
  `ResearchTreeError` and the catalogue
  loader refuses to load the tree.

The forest shape is what makes
`is_researched(id)` a one-map-read: the
answer is `carrier.researched[id] > 0`, full
stop. The forest shape is also what makes
the "what unlocks this?" UI a single
root-to-leaf walk: the answer is the
chain `(root, ..., node)`, with no
branching.

### The deterministic-replay invariant

> For any seed `s`, any
> `research_input_events` sequence
> `R = [r_0, r_1, …, r_n]`, and any
> per-tick `delta_days`, two realms
> with the same seed and the same
> `KnowledgeState` ticked through the
> same `R` and `delta_days` produce
> deep-equal `KnowledgeState` values
> and deep-equal
> `pending_effects` queues at every
> tick.

The invariant is what
`tests/integration/test_research_tree.
gd` (M4 Track A) will assert: two realms
seeded with the same seed and ticked
through the same input events with the
same `delta_days` produce deep-equal
`KnowledgeState` and `pending_effects` at
every tick. A regression in the per-tick
rule or in the forest invariant will fail
that test.

### What the schema does *not* pin

The contract pins the *payload schema*,
the *carrier*, the *save-body slot*, the
*per-tick rule*, and the *structural
invariant*. It does not pin:

- the **cost shape**. The M4 default is
  `knowledge_points: int` and
  `time_days: float`; an M5 content
  pass can add more cost keys (e.g.
  `mana: float` for ritual nodes, a
  `cult_unlock_id: StringName` for
  culture-gated research). The
  validator accepts any non-empty
  `Dictionary` whose keys are
  `StringName`.
- the **effect shape**. The M4 default
  is `pactmaker_power_id`, `decree_unlock`,
  `room_unlock`, and (for rituals)
  `crisis_summon_id`. An M5 content
  pass can add more effect keys.
- the **per-tick knowledge budget**.
  The M4 default is "1 point per
  active inhabitant per tick";
  content-tunable per the §17
  data-driven rule. The budget lives
  in the content catalogue; the
  carrier does not own it.
- the **research/ritual UI**. The UI
  reads the carrier and the catalogue
  and projects; it does not look
  inside the per-tick rule.

### Module-boundary impact

Per ADR-0002, `src/sim` is forbidden from
importing `src/ui`, `src/realm`, or
`src/save`. This ADR reinforces that rule
for the M4 carrier: the carrier does not
call into the realm façade to fetch the
time, does not read from the save layer to
reload knowledge state mid-tick, and does
not project anything onto the screen. The
realm façade is the *consumer* of
`pending_effects`; the sim owns the
producer side.

The M4 carrier imports from `src/core` (for
the canonical `StringName` helpers) and
from `src/content` (for the research
catalogue loader, planned for the M4
Track A commit). The skeleton commits in
this PR declare the dependency but do
not actually preload it yet.

### Mechanical enforcement

The research-tree schema is mechanically
enforced by a test in
`tests/integration/test_m4_skeleton.gd`
(M4 foundation, this commit) and a fuller
test in
`tests/integration/test_research_tree.gd`
(M4 Track A). The foundation test asserts:

- `KnowledgeState.save()` produces a
  `Dictionary` with the canonical keys
  (`version`, `researched`,
  `active_rituals`, `pending_effects`).
- `KnowledgeState.from_dict(d)` round-trips
  the save body (deep-equal on
  `researched` and `active_rituals`).
- `is_researched` and `is_ritual_active`
  return `false` on a fresh carrier and
  `true` after the relevant field is set.
- `ResearchNode.from_content(d)` produces
  a `ResearchNode` whose fields match
  the input `d`.

The M4 Track A test asserts the forest
invariant: a tree with two roots whose
prerequisite closures overlap is rejected
by the validator; a tree whose
`prerequisites` is empty on a non-root
node is rejected; a tree whose
`prerequisites` references a non-existent
id is rejected.

A regression in the carrier's
`save`/`from_dict` round-trip, in the
`is_researched`/`is_ritual_active`
predicates, in the `ResearchNode` payload,
or in the forest invariant will fail the
test.

The module-dependency check
(`tools/check_module_dependencies.sh`)
enforces the boundary mechanically today;
the foundation smoke test is the companion
mechanical check for this ADR.

### Consequences

- Good, because the schema is
  *content-driven*. A research node and
  a ritual node are `.tres` files under
  `data/`; no GDScript is required to
  express them.
- Good, because the carrier is *one
  map read*. `is_researched(id)` is a
  constant-time lookup; the per-tick
  rule is O(n) in the number of
  research nodes whose prereqs are
  met, which is small.
- Good, because the forest shape is
  *determinism-friendly*. A DAG with
  joins would force a closure walk on
  every tick; a forest is a
  root-to-leaf chain, which is the
  cheapest data structure the
  determinism contract can read.
- Good, because the save body is
  *pinned*. `body.knowledge` is the
  single source of truth for the M5
  replay feature; the M4 foundation
  commit reserves the slot.
- Good, because the per-tick rule is
  *pure*. Same input, same output,
  no observable side effects on the
  sim's RNG state.
- Bad, because the forest shape is
  *load-bearing*. A future content
  author who reads the schema and
  reaches for "let me have a node
  with two parents" will be confused
  by the validator's refusal. The
  rule is documented here; the
  validator is the safety net.
- Bad, because the M4 carrier
  *extends* the per-tick pipeline
  with a new step. The new step
  changes the sim's `tick()` body
  (a new step 7c, after step 7b
  *narrative anchors*). The change
  is additive — the existing
  eight steps are unchanged — but
  the sim's `tick()` docstring must
  be updated. The M4 foundation
  commit reserves the slot; the M4
  Track A commit fills the body.

### Confirmation criteria

This ADR is considered effective when:

- [ ] `docs/adrs/0010-research-tree-schema.md`
      exists with this frontmatter and this
      decision outcome.
- [ ] `src/sim/knowledge_state.gd` exposes
      `KnowledgeState` with the documented
      fields (`researched`, `active_rituals`,
      `pending_effects`), the documented
      methods (`is_researched`,
      `is_ritual_active`, `save`, `load`,
      `from_dict`, `consume_pending_effects`).
- [ ] `src/sim/research_node.gd` exposes
      `ResearchNode` with the documented
      fields (`id`, `kind`, `display_name`,
      `summary`, `cost`, `prerequisites`,
      `unlocks`, `effect`) and a
      `from_content(...)` static factory.
- [ ] `src/sim/m4_skeleton.gd` re-exports
      the M4 carriers (KnowledgeState,
      ResearchNode) for the M4 closeout
      smoke test.
- [ ] `tests/integration/test_m4_skeleton.gd`
      instantiates every skeleton and
      asserts the public surface (10+
      asserts, no silent-pass).
- [ ] `tools/check_module_dependencies.sh`
      is green against the new `src/sim/`
      files.
- [ ] `./tools/run_quality.sh` is green at
      the end of the M4-foundation commit.

## Pros and cons of the options

### Forest-of-roots tree, `ResearchNode` payload schema with a `kind` discriminator, per-realm `KnowledgeState` carrier pinned to `body.knowledge`, deterministic per-tick rule

- Good, content-driven.
- Good, one map read.
- Good, determinism-friendly.
- Good, save body pinned.
- Good, pure per-tick rule.
- Bad, forest shape is load-bearing.
- Bad, the M4 carrier extends the
  per-tick pipeline with a new step.

### DAG with joins, per-realm `KnowledgeState` carrier

- Good, more expressive.
- Bad, `is_researched` is a closure walk.
- Bad, breaks the "one-map-read" contract.
- Bad, per-tick rule is heavier.
- Bad, no M4 acceptance criterion that
  needs joins.

### Per-inhabitant knowledge carrier

- Good, "the inhabitant knows things" is
  a natural story.
- Bad, research is a property of the realm.
- Bad, per-inhabitant carrier forces
  "share knowledge" mechanics the M4
  acceptance does not require.

### Per-room knowledge carrier

- Good, "the room has a research bench" is
  a natural story.
- Bad, M4 acceptance is realm-level.
- Bad, per-room carrier forces
  "what room is the research in?" lookup.

### No per-tick rule — research is player-driven click-to-complete

- Good, simplest.
- Bad, breaks determinism (the player
  click is an event, not a state).
- Bad, the M5 replay feature would have
  to record the click, not read the
  carrier.

## More information

- `docs/requirements.md` §10 (resources,
  knowledge, and progression), §11
  (conflict and crises), §16 (technical
  architecture), §17 (code quality),
  §18 (testing and local quality gates),
  §23 (M4 milestone DoD).
- ADR-0001 (record architecture decisions).
- ADR-0002 (module boundaries) — the
  `src/sim` boundary this ADR reinforces.
- ADR-0003 (save format) — the
  `body.knowledge` slot this ADR pins.
- ADR-0005 (sim-tick determinism) — the
  per-tick rule this ADR extends (new
  step 7c *Research/ritual progression*).
- ADR-0008 (branching-event schema) — the
  `crisis_summon_id` effect key on
  ritual nodes borrows the M3
  follow-up pattern.
- `src/sim/sim.gd` — the sim façade this
  ADR extends (step 7c, planned for the
  M4 Track A commit).
- `src/sim/knowledge_state.gd`,
  `src/sim/research_node.gd`,
  `src/sim/m4_skeleton.gd` (lands with
  this ADR; skeletons only).
- `data/research/*.tres`,
  `data/rituals/*.tres` (lands with the
  M4 Track A commit; content-driven
  tree).
- `tests/integration/test_m4_skeleton.gd`
  (lands with this ADR; foundation
  smoke test).
- `tests/integration/test_research_tree.gd`
  (M4 Track A; the full forest
  invariant test).
