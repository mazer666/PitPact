# Narrative anchors

Fixed narrative hooks the M3 world generator emits. The
M3 cycle 2 (Track B) commit ships four anchors:

  * `first_morning.tres` — the first morning in the
    hollow.
  * `stowaway.tres` — a stowaway in the realm.
  * `first_pactmaker_visit.tres` — the first pactmaker
    visits.
  * `inspector_returns.tres` — the inspector returns.

The data is a 1:1 mirror of the `NarrativeAnchor`
fields. The `.tres` files are not strictly required —
the test suite builds the anchor set in code; the
files are a content-team drop point.
