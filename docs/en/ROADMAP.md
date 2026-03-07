# Roadmap

This roadmap is a directional public plan, not a strict delivery promise.

## Current baseline

v6.0.0 establishes:

- xhttp-only strongest-default install
- explicit blocking of mutating actions on managed legacy transports until `migrate-stealth`
- transport-aware self-check backed by canonical raw xray client artifacts
- capability-driven export matrix
- local measurement harness for real-network comparison

## Near-term priorities

1. strengthen self-check observability and probe diagnostics
2. improve domain-health feedback and operator summaries
3. expand measurement reports and comparison tooling
4. keep bilingual docs and release metadata perfectly aligned

## Next improvements

- richer summarize-and-compare output for `scripts/measure-stealth.sh`
- more precise capability notes for external clients
- stronger e2e coverage around degraded `warning` paths
- more visible field-data guidance for RF network validation

## Mid-term direction

- optional experimental stealth tiers without weakening the default path
- clearer separation between policy inputs and generated runtime artifacts
- better operator tooling for rotating or retiring degraded nodes

## Out of scope for now

- broad multi-os promises without CI validation
- misleading partial client templates for unsupported xhttp targets
- silent behavior changes without changelog and migration notes

## How to influence the roadmap

- open a Discussion with a concrete use case
- attach reproducible diagnostics for reliability gaps
- include self-check or measurement output where possible
- submit PRs with tests and bilingual docs updates
