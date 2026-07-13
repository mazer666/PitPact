# Pact & Pit Requirements Specification

**Working title:** *Pact & Pit — An Underworld of Terms and Terrors*  
**Document status:** Project-start baseline  
**Language:** English  
**Audience:** Maintainers, contributors, artists, writers, testers, and AI-assisted development agents.

## 1. Purpose and product vision

*Pact & Pit* is an original, open-source, single-player 2.5D management and simulation game. The player is a mysterious Pactmaker: a selectable, disembodied entity that builds an underground realm through bargains, decrees, limited supernatural interventions, and priorities rather than direct unit control.

The player plans and develops a subterranean realm, enters individual contracts with unusual inhabitants, manages production and knowledge, explores unknown depths, and survives meaningful crises. Inhabitants have needs, values, memories, professions, relationships, and the capacity to die. The game combines dark, colourful Weird/Gothic Fantasy with dry bureaucratic satire about authority, dogma, extractive economies, empires, and administration.

The game must be its own work. It may use broad genre concepts such as a fantasy underground settlement or creature simulation, but it must not reproduce protected expression, terminology, characters, lore, maps, room layouts, creature designs, UI patterns, music, writing, or assets from any existing game.

## 2. Product principles

1. **Indirect authority, not click-commanding.** The player sets conditions and priorities; inhabitants make most decisions.
2. **Consequences remain legible.** The player must be able to learn why events happened through inspection, logs, and overlays.
3. **Failure teaches at a price.** A failed campaign has meaningful losses but unlocks understanding or future options.
4. **Simulation supports story.** Systems create situations; authored narrative anchors give them shape.
5. **Complexity is optional.** The default interface is approachable; detailed rule and diagnostic views are available when wanted.
6. **Privacy and ownership first.** The game is offline-first, account-free, telemetry-free, and user data remains under player control.
7. **Open development is a quality feature.** Code, data, decisions, and licenses must be clear enough for newcomers to inspect and improve.

## 3. Scope and release structure

### 3.1 First public playable release: Vertical Campaign Slice

The first public release shall be a short, complete, procedurally generated campaign, not an unbounded prototype. It shall contain:

| Content | Required baseline |
|---|---:|
| Biomes | 2 |
| Creature cultures | 6 |
| Room types | 10 |
| Authored event templates | 15 |
| Major crises | 2 |
| Procedural dungeon | At least one valid dungeon per campaign |
| Campaign outcome | A success, failure, and restart/progression loop |

It must demonstrate validated procedural generation; zoning and organic room change; individual creature contracts and needs; research/ritual decisions; one autonomous conflict resolved through creature behaviour plus limited Pactmaker influence; and one branching event with a long-term consequence.

### 3.2 Explicitly deferred scope

The following are not required for the first public release: co-op, competitive multiplayer, smartphones, a public mod marketplace, a full map editor, a large multi-biome campaign, full voice acting, or external account/cloud functionality. Architecture must avoid making later co-op or iPadOS support impossible, but neither may delay the desktop single-player release.

## 4. Target platforms and performance

- **Release priority:** macOS, Windows, and Linux desktop.
- **Primary development/reference device:** MacBook Air with Apple M5.
- **Later target:** iPadOS, after the desktop release.
- **Not a target:** smartphones.
- **Input from day one:** keyboard, mouse, trackpad, and touch-aware UI interactions. Controller support is out of initial scope.
- Normal-sized realms on the reference MacBook Air M5 must feel smooth at a 60 FPS target.
- Lower-end systems must have sensible performance limits and adjustable visual quality.
- Large transitions may use clear, brief loading screens; the game must not silently freeze or stutter for long periods.
- Simulation, map, and creature performance must be benchmarked locally.
- The game must run without an active Internet connection or externally hosted runtime service.

## 5. Player identity and campaign loop

The player selects a Pactmaker origin. An origin changes starting powers, preferences, weaknesses, and which inhabitants trust the realm first. Origins provide narrative and strategic variety, but no objectively superior option.

Core campaign loop:

1. Generate and validate a campaign world.
2. Reveal and connect viable underground spaces.
3. Zone rooms and establish logistics, production, research, rituals, and defences.
4. Form contracts, rescue expedition finds, and create or bind eligible inhabitants.
5. Set policies and priorities; observe inhabitants autonomously fulfil, resist, or reinterpret them.
6. Discover ruins, secrets, factions, and crises.
7. Make Pactmaker interventions with limits and consequences.
8. Resolve the campaign, or fail meaningfully and carry defined meta-progression forward.

