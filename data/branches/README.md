# Branching events

The M3 cycle 2 (Track B) commit ships three branches:

  * `first_inspection_branch.tres` — root of the
    First-Inspection branch.
  * `accept_audit.tres` — terminal: accept the
    inspector's audit.
  * `counter_offer.tres` — terminal: counter-offer.

The data is a 1:1 mirror of the `BranchNode` fields.
The `.tres` files are not strictly required — the
test suite builds the branch tree in code; the files
are a content-team drop point.
