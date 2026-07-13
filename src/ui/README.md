# src/ui

Godot scenes, controllers, the input map, the camera.

## Purpose

`src/ui` is the presentation layer. It observes the realm
façade and projects it onto a screen. It owns no game state.

This is the **only** module that is allowed to import from
`src/realm` and `src/content` and to talk to the Godot scene
tree. It is also the only module the game-domain modules are
forbidden to import from — see ADR-0002 for the load-bearing
rule and the mechanical check.

## Responsibility

`src/ui`:

- hosts the Godot scenes that make up the player UI
  (main menu, realm view, room inspector, inhabitant list,
  event log, save/load dialogs),
- hosts the input map actions (§4.1 of the requirements
  spec: keyboard, mouse, trackpad, touch-aware),
- hosts the camera controller (fixed orientation, free
  zoom — see ADR-0004),
- hosts the localisation-driven label / tooltip
  controllers (§15 of the requirements spec),
- hosts the audio cue and ambient-music controllers
  (lands with the M5 audio pass).

`src/ui` does **not** own gameplay state, does **not**
simulate, and does **not** persist saves (the save dialog
delegates to `SaveService`).

## Public entry point

The main realm scene (`res://scenes/main/realm.tscn`, lands
with M1 cycle 2) plus the autoload controller documented
in this section. Until the real scene exists, the public
entry point is the `class_name RealmUiController` declared
in `ui.gd`.

## Main dependencies

- `src/realm` — for the player-facing API the UI binds to.
- `src/content` — for display data (room names, inhabitant
  names, item names) that is not part of the live realm
  state.
- `src/audit` — for rendering the event log.

## Must NOT depend on

- `src/core`, `src/world`, `src/sim`, `src/save` directly.
  The UI talks to the realm façade; the façade hides the
  lower layers. A UI feature that needs data the façade
  does not expose is a signal that the façade is missing a
  method, not a license to reach around it.
- (The reverse is the load-bearing rule: `src/core`,
  `src/world`, `src/sim`, `src/realm`, `src/content`,
  `src/save` MUST NOT import from `src/ui`.)

The mechanical check for both directions lives in
[`tools/check_module_dependencies.sh`](../../tools/check_module_dependencies.sh).

## Files

| File | Public class | Status |
|------|--------------|--------|
| [`ui.gd`](ui.gd) | `RealmUiController` (stub) | M1 stub |
| (lands with M1 cycle 2) | the real scene tree, the camera controller, the input map | planned |

## See also

- [`docs/adrs/0002-module-boundaries.md`](../adrs/0002-module-boundaries.md)
- [`docs/adrs/0004-spatial-model.md`](../adrs/0004-spatial-model.md)
- [`scenes/README.md`](../../scenes/README.md)
- [`docs/requirements.md`](../requirements.md) §4, §8, §13, §16, §17
