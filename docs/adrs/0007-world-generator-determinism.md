---
status: accepted
date: 2026-07-14
deciders: project leads
consulted: contributors
informed: all contributors
---

# 7. World-generator determinism

## Context and problem statement

`docs/requirements.md` §7 requires a *constrained procedural
generator* for the M3 world map, and §8 requires that the
map contain at least two biomes and that the player's first
room — the **Hearth** — be placed on a tile that is reachable
from the map edge and that is "low-burden" (hostile tiles
should not be the spawn). §16 requires that "deterministic
game-domain logic" be reproducible from a seed, and that
"save formats must be versioned and migration-tested".

M3 is the milestone that delivers the world generator. M2
already shipped the simulation façade (ADR-0005), which
establishes the rule "the sim owns the per-tick RNG state;
every other module receives a read-only handle". M3 needs
the same kind of contract for the *generator*: without a
written contract, two implementers of the two parallel
tracks that follow this skeleton (Track A: biomes and
exploration; Track B: narrative anchors and branching
events) will make implicit choices about *what randomness
the generator may use*, *what state is a generator input*,
*and what the determinism invariant is*. The first
inconsistency will surface as a save/load round-trip that
produces a different map from the same seed, and the
inconsistency will be invisible in code review because the
two tracks will not have a shared test fixture.

We need a contract that:

1. pins the generator's *signature* — the function shape
   the realm façade and the save/load pipeline call,
2. pins the generator's *constraint set* — what the caller
   is allowed to require, and what the generator must
   satisfy,
3. pins the *determinism invariant* — the property the
   save/load round-trip and the replay tests check,
4. separates the generator's RNG state from the sim's RNG
   state, so inhabitants and crises do not accidentally
   consume the same stream the generator used,
5. is mechanically checkable from a test in
   `tests/world/test_generator_determinism.gd` (M3 cycle
   2, Track A), and is small enough that an M5 mod author
   can read it before writing a custom biome.

## Decision drivers

- **Determinism.** §7, §16. The generator is the
  load-bearing reproducibility primitive: every save file
  stores the seed (ADR-0003, `body.seed`), and the
  load path regenerates the world from that seed. A
  generator that is not a pure function on
  `(seed, constraints)` breaks the save/load invariant
  and breaks the M5 "replay a campaign from an event log"
  feature.
- **The "two biomes" acceptance criterion is structural,
  not cosmetic.** §8. The M3 acceptance is "the map
  contains at least two biomes". A generator that paints
  two biome *names* on the same underlying tile
  distribution does not satisfy §8; a generator that
  produces at least two *spatially distinct* biomes
  does. The constraint set must encode the distinction
  so the structural property is a hard guarantee, not a
  hopeful outcome of random placement.
- **The Hearth constraint is structural.** §8. The Hearth
  must be on a low-burden tile that is reachable from
  the map edge. A "low-burden" tile is content-defined
  (a marshlands tile with `burden <= 0.3` in the
  M3 default); "reachable from the map edge" is
  graph-theoretic (4-connected component that touches
  at least one edge tile). The generator must satisfy
  both; the failure mode "the Hearth is on an
  unreachable high-burden tile" must be impossible
  to reach by construction, not by hand-tuning.
