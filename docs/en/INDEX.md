# Documentation index (EN)

Welcome to the **Network Stealth Core** documentation hub.

## Start here

- [../../README.md](../../README.md) — quick start and command map
- [OPERATIONS.md](OPERATIONS.md) — install, maintenance, migration, measurement, and rollback
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) — symptom-driven debugging

## Current baseline

- `install` = minimal xhttp-only strongest-default path
- `install --advanced` = manual profile and config-count prompts
- `migrate-stealth` = only managed bridge from legacy `grpc/http2`
- `clients.json` = schema v2 with per-config `variants[]`
- `export/raw-xray/` = raw per-variant xray client json files
- `export/capabilities.json` = machine-readable export capability matrix
- `/var/lib/xray/self-check.json` = last transport-aware verdict
- `scripts/measure-stealth.sh` = local measurement harness

## Core docs

| Document | Purpose |
|---|---|
| [ARCHITECTURE.md](ARCHITECTURE.md) | runtime architecture, module contracts, generated artifacts |
| [OPERATIONS.md](OPERATIONS.md) | day-2 operations, migration, measurement, and maintenance runbook |
| [CHANGELOG.md](CHANGELOG.md) | released changes and version notes |

## Operator docs

| Document | Purpose |
|---|---|
| [FAQ.md](FAQ.md) | common questions about profiles, prompts, and runtime behavior |
| [TROUBLESHOOTING.md](TROUBLESHOOTING.md) | install, self-check, migration, and artifact recovery |
| [GLOSSARY.md](GLOSSARY.md) | project terms used in logs, docs, and scripts |

## Project docs

| Document | Purpose |
|---|---|
| [COMMUNITY.md](COMMUNITY.md) | discussions, issue quality, and useful field reports |
| [ROADMAP.md](ROADMAP.md) | post-v6 direction and near-term priorities |
| [../../.github/CONTRIBUTING.md](../../.github/CONTRIBUTING.md) | contributor workflow and quality gates |
| [../../.github/SECURITY.md](../../.github/SECURITY.md) | supported versions, threat model, and disclosure process |

## Language navigation

- russian docs: [../ru/INDEX.md](../ru/INDEX.md)
- russian readme: [../../README.ru.md](../../README.ru.md)
