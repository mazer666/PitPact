# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — inhabitant data carrier (M2 Track A).
#
# `Inhabitant` is the per-inhabitant data carrier for
# the M2 simulation. The M2 Track A commit fills in
# the per-tick behaviour:
#
#   * `tick(delta_days, world, rng)` — the
#     per-tick update the sim calls in step 2
#     of `Sim.tick()` (ADR-0005). The function
#     decays the inhabitant's needs, derives
#     morale and stress from the new needs,
#     and prunes the event memory. It is a
#     pure function on the inhabitant's own
#     state; it does not write to the
#     `EventLog` (that is the sim's step-6
#     job, not the inhabitant's).
#
# The class also gains typed members for the
# four sub-carriers (morale, needs, memory) and
# the per-inhabitant `birth_day` field. The
# save/load pipeline (ADR-0003) round-trips
# these through the canonical body; the M2
# cycle 3 commit adds the `to_save_dict` and
# `from_save_dict` accessors the serializer
# will call.
#
# Per ADR-0002, this file does not import from
# `src/ui`, `src/realm`, or `src/save`. It imports
# from `src/core` and `src/sim/{needs,morale,
# event_memory,constants}.gd` only.
class_name Inhabitant
extends RefCounted

## Lifecycle enum (M2 Track A). The values are
## the canonical integers from the M0 baseline;
## the names are what the M2 code uses. The
## `int` is the authoritative representation;
## the enum is the readable alias. `ABSENT`
## covers both voluntary departure and
## involuntary disappearance (kidnapping,
## exploration, …) — the difference is captured
## in the event log, not in the enum.
const STATE_ALIVE: int = 0
const STATE_ABSENT: int = 1
const STATE_DECEASED: int = 2

## The inhabitant's stable identity. `StringName`
## so it survives the dictionary round-trip and
## so identity comparisons are O(1) hashed
## lookups. The id is assigned once at
## construction and never changes for the
## lifetime of the inhabitant.
var id: StringName = &""

## The inhabitant's culture id (a `StringName`
## reference to a `CultureData` instance under
## `data/cultures/`). The M0 template reserves
## the cultures directory; the M5 commit
## populates the six culture files. The id
## here is the `StringName` key into the
## content registry; the registry is owned by
## `src/content/` (M2 Track A dependency).
var culture: StringName = &""

## The inhabitant's display name, stored as a
## `StringName` that is a *locale key* (see
## `docs/localization.md` §"Naming"). The M2
## code does not resolve the key; the UI layer
## resolves it via `tr()` at draw time. The
## name is a `StringName` so it survives the
## dictionary round-trip and so identity
## comparisons are O(1) hashed lookups.
var name: StringName = &""

## The inhabitant's role in the realm. Default
## is `"settler"` per the M2 contract; other
## values (`"foreman"`, `"scout"`, `"scribe"`,
## …) are added by the M2 Track A and Track B
## commits. The role is a `StringName` keyed
## against a `RoleData` table in `data/roles/`
## (planned for M2 cycle 2).
var role: StringName = &"settler"

## The inhabitant's tile coordinates, per
## ADR-0004. `Vector2i` because the spatial
## state is integer (`src/world/coordinates.gd`).
## The M2 code treats this as the *authoritative*
## position; the pathing layer (M3+) animates
## between positions and the simulation only
## ever sees the `Vector2i` endpoints.
var position: Vector2i = Vector2i.ZERO

## The inhabitant's lifecycle state, as an
## `int` enum value. A non-zero value marks
## the inhabitant as out of the active tick
## loop: absent inhabitants do not work,
## deceased inhabitants do not decay, and
## the realm façade's view model (M5)
## renders them with the
## `INHABITANT_STATE_ABSENT` / `_DECEASED`
## localised label.
var state: int = STATE_ALIVE

## The in-game day the inhabitant was born
## (or, in M2 terms, the in-game day the
## inhabitant's contract with the realm
## started). The field is `0.0` by default;
## the realm façade's contract-stamping
## method sets it. A new inhabitant born
## at day `7.0` has `birth_day = 7.0`;
## the M5 inspector surfaces the field as
## the "age" badge.
var birth_day: float = 0.0

