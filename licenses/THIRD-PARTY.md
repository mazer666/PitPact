# Third-Party Material

This file lists every piece of third-party code, data, asset, font,
sound, or other material that has been integrated into PitPact, along
with its license and attribution.

## How to add an entry

When you add any third-party material to the repository, you MUST add
an entry to the table below **in the same commit that introduces the
material**. Do not defer this to a later PR — provenance must travel
with the change.

Columns:
- **Path** — path within this repository, or the addon name.
- **Component** — short description.
- **Upstream** — canonical source (URL or project name).
- **Version / commit** — pinned reference where possible.
- **License** — SPDX identifier.
- **Modifications** — what was changed locally, if anything.
- **Attribution** — required credit line, verbatim.

## Entries

| Path | Component | Upstream | Version | License | Modifications | Attribution |
|------|-----------|----------|---------|---------|---------------|-------------|
| _none yet_ | — | — | — | — | — | — |

## License text archive

License texts of all third-party components are stored alongside this
file using their SPDX identifier as filename, e.g. `MIT.txt`,
`Apache-2.0.txt`, `OFL-1.1.txt`, etc. (texts fetched at the time of
integration; verify against upstream before relying on them in a
release).

## Review

Before any public release, the maintainers must walk this file and
`assets/MANIFEST.md` together to confirm the IP/license checklist in
§20.3 of the Requirements Specification.