The game runs in real time with pause and configurable speed settings. Important decisions may automatically pause the game. The player controls roles, priorities, policies, contracts, decrees, and limited powers, but does not directly control individual inhabitants. Emergency powers may influence an individual temporarily, with an explicit cost or consequence.

## 6. World, narrative, and tone

The setting is original Weird/Gothic Fantasy: decaying ancient powers, strange biology, impossible geography, pacts, and hidden histories. Major factions include rival underground realms/Pactmakers; expansionist surface polities shaped by bureaucracy and aristocracy; cultic/religious institutions; and academies, guilds, and research bodies.

The game may satirize bureaucracy, absurd administrative rules, capitalism and extractive resource hunger, religious dogma, aristocracy, imperial expansion, and institutional research without responsibility. Satire must target systems and power structures rather than demean real-world protected groups. Humour must not trivialize harm.

Story delivery requires short readable dialogues, recurring characters, fixed narrative anchor points, branching events with visible later effects, simulation-led moment-to-moment stories, and contracts/reports/notices/advisor commentary as core vehicles for dry humour.

Visual violence is cartoon-macabre, never realistic gore. Potentially distressing material requires content warnings and individually switchable presentation options where practical. The game must distinguish dark atmosphere from glorification of cruelty.

## 7. Procedural generation

Each campaign generates dungeon topology, tunnels, resources, biome placement, discoverable ruins/secrets/special locations, and a suitable political/starting context. Random inhabitants and variant event contexts are allowed, but generation is constrained by narrative anchors.

Generation is **constrained, validated generation**, not unconstrained randomness. Before a map is offered to the player, it must satisfy configurable validity rules including reachable critical paths, meaningful spacing, no undocumented impossible isolated regions, sufficient early resources and safe expansion choices, bounded distributions, no unavoidable soft locks, a reproducible seed, and a validation report for development/testing.

Invalid worlds are rejected and regenerated automatically. Generator rules, constraints, and seed failures must have automated tests.

## 8. Realm building and spatial simulation

- The realm uses a readable isometric tile grid with free zoom and a fixed camera orientation.
- Walls, roofs, and ceilings may become partially transparent when they conceal relevant activity.
- Players designate room zones. Inhabitants furnish, operate, expand, repurpose, neglect, or cause room decay according to rules and resources.
- Initial room categories include research/ritual/knowledge, workshops/storage/production, and defence/traps/control points.
- Construction shall reflect access, labour, materials, and logistics without turning routine building into excessive micromanagement.
- Biomes affect resources, visual identity, environmental opportunities, and risks.
- A minimap and quick navigation to rooms, inhabitants, and important events are required.

## 9. Inhabitants

The first release contains six original cultures. They must differ in body form, movement, values, professions, social expectations, and conflict patterns. Some may be spirits, demons, or other bound beings. They must not replicate recognizable existing fantasy creature designs.

Every inhabitant has identifying data and culture; core attributes, traits, preferences, and aversions; needs for food, rest, safety, and recognition; profession/role, training, and progression; morale, loyalty, stress, and potential for departure or rebellion; relationships; and concise event memory.

The UI must explain the practical cause of a need, decision, mood, conflict, or contract issue. The simulation must use data-driven rules so cultures and future mod content can be added without editing unrelated systems.

Inhabitants may enter by individual contract, through exploration/rescue, or via permitted creation, breeding, summoning, or binding systems. Death is possible and meaningful. Contract breach, rebellion, and departure are valid outcomes where caused by visible world conditions and choices.

## 10. Resources, knowledge, and progression

The economy includes material resources, food/medicine/comfort goods, knowledge/secrets/memories, influence/reputation/fulfilled contracts, and magical essence from places, events, or beings. Names and exact balance are content decisions, but resource sinks and sources must be transparent.

Research and rituals unlock powers, decrees, contracts, and discoveries. Rooms and infrastructure can improve or transform. Cross-campaign meta-progression unlocks carefully limited options. Progression must add approaches, not merely percentage bonuses. Failed campaigns grant knowledge or a limited persistent unlock at a meaningful cost; they must not erase consequences or make failure optimal.

