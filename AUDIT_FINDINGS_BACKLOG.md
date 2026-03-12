# audit findings backlog

date: 2026-03-12
baseline snapshot: `ubuntu` working tree after maturity hardening wave

## active backlog

there is no confirmed open `p0`–`p3` runtime or release-blocking finding in this audit pass.

## watch items

these are real future maintenance costs, but they are **not** proven defects in the current baseline:

### w-001 — planner data contract is still multi-source

- type: maintainability / design cost
- files:
  - `data/domains/catalog.json`
  - `domains.tiers`
  - `sni_pools.map`
  - `transport_endpoints.map`
  - `modules/lib/domain_sources.sh`
  - `modules/config/domain_planner.sh`
- problem:
  - active planning still combines the canonical catalog with legacy side maps and tier sources.
  - this is manageable today, but it keeps planner reasoning and future cleanup more expensive than necessary.
- recommended direction:
  - keep shrinking active planner reads toward the catalog-first contract.
  - preserve side maps only where migration or explicit compatibility still needs them.

### w-002 — a few focused modules are still broad enough to deserve future decomposition if scope grows

- type: maintainability
- files:
  - `config.sh`
  - `modules/lib/runtime_inputs.sh`
  - `modules/config/domain_planner.sh`
- problem:
  - the root-script sprawl problem was materially reduced, but a few remaining files still carry broad contracts and could become the next hotspots if new product scope is added carelessly.
- recommended direction:
  - keep new behavior out of the root entrypoints.
  - prefer subsystem-focused extractions before these files start growing sharply again.

## resolved in this wave

these older items are no longer open:

- `f-001` — workflow lint coverage mismatch between `make lint` and `tests/lint.sh`
- `f-002` — active xhttp planner dependency on grpc-named seed contracts
- `f-003` — oversized root entrypoint sprawl; this wave cut `lib.sh` below 1000 lines and moved orchestration behavior into focused modules
- pinned bootstrap being visually secondary to floating bootstrap in user docs
- missing public issue/pr intake templates
- missing reusable vm-lab proof-pack artifact flow
- workflow maintenance noise from node 20 deprecation warnings in pinned actions