- **Separation from the sim RNG.** ADR-0005 pins the
  rule "Sim owns the per-tick RNG state". If the
  generator and the sim share a stream, the M5
  replay feature cannot replay a campaign from a
  saved event log alone: the inhabitant decisions in
  tick N are a function of the generator's RNG
  draws in tick 0, and the event log does not record
  those draws. The generator must have its own RNG
  state, exhausted at construction time, and the
  sim's `_rng` must be re-seeded from the realm's
  recorded seed (not the generator's residual state)
  when the realm is materialised.
- **Mechanical checkability.** §18. The local quality
  suite runs GUT 9 headless. A determinism contract
  that can be exercised by a unit test ("generate
  twice with the same seed and the same constraints;
  assert deep-equal maps; assert two biomes; assert
  the Hearth is on a low-burden edge-reachable
  tile") is what makes the contract load-bearing.
  The test is the M3 cycle 2 (Track A) commit's
  responsibility; this ADR pins the contract the
  test asserts.

## Considered options

1. **Pure-function generator, `(seed, constraints) -> WorldMap`,
   with its own RNG state, constraint set, and structural
   acceptance checks; sim RNG is re-seeded from the realm
   seed at materialisation time** (this).
2. **Generator as a method on `WorldState` ("the world
   builds itself").** Rejected: it makes the generator
   mutable on the world it produces (the world has not
   been built yet; the method has no `this` to mutate),
   and it puts the RNG state on the wrong object. The
   sim already owns the per-tick RNG; the world should
   not own an RNG at all.
3. **Generator as a singleton / autoload.** Rejected:
   singletons are not testable per-call, they leak state
   across tests, and ADR-0002 already pins the rule "no
   autoloads for game-domain state". A free function
   (or a static method on `WorldGenerator`) is the
   right tool.
4. **Generator that takes only the seed; constraints
   are global and content-driven.** Rejected: §8 makes
   the Hearth constraint (low-burden, edge-reachable)
   and the two-biome constraint structural; structural
   constraints must be parameters of the generator,
   not defaults the caller has to override. A generator
   that hard-codes "marshlands is the spawn biome"
   would break the moment M5 ships a culture whose
   spawn biome is not marshlands.
5. **Generator that mutates the realm façade in place.**
   Rejected: the realm façade is the UI's view of the
   realm; the generator runs before the realm exists.
   The generator's output is a `WorldMap` data carrier
   (a pure data object) that the realm façade
   materialises by binding a `WorldState` and a `Sim`
   to it.

## Decision outcome

Chosen option: **Pure-function generator,
`(seed, constraints) -> WorldMap`, with its own RNG
state, constraint set, and structural acceptance checks;
sim RNG is re-seeded from the realm seed at materialisation
time.**

### The generator's contract

`WorldGenerator.generate(seed, width, height, constraints)
-> WorldMap` is a **pure function**. It:

- takes a 64-bit `seed`, a `width`, a `height`, and a
  `constraints` `Dictionary`,
- constructs **its own** `SplitMix64` instance from
  the seed (per ADR-0005's "RNG ownership" rule, the
  generator is the sole owner of the per-generation
  RNG state),
- produces a `WorldMap` data carrier whose contents
  satisfy the constraints (see "The constraint set"
  below),
- does not read the wall clock, does not call into
  the scene tree, does not touch the realm façade,
  does not talk to the sim, and does not read or
  write any global state.

Two calls to
`WorldGenerator.generate(s, w, h, c)` with the same
`s`, `w`, `h`, and `c` produce **deep-equal**
`WorldMap` values, on every platform, for every Godot
version, for every integer version of GDScript. This
is the **determinism invariant** the contract pins.

### The constraint set

The `constraints` argument is a `Dictionary` with the
following canonical keys. Every key is optional; a
missing key falls back to the documented default. The
generator must satisfy every constraint in the set;
if a constraint is unsatisfiable (e.g. the requested
Hearth position is unreachable from the requested map
edge), the generator raises a `GeneratorConstraintError`
and returns an empty `WorldMap`. The error path is part
of the contract: a generator that silently relaxes a
constraint has *not* honoured the contract.

| Key | Type | Default | Meaning |
|-----|------|---------|---------|
| `hearth_position` | `Vector2i` | `null` (the generator picks) | The tile coordinate the Hearth must be placed on. If `null`, the generator picks a low-burden, edge-reachable tile and exposes the pick as `WorldMap.hearth_position`. |
| `required_biome_ids` | `Array[StringName]` | `[]` (the generator decides) | The set of biome ids the generator must place at least one tile of. The M3 default is `[&"hollow", &"dustmaze"]` — the two biomes that satisfy the "at least two biomes" §8 acceptance criterion. The generator is allowed to add more. |
| `min_biome_count` | `int` | `2` | The minimum number of spatially distinct biomes the generated map must contain. The M3 default is `2`; an M5 content pass that requires three or more overrides this. |
| `hearth_burden_max` | `float` | `0.3` | The maximum `biome.burden` value the Hearth's tile is allowed to have. The M3 default is `0.3`; the M3 default candidate biomes (marshlands) are below this. |
| `random` | `int` | `0` | An additional per-generation entropy offset. The M3 default is `0`; the offset exists so the realm façade can spawn two realms from the same campaign seed in parallel (e.g. for an A/B test) without colliding. The seed is XORed with the offset *before* the generator's RNG is constructed; the offset is part of the contract's identity. |

The structural acceptance checks the generator must
satisfy are:

1. **Edge reachability.** The Hearth's tile is in
   the same 4-connected component as at least one
   map-edge tile. The map edge is the set of tiles
   with `x == 0`, `x == width - 1`, `y == 0`, or
   `y == height - 1`. (Diagonals do not connect;
   the rule mirrors ADR-0004's 4-connectivity rule
   for zones.)
2. **Low burden.** The Hearth's tile has
   `biome.burden <= constraints.hearth_burden_max`.
3. **Biome count.** The generated map contains at
   least `constraints.min_biome_count` spatially
   distinct biomes. "Spatially distinct" means
   "each biome occupies a connected region of at
   least one tile in the grid"; the generator's
   validation step walks the grid's per-tile
   biome and asserts the count.

The three checks are the *hard* contract. The
*soft* contract (which biomes, how many, where
the Hearth is) is the content's choice; the
content layer reads the constraints and the
`WorldMap` and decides how to satisfy them.

### The determinism invariant

> For any seed `s`, any `constraints` dictionary
> `c`, any `width` `w > 0`, and any `height`
> `h > 0`, two calls to
> `WorldGenerator.generate(s, w, h, c)` produce
> deep-equal `WorldMap` values.

"Deep-equal" means:

- the same tile data per `(x, y)` (same `id`,
  same `biome`, same `surface_meta`),
- the same biome assignment (every tile's biome
  matches),
- the same `hearth_position` (the generator's
  pick, if `constraints.hearth_position` was
  `null`; the input value, otherwise),
- the same narrative-anchor positions
  (the M3 cycle 2 commit pins the per-anchor
  placement rule),
- the same branch-node root set
  (the M3 cycle 2 Track B commit pins the per-
  branch generation rule).

The invariant is what
`tests/world/test_generator_determinism.gd`
(M3 cycle 2, Track A) will assert: two
`WorldGenerator.generate(...)` calls with the
same `(s, w, h, c)`, assert deep-equal maps, and
assert the three structural checks. A regression
in the RNG ownership rule (the generator reads
from the sim's RNG) or in the constraint set
(the generator silently relaxes a constraint)
will fail this test.

### The RNG ownership rule

The generator **owns** the per-generation RNG
state. The state is constructed at the top of
`generate()` and is *exhausted* by the end of
the function. The generator does not expose a
snapshot, a restore, a save_state, or a
load_state. The save/load pipeline (ADR-0003)
round-trips the generator by re-supplying the
seed, not by storing the generator's residual
state.

The sim's RNG state is **separate**. The sim's
`_rng` is re-seeded from the realm's recorded
seed (not from the generator's residual state)
when the realm is materialised. The
re-seeding is the realm façade's job (M3 cycle 2,
Track A); the generator does not know about the
sim.

The rule, in one sentence: **the generator
writes the generation RNG state; the sim writes
the per-tick RNG state; they never share a
stream.**

### What the generator does *not* own

The contract pins the *signature* and the
*constraint set*. It does not pin:

- the **biome set** the generator picks from
  (the M3 default is `[&"hollow", &"dustmaze"]`,
  but a future M5 content pass can add more).
- the **per-biome placement algorithm** (the
  M3 cycle 2 Track A commit picks the algorithm
  — cellular automata, Voronoi, random walk, …
  — and pins it in a sub-ADR if it is not
  obvious).
- the **narrative-anchor placement** (M3 cycle 2
  Track B).
- the **branch-node generation** (M3 cycle 2
  Track B).
- the **renderer's use of the map** (M3 cycle 3
  Track A: the renderer reads the `WorldMap` and
  projects; it does not look inside the
  generator).
- the **inhabitants' spawn** (the inhabitants
  arrive after the realm is materialised; they
  read the `WorldMap` and the realm's seed; they
  do not read the generator's residual state).

The generator's output is a *pure data carrier*.
The realm façade, the renderer, and the
inhabitants read the carrier; they do not
look inside the generator.

### Module-boundary impact

Per ADR-0002, `src/world` is forbidden from
importing `src/ui`, `src/sim`, `src/realm`,
`src/save`, or `src/audit`. This ADR reinforces
that rule for the M3 generator: the generator
does not call into the sim to fetch the time,
does not read from the save layer to reload
RNG state mid-generation, and does not
project anything onto the screen.

The generator imports from `src/core` (for
`SplitMix64`) and from `src/content` (for the
biome catalogue and the per-biome `burden`
field) only. The biome catalogue is a
`Dictionary[StringName, Biome]`; the M3 cycle 2
Track A commit owns the load order and the
validation rule.

### Mechanical enforcement

The determinism invariant is mechanically
enforced by a test in
`tests/world/test_generator_determinism.gd`
(M3 cycle 2, Track A). The test:

1. constructs two `WorldGenerator` instances
   (or calls the static `generate` method twice
   — the API the M3 cycle 2 commit pins),
2. calls `generate(s, w, h, c)` twice with the
   same `(s, w, h, c)`,
3. asserts deep-equal `WorldMap` values,
4. asserts the three structural checks
   (edge reachability, low burden, biome count).

A regression in the RNG ownership rule (the
generator reads from the sim's RNG), in the
constraint set (the generator silently relaxes
a constraint), or in the determinism invariant
(the generator reads the wall clock) will fail
this test.

The module-dependency check
(`tools/check_module_dependencies.sh`) enforces
the boundary mechanically today; the
determinism test is the companion mechanical
check for this ADR.

### Consequences

- Good, because the determinism story is one
  sentence long: "same seed + same constraints
  ⇒ same map". Every other determinism claim
  in the project (save format, replay,
  benchmark reproducibility, headless test) is
  a corollary of that sentence.
- Good, because the constraint set is small
  and visible. A new contributor can read the
  five canonical keys in a minute and know
  exactly what their content is allowed to
  require of the generator.
- Good, because the structural acceptance
  checks (edge reachability, low burden, biome
  count) are *hard* guarantees, not hopeful
  outcomes. A future "the Hearth is on an
  unreachable tile" bug is impossible to reach
  by construction.
- Good, because the RNG ownership rule mirrors
  ADR-0005's. The M5 replay feature can
  rebuild a campaign from a seed and an event
  log without ever reading the generator's
  residual state.
- Good, because the generator is a *pure
  function*; the test for the determinism
  invariant is a one-page test that calls
  `generate` twice and asserts deep-equal
  output.
- Bad, because "pure function" is a
  load-bearing constraint. A future subsystem
  that wants to be stateful (e.g. "the
  generator remembers the last map it
  produced") will have to push the state into
  the caller, not into the generator. That is
  the right trade-off for a single-timeline,
  single-seed game.
- Bad, because the structural acceptance
  checks can fail. A request for "Hearth on
  a marshlands tile" on a 4x4 map is not
  satisfiable; the generator raises
  `GeneratorConstraintError`. The error path
  is part of the contract, and a future
  caller that swallows the error has not
  honoured the contract.

### Confirmation criteria

This ADR is considered effective when:

- [ ] `docs/adrs/0007-world-generator-determinism.md`
      exists with this frontmatter and this
      decision outcome.
- [ ] `src/world/generator.gd` exposes
      `WorldGenerator.generate(seed, width, height,
      constraints) -> WorldMap` whose docstring
      names the determinism invariant and the
      five canonical constraint keys.
- [ ] `src/world/generator.gd` holds the
      per-generation RNG state in a private
      member; the public surface does not
      expose `snapshot` / `restore` /
      `save_state` / `load_state` on the
      generator itself.
- [ ] The generator's RNG state is exhausted at
      the end of `generate()`; the sim's RNG
      state is re-seeded from the realm's
      recorded seed at materialisation time.
- [ ] The skeleton classes in `src/world/`
      (`Biome`, `ExplorationMap`,
      `NarrativeAnchor`, `BranchNode`) declare
      their public surface exactly as
      documented in the M3 task spec, and the
      public surface is the only thing the
      M3 cycle 2 Tracks A and B commits are
      allowed to add to.
- [ ] `tools/check_module_dependencies.sh` is
      green against the new `src/world/` files.
- [ ] `./tools/run_quality.sh` is green at
      the end of the M3-foundation commit.

## Pros and cons of the options

### Pure-function generator, `(seed, constraints) -> WorldMap`, with its own RNG state, constraint set, and structural acceptance checks; sim RNG is re-seeded from the realm seed at materialisation time

- Good, determinism is a one-sentence
  property.
- Good, constraint set is small and visible.
- Good, structural checks are hard.
- Good, RNG ownership mirrors ADR-0005's.
- Good, the test is a one-page test.
- Bad, "pure function" is a load-bearing
  constraint.
- Bad, the structural checks can fail (the
  error path is part of the contract).

### Generator as a method on `WorldState`

- Good, "the world builds itself" reads
  naturally.
- Bad, no `this` to mutate (the world has
  not been built yet).
- Bad, puts the RNG on the wrong object.
- Bad, hard to test in isolation.

### Generator as a singleton / autoload

- Good, no instantiation ceremony.
- Bad, not testable per-call.
- Bad, leaks state across tests.
- Bad, ADR-0002 forbids autoloads for
  game-domain state.

### Generator that takes only the seed; constraints are global and content-driven

- Good, smaller signature.
- Bad, §8's Hearth constraint and
  two-biome constraint are structural.
- Bad, a generator that hard-codes
  "marshlands is the spawn biome" breaks
  the moment M5 ships a culture whose
  spawn biome is not marshlands.
- Bad, no way for a content pack to
  override the constraint set.

### Generator that mutates the realm façade in place

- Good, "one call to build a realm"
  reads naturally.
- Bad, the realm façade is the UI's view
  of the realm; the generator runs before
  the realm exists.
- Bad, mutates the very object the UI
  is going to read; couples the
  generator's contract to the realm
  façade's lifecycle.

## More information

- `docs/requirements.md` §7 (procedural
  generation), §8 (realm building and spatial
  simulation), §16 (technical architecture),
  §17 (code quality), §18 (testing and local
  quality gates).
- ADR-0001 (record architecture decisions).
- ADR-0002 (module boundaries) — the `src/world`
  boundary this ADR reinforces.
- ADR-0003 (save format) — the `body.seed` that
  re-supplies the seed at load time.
- ADR-0004 (spatial model) — the 4-connectivity
  rule the Hearth edge-reachability check uses.
- ADR-0005 (sim-tick determinism) — the
  "RNG ownership" rule this ADR mirrors for the
  generator.
- `src/world/generator.gd` (lands with this
  ADR; signature only, body is a no-op).
- `src/world/biome.gd`, `src/world/exploration.gd`,
  `src/world/narrative_anchor.gd`,
  `src/world/branch.gd` (land with this ADR;
  skeleton only).
- `src/core/rng.gd` — the `SplitMix64` RNG the
  generator owns.
- `tests/_smoke/test_world_skeleton.gd` (lands
  with this ADR; trivial skeleton test).
- `tests/world/test_generator_determinism.gd`
  (M3 cycle 2, Track A; the full determinism
  test).