## 11. Conflict and crises

Inhabitants resolve most combat autonomously through role, behaviour, relationships, position, and current condition. The Pactmaker may exert limited tactical influence through powers and decrees. The first release includes two major crises. Conflict need not be a repeating attack-wave mode; threats can come from politics, environment, contract failure, discovery, or hostile forces. Injury, death, loss, fear, and later consequences must be visible in the event log and relevant inspection panels.

## 12. Difficulty and saving

Required presets are Narrative, Balanced, and Challenging. Players may change difficulty during a campaign and adjust individual rules rather than only selecting a global preset. Difficulty must come from world rules and scarcity, not hidden artificial opponent bonuses. Free local save/load is required. Campaign failure is allowed and must lead to a clean restart flow with defined learning/meta-progression. Players can export and import saves. Generated worlds and saves remain player-owned.

## 13. UI, UX, and accessibility

Required information design includes plain-language context menus and tooltips, an event log showing cause/effect/affected inhabitants, visual overlays for diagnostics, inspectable room and inhabitant views, and optional automatic camera follow for important events.

Accessibility requirements include remappable keyboard and pointer controls, scalable interface and text, subtitle support, separate volume sliders, full pause and adjustable speed, non-colour-only state communication, and reduced motion/effect options before iPadOS release.

## 14. Audio and presentation

The game uses stylised, colourful 2.5D visuals with a dark Weird/Gothic atmosphere. Dynamic music responds to biomes, danger, crisis, discovery, and success. Distinct work, inhabitant, creature, and environmental sounds are required. Voice is short and selective. A visual, audio, and writing style bible must define terminology, tone, palette, silhouette principles, sound motifs, and forbidden reference points.

## 15. Localization

English is the complete source language. German is the first additional language. Every user-visible string must be externalized into localization data from the first commit; no visible strings may be hard-coded in scripts or scenes. Community translations must be possible without programming. Automated validation must detect missing keys, invalid placeholders, and layout-critical formatting problems. Source text must be written with translation-friendly grammar and avoid concatenated fragments.

## 16. Technical architecture

- Engine: **Godot 4**.
- Primary language: **GDScript**, using static typing where it improves clarity.
- Native extensions: C++ only after profiling proves a contained hotspot cannot meet targets in GDScript.
- No external runtime service is required for gameplay.
- Separate deterministic game-domain logic from Godot scene/UI code wherever practical.
- Use data-driven definitions for rooms, inhabitants/cultures, contracts, events, research, resources, biomes, and localization.
- Maintain clear module boundaries for world generation, simulation, campaign state, saving, UI, audio, and content data.
- Centralise settings and tuning constants.
- Support deterministic replay of generator seeds and test scenarios.
- Save formats must be versioned and migration-tested.

The planned repository structure is documented in `docs/repository-structure.md`. Structure changes that affect module boundaries or contributor workflow require an ADR.

## 17. Code quality, documentation, and AI-agent rules

Each module begins with purpose, responsibility, public entry point, and main dependencies. Public classes and functions require plain-English docstrings. Comments explain intent, invariants, constraints, and trade-offs. Architecture diagrams and data-flow explanations live in `docs/`. `AGENTS.md` defines repository orientation, safe commands, testing expectations, style rules, file ownership boundaries, documentation updates, and prohibition of silent broad refactors. Coding standards define naming, typing, error handling, logging, test naming, data schema conventions, commit/PR expectations, and localization rules.

## 18. Testing and local quality gates

The project shall provide a documented single local command that runs the standard quality suite without requiring GitHub Actions or paid cloud capacity.

Required local checks include formatting, linting, static analysis, unit tests, generator invariant tests, save/load/export/import and migration tests, localization tests, and reproducible benchmarks. GitHub CI may run a minimal confirmation suite, but local tests remain authoritative and complete. Every fixed bug should receive a regression test when feasible.

## 19. Security, privacy, and data handling

No account, login, mandatory launcher, online connection, telemetry, analytics SDK, advertising SDK, tracking pixel, or external game service is allowed for required gameplay. No personal data is collected by default. Save files remain local and exportable/importable in documented formats. Any future opt-in error report must be explicit, inspectable before sending, anonymised, and avoid personal paths/content by default. Dependencies must be minimal, pinned where appropriate, license-reviewed, and documented. Imported saves/mods must validate formats and fail safely; untrusted content must not execute arbitrary code.

