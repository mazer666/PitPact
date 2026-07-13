# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — Hearth: the first Room.
#
# The Hearth is the player-visible "camp fire" / "central
# hearth" room: a small constructed zone that gives the
# settlement a place to gather, eat, and warm up. It is
# the M1 demo's only room and the only room the player
# can paint in the M1 cycle.
#
# Per the M1 task spec:
#   * "The runtime reads this [data/rooms/hearth.tres];
#     do not hard-code values in src/realm/hearth.gd."
#   * "Implement the lifecycle: PLANNED → CONSTRUCTING →
#     ACTIVE → DECAYING → ABANDONED."
#
# The Hearth extends `Room`. The state machine and the
# tick logic are in `room.gd`; this file is the Hearth-
# specific factory and the data loader.
#
# Per ADR-0002, this file does not import from `src/ui`.
# It imports from `src/core`, `src/world`, `src/content`,
# and `src/audit`.
class_name Hearth
extends Room

## The path to the Hearth's data definition. The runtime
## loads this on demand; tests load it directly via
## `load(Hearth.DEFINITION_PATH)`.
const DEFINITION_PATH: String = "res://data/rooms/hearth.tres"


## Default constructor. Most callers should use
## `Hearth.create(zone)` instead; this constructor is
## kept for the save-loader path (where the definition is
## resolved from the saved `definition_id`).
func _init(p_definition: Resource = null) -> void:
	super._init(p_definition)


## Factory: build a Hearth from a zone. Loads the data
## definition, validates it, and creates a `Room` with
## state `PLANNED` and the zone's tiles. The M1
## `Hearth.create(z)` is the entry point the demo and
## the tests use.
##
## The data definition is loaded once per `create` call;
## in M2+ this becomes a content-registry lookup so the
## Hearth definition can be swapped by mods.
static func create(zone) -> Room:
	var def: Resource = load(DEFINITION_PATH)
	if def == null:
		push_error("Hearth.create: could not load definition at %s" % DEFINITION_PATH)
		return null
	# Validate the definition against the schema so a
	# corrupted `.tres` surfaces at room-construction
	# time, not silently at runtime.
	if def.has_method("validate"):
		var errs: PackedStringArray = def.call("validate")
		if errs.size() > 0:
			push_error("Hearth.create: invalid definition: %s" % str(Array(errs)))
			return null
	return Room.promote(zone, def)