## The inhabitant's per-tick morale/stress
## value object. The Track A commit promotes
## the field from an untyped `Variant` to a
## typed `Morale`; the save/load pipeline
## (ADR-0003) round-trips it through
## `to_dict` / `from_dict`.
var morale: Morale = Morale.new()

## The inhabitant's per-tick need vector.
## Typed `Needs`; the save/load pipeline
## round-trips it through `to_dict` /
## `from_dict`.
var needs: Needs = Needs.new()

## The inhabitant's event memory. Typed
## `EventMemory`; the save/load pipeline
## round-trips it through `to_dict` /
## `from_dict`. The cap is the per-inhabitant
## `TUNING_EVENT_MEMORY_CAPACITY` constant
## in `src/sim/constants.gd`.
var memory: EventMemory = EventMemory.new()


## Default constructor. Assigns a fresh
## `StringName("")` id, the canonical
## `"settler"` role, the origin position, the
## `ALIVE` state, and the per-tick
## sub-carriers (`Morale`, `Needs`,
## `EventMemory`). The M2 Track A commit
## replaces this with a constructor that
## takes `(id, culture, name, role)` and
## asserts the arguments are non-empty.
func _init() -> void:
	id = &""
	culture = &""
	name = &""
	role = &"settler"
	position = Vector2i.ZERO
	state = STATE_ALIVE
	birth_day = 0.0
	morale = Morale.new()
	needs = Needs.new()
	memory = EventMemory.new()


## Construct an inhabitant with the canonical
## four identifying fields. The M2 Track A
## commit uses this constructor in the
## integration test; the M3+ content loader
## uses it from the JSON data.
func _init_id(
	p_id: StringName, p_culture: StringName, p_name: StringName, p_role: StringName
) -> void:
	id = p_id
	culture = p_culture
	name = p_name
	role = p_role
	position = Vector2i.ZERO
	state = STATE_ALIVE
	birth_day = 0.0
	morale = Morale.new()
	needs = Needs.new()
	memory = EventMemory.new()


## Apply the per-tick update to the inhabitant.
## The function is the M2 Track A per-tick body
## of step 2 in ADR-0005: needs decay, then
## morale/stress derivation, then memory prune.
##
## Parameters:
##   * `delta_days` — the in-game days the tick
##     advances (positive). The M2 contract pins
##     this as the *only* time the sim advances.
##   * `world` — the realm's `World` (currently
##     unused by the Track A body; the M3+ room
##     system feeds the `has_shelter` flag in
##     through this handle). Reserved for
##     forward compatibility.
##   * `rng` — the per-tick `SplitMix64` read-
##     only handle. The M2 Track A body does not
##     use randomness; the parameter is reserved
##     for the M3+ per-tick social decisions
##     (e.g. "should this inhabitant complain
##     this tick?"). Per ADR-0005, the sim
##     writes the RNG state; the inhabitants
##     read it.
##
## The function is a no-op for absent and
## deceased inhabitants: their needs are not
## decayed, their morale is not derived, and
## their memory is not pruned. The event log
## still records their existence (the
## sim's step 6 does that); the inhabitant
## itself is passive when not in the
## `ALIVE` state.
##
## Returns `void`. The function mutates the
## inhabitant in place; the sim's step 6
## reads the new state and appends the
## corresponding events to the `EventLog`.
func tick(delta_days: float, world, _rng) -> void:
	assert(delta_days > 0.0, "Inhabitant.tick: delta_days must be positive (got %f)" % delta_days)
	if state != STATE_ALIVE:
		# Absent and deceased inhabitants
		# are passive. The realm façade's
		# view model (M5) reads the
		# `state` field to render them
		# with the localised absent /
		# deceased label; the simulation
		# does not move their state.
		return
	# The world handle is the realm's
	# spatial state. M2 Track A does not
	# read it (we do not yet have a
	# "room the inhabitant occupies" query
	# in the sim's surface); M3+ will
	# feed `has_shelter` through this
	# handle. For now we pass `false`
	# (the unsheltered default) so the
	# safety need decays at the baseline
	# rate. The parameter is in the
	# signature so M3+ does not have to
	# change the call site.
	var has_shelter: bool = false
	if world != null and world.has_method("is_sheltered"):
		has_shelter = bool(world.call("is_sheltered", position))
	# Step 1 (ADR-0005 step 2): decay the
	# needs. The decay is the per-channel
	# `TUNING_NEED_DECAY_PER_DAY`; the
	# `safety` channel halves when
	# `has_shelter` is true.
	needs.decay(delta_days, has_shelter)
	# Step 2: derive morale and stress
	# from the *new* need values. The
	# `Morale.tick` function is the
	# implementation of §9.1 spec rules
	# R1, R2, R3.
	morale.tick(needs, delta_days)
	# Step 3: prune the event memory.
	# The 4x halflife threshold is the
	# M2 baseline; the prune is a
	# bound on the per-inhabitant
	# memory footprint. The current
	# day is read from the world's
	# `time_days` property when the
	# world handle provides one;
	# otherwise the prune is a no-op
	# (the memory retains all entries
	# until the cap evicts them).
	if world != null and "time_days" in world:
		memory.prune(float(world.get("time_days")))