## 20. Open source, assets, and IP compliance

Original source code is intended to be GPL-3.0-or-later. Original art, audio, writing, and data are intended to be CC BY-SA 4.0 unless a future documented exception is necessary. Third-party material is permitted only when compatible, documented, and included with required attribution/notice text.

Long-term assets should be original. Early placeholders are permitted only if clearly labelled and license-compatible. AI-generated assets are permitted only if transparently labelled in the asset manifest with creation method, tool/source where appropriate, human modifications, and applicable rights information, and they must still pass originality and style review.

Before public releases, maintainers must complete an IP and license checklist covering names, writing, visuals, UI, gameplay presentation, music/audio, dependencies, third-party assets, AI-generated assets, attributions, and trademarks.

## 21. Community and governance

The repository is public. Contributions are welcome through reviewed pull requests. A Code of Conduct and clear moderation process are required. Issue templates should cover bugs, feature ideas, balance feedback, translation issues, performance, and security/privacy concerns. Public milestones and a prioritized issue board track work. Release notes disclose changes, known limitations, migration notes, and credits. Tester builds should be reproducible and regularly published through GitHub Releases.

## 22. Distribution

Initial distribution is free downloads through GitHub Releases. No accounts, launcher, or online service are required. macOS builds should be signed/notarized when practicable; unsigned development builds must clearly explain macOS installation implications. itch.io and Steam are possible future channels but must not shape initial architecture or impose closed services.

## 23. Milestone plan

| Milestone | Definition of done |
|---|---|
| M0: Foundation | Repository governance, licenses, `AGENTS.md`, style rules, Godot project, local quality command, CI-minimum, documentation skeleton. |
| M1: Playable realm core | Camera/UI shell, tile map, zoning, one room lifecycle, local saving, diagnostics. |
| M2: Simulation core | Inhabitant needs, contracts, tasks, relationships/memory foundation, resources, event log, tests. |
| M3: World and campaign | Constrained generator, two biomes, exploration, fixed narrative anchors, branching events. |
| M4: Knowledge and crisis | Research/ritual progression, Pactmaker powers, autonomous conflict, two crises, difficulty/settings. |
| M5: Vertical campaign completion | Six cultures, ten rooms, fifteen events, complete success/failure/restart loop, English/German, audio pass. |
| M6: Public release readiness | Performance target, accessibility review, licensing/IP audit, reproducible builds, release notes, known-issues list. |
| Post-release | Balancing, additional content, mod/content interfaces, and later iPadOS preparation; co-op only after the single-player architecture is stable. |

## 24. Acceptance criteria for the first public release

1. A player can start, complete, fail, save, load, export, and import a campaign entirely offline.
2. Every generated campaign passes documented generator validation rules.
3. The required vertical-slice content counts are present and usable.
4. Inhabitants visibly demonstrate contracts, needs, autonomous work, and at least one meaningful social consequence.
5. The player can understand major outcomes through inspection, overlays, and the event log.
6. Difficulty presets and per-rule adjustment work without hidden difficulty bonuses.
7. English is complete; German is available; localization tests pass.
8. The documented local quality suite passes on the reference development environment.
9. The game meets its smooth-play target on the reference MacBook Air M5 under the documented normal-realm benchmark.
10. No required feature sends player data or requires an Internet connection.
11. Code, assets, dependencies, and documentation pass the pre-release IP/license checklist.
12. Public documentation, project plan, roadmap, ADRs, changelog, code of conduct, contribution guide, and `AGENTS.md` exist and are current.

## 25. Open design decisions to resolve during M0/M1

- Final public project name and trademark clearance for *Pact & Pit*.
- Names, visual silhouettes, and social rules of the six original cultures.
- Exact biome names and mechanical identities.
- Exact room list, resource names, contract taxonomy, and Pactmaker origin roster.
- Save-file format and mod-data schema versioning detail.
- Minimum supported desktop hardware beyond the M5 reference target.
- Exact macOS signing/notarization release policy and iPadOS schedule.

These are intentionally open content/implementation decisions, not gaps in the product requirements. Their resolution must follow the style bible, IP checklist, ADR process, and vertical-slice scope.
