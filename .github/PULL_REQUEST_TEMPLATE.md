## Summary

<!--
One short paragraph: what does this PR do, and why?
Link the issue it closes (e.g. "Closes #42"). For substantial work
also link the design doc, ADR, or discussion thread.
-->

## What & Why

<!--
- Player-facing changes (visible behaviour, balance, content).
- Developer-facing changes (architecture, module boundaries, tests).
- Documentation changes (READMEs, style bible, ADRs, comments).
If any of these is "none", say so explicitly so reviewers know.
-->

## How it was tested

<!--
- Local command: `./tools/run_quality.sh` — pass/fail.
- New tests added.
- Manual playtest: seed, day reached, what you verified.
- Benchmark numbers, if performance-relevant.
- If you could not run the local suite, say why (sandbox, missing
  Godot binary, etc.) and what you ran instead.
-->

## Risk & Rollback

<!--
- What could break?
- Is this reversible? How?
- Does it touch the save format, locale schema, public APIs, or
  third-party licenses? If so, list the affected files and the
  migration story.
-->

## Checklist

<!--
Mark items with [x] when done. Leave unchecked items with a note
explaining the deferral.
-->

- [ ] `tools/run_quality.sh` runs clean locally.
- [ ] Tests added or updated (or "no tests needed — explain").
- [ ] Documentation updated in the same PR (module README, ADRs,
      style bible, CONTRIBUTING, AGENTS, etc., as applicable).
- [ ] Strings externalized into `locales/` (no hard-coded UI text).
- [ ] License posture checked: third-party material in
      `licenses/THIRD-PARTY.md`, AI-assisted material disclosed in
      the relevant manifest.
- [ ] No telemetry, analytics, network, or account code added.
- [ ] Changelog / release notes entry drafted in `CHANGELOG.md`
      if the change is user-visible.

## Screenshots / clips

<!--
Drag-and-drop images or paste a link to a screen recording.
PitPact is satirical by design; keep screenshots appropriate
for a public PR.
-->
