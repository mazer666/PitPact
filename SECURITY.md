# Security Policy

> Status: **M0 baseline**. The PitPact threat model is small because
> the game is offline-first and collects no data, but save files and
> imported content still need care. This document covers how to
> report, what we will do, and what is out of scope.

## Supported versions

PitPact is pre-release. Until the first public release ships (M6),
there is **no supported version** in the usual sense. Security work
during M0–M5 is welcome and handled in the open, on a best-effort
basis, by the maintainers.

Once the first public release ships, this section will list the
actively-supported versions and the support window for each.

## Threat model

In scope for security review during M0–M5:

- **Save-file safety.** PitPact saves are local. The format is
  versioned and migration-tested (§16.2). Imported saves and mods
  must validate strictly and fail safely; untrusted content must
  not execute arbitrary code (§19).
- **Dependency posture.** Minimal, pinned, license-reviewed, and
  documented (§19). Any new dependency is a PR that needs a
  security review and an ADR if it adds native code.
- **Distribution chain.** GitHub Releases and any future distribution
  channel must verify checksums and (when possible) signatures.
  macOS builds may be signed/notarized at the maintainers' discretion
  (§22).
- **Optional opt-in error reports.** Out of initial scope. When
  added, the report must be explicit, inspectable before sending,
  anonymised, and avoid personal paths/content by default (§19).

Out of scope:

- Account, login, telemetry, advertising, or online gameplay
  services — the spec excludes these for required gameplay (§19).
- Performance issues that are not security-relevant. Use the
  Performance issue template.
- General "crash" reports that are not security-relevant. Use the
  Bug report template.

## Reporting a vulnerability

**Do not file a public issue for suspected vulnerabilities that put
users at risk.** Public issues are indexed by search engines and
scrapers before maintainers can react.

Use GitHub's private vulnerability reporting:

1. Go to <https://github.com/mazer666/PitPact/security/policy>.
2. Click "Report a vulnerability".
3. Describe the issue, the impact, the reproduction steps, and
   (where helpful) a proof of concept. **Do not** include exploit
   payloads in the public template; private channels only.

If private disclosure is unavailable, contact the maintainers
through the channels listed on the project page. Expect an
acknowledgement within seven days.

We follow a coordinated disclosure model. Please give us a
reasonable window (typically 90 days) before public disclosure,
longer if a fix requires a coordinated release. We will not pursue
legal action against good-faith research that follows this policy.

## What we will do

1. Acknowledge the report within seven days.
2. Triage and confirm impact.
3. Develop a fix on a private branch.
4. Coordinate release timing with the reporter.
5. Credit the reporter in the release notes (unless anonymity is
   requested).
6. Mark the relevant issues / commits with a `security` label.

## Hardening commitments baked into the project

These are not aspirational; they are spec requirements that we
treat as load-bearing:

- No mandatory network connection for required gameplay.
- No analytics SDK, advertising SDK, or tracking pixel in any
  shipped binary.
- No personal data collection by default.
- Save files are local, exportable, and importable; the import path
  validates format and fails safely (§19).
- Dependencies are minimal, pinned, license-reviewed, and
  documented.
- Native code is gated by §16.1 and requires an ADR.

## See also

- `docs/requirements.md` §19 (security, privacy, and data handling).
- `CONTRIBUTING.md` (how to report other kinds of issues).
- `CODE_OF_CONDUCT.md` (community standards).
- `licenses/THIRD-PARTY.md` (dependency records).
