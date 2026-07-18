# ADR-0020 — M8: iPadOS & Mobile UI Preparation

- Status: Accepted
- Date: 2026-01
- Authors: PitPact contributors
- Phase: M8 (iPadOS & mobile UI)
- Supersedes: none
- Related: ADR-0018 (M6), ADR-0019 (M7), docs/roadmap.md

## Context

M7-Content-and-Balance (ADR-0019) lieferte
Content-Erweiterung + Balance-Pass + Mod-
Interface. M8 ist die **iPadOS-Vorbereitung**
und das **Mobile-UI-Refactoring**.

Per `docs/roadmap.md`:
> "Post-release work (balancing, additional
> content, mod/content interfaces, iPadOS
> preparation, eventual co-op) is out of
> scope for M0-M6 and tracked separately."

Diese ADR pinnt den M8-Scope *testbar*.
Drei Buckets sind in-scope (Touch Input,
Mobile UI, iOS-Export-Preset), drei sind
out-of-scope (echter iPad-Build, Co-op,
Mobile-Sound-Design).

## Decision

M8 wird in **drei orthogonalen Buckets**
geliefert. Jeder Bucket hat eine
Definition-of-Done mit *testbaren*
Kriterien (wie bei M0-M7).

### Bucket 1 — Touch Input

**Goal**: Das Spiel ist mit Touch-Events
bedienbar (Maus-Simulation wird durch
`InputEventScreenTouch` + `InputEventScreenDrag`
ergänzt).

**Definition-of-Done**:
- **`InputMap`** erweitert: `step`, `auto_tick`,
  `power_1`/`power_2`/`power_3`, `restart`
  Action-Mappings (default keyboard; touch
  wird via `InputEventScreenTouch` simuliert).
- **`_input(event)`** im `PlayableShellUI`:
  behandelt `InputEventScreenTouch` (tap =
  click) + `InputEventScreenDrag` (pan für
  Camera).
- **Touch-Tests**: headless-Tests die
  `Input.parse_input_event(InputEventScreenTouch)`
  aufrufen + Button-Pressed verifizieren.

### Bucket 2 — Mobile UI Reflow

**Goal**: Das Layout reagiert auf portrait/
landscape orientation + Bildschirm-
Verhältnis (4:3, 16:9, 9:16).

**Definition-of-Done**:
- **`scenes/main/PlayableShell.tscn`** mit
  ResponsiveLayout: TopBar + BottomBar
  bleiben fix, Inhabitant/Pactmaker Panels
  passen sich an Bildschirm-Breite an.
- **Touch-friendly Button-Größen**: minimum
  44x44px (per iOS HIG).
- **Landscape-Mode**: BottomBar wird zur
  SideBar (rechts).
- **Portrait-Mode**: BottomBar bleibt
  unten, Panels oben + unten gestapelt.
- Tests: `test_m8_responsive_*.gd` (5+
  Tests) die Window-Resize simulieren.

### Bucket 3 — iOS Export Preset

**Goal**: Das Spiel ist mit
`godot --export-release "iOS"` baubar
(mit den Godot-iOS-Templates).

**Definition-of-Done**:
- **`export_presets.cfg`** mit iOS-Preset
  (`iOS`, `Mobile`, `xcframework` output).
- **`tools/build/build_ios.sh`**: Build-
  Script das `godot --export-release "iOS"`
  aufruft.
- **iOS-Specific Notes** in
  `docs/ipados-deployment.md`: erklärt
  Code-Signing, Bundle-ID, App-Store-
  Submission.

## Out of scope (M8)

Per `docs/roadmap.md` und Apple-Constraints:

- **Echter iPad-Build** — out of scope
  (kein Apple-Hardware zum Testen, keine
  Code-Signing-Zertifikate).
- **Co-op / Multiplayer** — out of scope
  (kein Networking-Layer im M0-M7; M9+).
- **Mobile-Sound-Design** — out of scope
  (das M5-Closeout Bucket 6 audio ist
  PC-orientiert; mobile-Sound-Profiling
  erfordert echte Devices).
- **App-Store-Submission** — out of scope
  (erfordert Apple-Developer-Account;
  die M8 docs dokumentieren den Prozess
  aber führen ihn nicht aus).

## Consequences

### Positive

- M8 erweitert die Eingabe-Modalitäten
  (Touch + Tastatur + Maus).
- Mobile-UI-Reflow macht das Spiel
  auf kleinen Bildschirmen spielbar.
- iOS-Export-Preset ermöglicht Builds
  für Apple-Hardware (auch wenn wir
  sie nicht testen können).

### Negative / Tradeoffs

- Touch-Tests sind headless-only (kein
  echter Touch-Test).
- Mobile-UI-Reflow kann zu Layout-Shifts
  führen (per ADR-0002 §"stable layout").
- iOS-Export-Preset kann nicht getestet
  werden (kein Apple-Hardware).

## Validation (per Bucket)

- **Quality gate**: `tools/run_quality.sh` →
  ALL CHECKS PASSED ✓
- **GUT headless**: 273 + 15-25 neue Tests
  = 290+ Tests, 1750+ Asserts
- **Mutation sweep**: M8 mutations (5+ je
  Bucket)
- **Build**: `tools/build/build_ios.sh`
  exit 0 (wenn Apple-Templates
  installiert sind)

## Prio-Order

1. **Bucket 1 (Touch Input)** — high
   leverage (mobile-readiness).
2. **Bucket 2 (Mobile UI Reflow)** —
   high impact (Portrait/Landscape).
3. **Bucket 3 (iOS Export Preset)** —
   preparation (Builds).

## References

- ADR-0019 — M7-Content-and-Balance
- ADR-0018 — M6-Release-Readiness
- docs/roadmap.md (Post-release backlog)
- docs/requirements.md §1 (offline-first)
- Godot InputEventScreenTouch docs:
  https://docs.godotengine.org/en/stable/classes/class_inputeventscreentouch.html
- Apple iOS HIG: https://developer.apple.com/design/human-interface-guidelines/
