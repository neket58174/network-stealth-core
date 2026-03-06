# Roadmap

This roadmap is a directional public plan, not a strict delivery promise.

## Current baseline

v5.1.0 establishes:

- minimal xhttp-first install as the strongest default
- `install --advanced` for manual prompt-driven setup
- `migrate-stealth` for managed legacy migration
- schema v2 client artifacts with per-config variants

## Near-term priorities

1. transport-aware health checks beyond simple listening-port validation
2. cleaner capability matrix for client export formats
3. more migration and rollback coverage around legacy installs
4. tighter docs consistency across all public surfaces

## Next improvements

- better domain-health readability and operator verdicts
- more explicit compatibility notes for each client/export target
- stronger artifact validation after `update`, `repair`, and migration
- measurement loops for real-world RF network behavior

## Mid-term direction

- retire legacy `grpc/http2` after the compatibility window
- separate policy inputs more clearly from generated runtime artifacts
- add optional experimental stealth tiers without weakening the default path

## Out of scope for now

- broad multi-os promises without ci validation
- enterprise orchestration features without a clear maintenance budget
- silent behavior changes without changelog and migration notes

## How to influence the roadmap

- open a Discussion with a concrete use case
- attach reproducible diagnostics for reliability gaps
- submit PRs with tests and bilingual docs updates