## Apply the per-tick culture bias to the
## inhabitant's morale / stress. The
## function is the M2 Track A step-2
## content hook: the sim's `_advance_inhabitants`
## calls it after `Morale.tick` derives
## morale / stress from the needs.
##
## The M2 Track A implementation
## dispatches on the `culture` field:
##
##   * `&"lanternbearer"` -> applies the
##     Lanternbearer's per-tick bias.
##   * everything else   -> no-op.
##
## The M5 cultures pass adds the
## per-culture `apply_bias` calls for the
## remaining five cultures. The signature
## is pinned now so the sim's step 2 call
## site does not change between M2 and M5.
##
## Parameters:
##   * `delta_days` — the in-game days the
##     tick advances. The bias is scaled
##     by `delta_days` so a multi-day
##     tick applies the bias once per
##     in-game day (the bias is a
##     per-day value, not a per-tick
##     value).
##
## Returns `void`. The function mutates
## the inhabitant's `morale` in place.
func apply_culture_bias(delta_days: float) -> void:
	if culture == &"lanternbearer":
		LanternbearerCulture.apply_bias_static(morale, delta_days)


## Convenience: return a deep-copy `Dictionary`
## representation of the inhabitant, for
## save/load (ADR-0003) and for test asserts.
## The returned dictionary has the canonical
## keys `id`, `culture`, `name`, `role`,
## `position`, `state`, `birth_day`, `morale`,
## `needs`, `memory`; round-tripping through
## `from_dict` is the test contract.
func to_dict() -> Dictionary:
	return {
		"id": id,
		"culture": culture,
		"name": name,
		"role": role,
		"position": Vector2i(position),
		"state": state,
		"birth_day": birth_day,
		"morale": morale.to_dict(),
		"needs": needs.to_dict(),
		"memory": memory.to_dict(),
	}


## Convenience: restore the inhabitant from a
## `Dictionary` produced by `to_dict`. Unknown
## keys are ignored; missing keys leave the
## current value in place. Used by the M2
## save/load pipeline (Track C); the M2 cycle 3
## commit is the canonical caller.
func from_dict(d: Dictionary) -> void:
	if d == null:
		return
	if d.has("id"):
		id = StringName(d["id"])
	if d.has("culture"):
		culture = StringName(d["culture"])
	if d.has("name"):
		name = StringName(d["name"])
	if d.has("role"):
		role = StringName(d["role"])
	if d.has("position") and d["position"] is Vector2i:
		position = d["position"]
	if d.has("state"):
		state = int(d["state"])
	if d.has("birth_day"):
		birth_day = float(d["birth_day"])
	if d.has("morale") and d["morale"] is Dictionary:
		morale.from_dict(d["morale"])
	if d.has("needs") and d["needs"] is Dictionary:
		needs.from_dict(d["needs"])
	if d.has("memory") and d["memory"] is Dictionary:
		memory.from_dict(d["memory"])
