# src

GDScript source organised by module. The module split is
defined in [`docs/adrs/0002-module-boundaries.md`](../adrs/0002-module-boundaries.md).

## Module map

| Module | README | Status | Public entry point |
|--------|--------|--------|--------------------|
| `src/core`    | [README](core/README.md)    | M1 stub + `SplitMix64` | `class_name PitPactCore`, `SplitMix64` |
| `src/world`   | [README](world/README.md)   | M1 stub | `class_name WorldState` |
| `src/sim`     | [README](sim/README.md)     | M2 foundation | `class_name Sim` |
| `src/realm`   | [README](realm/README.md)   | M1 stub | `class_name Realm`, `RealmFactory` |
| `src/content` | [README](content/README.md) | M1 stub | `class_name ContentRegistry` |
| `src/save`    | [README](save/README.md)    | M1 stub | `class_name SaveService` |
| `src/ui`      | [README](ui/README.md)      | M1 stub | `class_name RealmUiController` |
| `src/audit`   | [README](audit/README.md)   | M1 stub | `class_name AuditLog` |

## The data-flow rule (load-bearing)

> Deterministic game-domain modules — `src/core`, `src/world`,
> `src/sim`, `src/realm`, `src/content`, `src/save` — **MUST NOT
> import from `src/ui`.**
>
> UI imports game-domain modules; never the other way.

The mechanical check is
[`tools/check_module_dependencies.sh`](../tools/check_module_dependencies.sh).
It runs as part of [`tools/run_quality.sh`](../tools/run_quality.sh)
and the CI confirmation suite.

## Cross-cutting dependency graph

```
src/core        → (nothing)
src/content     → src/core
src/audit       → src/core
src/save        → src/core
src/world       → src/core, src/content
src/sim         → src/core, src/world, src/content, src/audit
src/realm       → src/core, src/world, src/sim, src/content, src/save, src/audit
src/ui          → src/realm, src/content, src/audit
```

The graph is acyclic. Adding a new module or a new edge
requires updating ADR-0002 and the dependency check.

## See also

- [`docs/adrs/0002-module-boundaries.md`](../adrs/0002-module-boundaries.md)
  — the full per-module contract and the data-flow rule.
- [`docs/repository-structure.md`](../docs/repository-structure.md) —
  the broader repository layout.
- [`docs/requirements.md`](../docs/requirements.md) §16, §17.
