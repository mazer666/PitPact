# `licenses/` — License Texts and Provenance

> This directory holds the project's license texts, third-party
> license records, and asset provenance tables. It is the
> authoritative source for "what is this code, art, or asset
> licensed under?" See [`LICENSE`](../LICENSE) at the repo root
> for the split-license summary.

## Project licenses (default)

| What | License | File |
|------|---------|------|
| Original source code | GNU General Public License v3.0 or later (GPL-3.0-or-later) | [`GPL-3.0.txt`](GPL-3.0.txt) |
| Original art, audio, writing, and data | Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0) | [`CC-BY-SA-4.0.txt`](CC-BY-SA-4.0.txt), [`CC-BY-SA-4.0.md`](CC-BY-SA-4.0.md) |

These match the split defined in [`LICENSE`](../LICENSE) and
§20.1 of [`docs/requirements.md`](../docs/requirements.md). The
human-readable summary in `CC-BY-SA-4.0.md` records what the
license covers and what it does not, so a contributor does not
need to read the full legal text to apply it.

## Third-party material

See [`THIRD-PARTY.md`](THIRD-PARTY.md) for the running list of
every third-party code, data, asset, font, sound, or other
material integrated into PitPact, with the required
attribution, license, and version. Every entry is added in the
same commit that introduces the material; provenance travels
with the change.

The columns in the THIRD-PARTY table are:

- **Path** — path within this repository, or the addon name.
- **Component** — short description.
- **Upstream** — canonical source (URL or project name).
- **Version / commit** — pinned reference where possible.
- **License** — SPDX identifier.
- **Modifications** — what was changed locally, if anything.
- **Attribution** — required credit line, verbatim.

## License text archive

License texts of every third-party component are stored
alongside this file using their SPDX identifier as the
filename, e.g. `MIT.txt`, `Apache-2.0.txt`, `OFL-1.1.txt`. The
texts are fetched at integration time and verified against
upstream before they are relied on in a release.

## Asset manifest

The full asset inventory (path, author, license, source,
modifications, AI disclosure) lives in
[`assets/MANIFEST.md`](../assets/MANIFEST.md). Any discrepancy
between `assets/MANIFEST.md` and `THIRD-PARTY.md` is resolved
in favour of the manifest; the THIRD-PARTY table is updated
as a follow-up.

## Adding an entry

When a contributor adds any third-party material to the
repository, they MUST add an entry to the THIRD-PARTY table in
the same commit that introduces the material. The pull request
template's checklist enforces this.

## Review

Before any public release, the maintainers walk this file,
[`assets/MANIFEST.md`](../assets/MANIFEST.md), and the
[`docs/ip-license-checklist.md`](../docs/ip-license-checklist.md)
together to confirm the IP/license checklist in §20.3 of
[`docs/requirements.md`](../docs/requirements.md).

## See also

- [`LICENSE`](../LICENSE) at the repo root — the split-license
  notice.
- [`licenses/THIRD-PARTY.md`](THIRD-PARTY.md) — the running
  third-party table.
- [`assets/MANIFEST.md`](../assets/MANIFEST.md) — the asset
  inventory.
- [`docs/ip-license-checklist.md`](../docs/ip-license-checklist.md) —
  the pre-release review checklist.
- [`CONTRIBUTING.md`](../CONTRIBUTING.md) — how to record
  provenance when contributing.
