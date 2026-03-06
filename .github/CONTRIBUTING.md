# Contributing

Thanks for contributing to **Network Stealth Core**.

This guide defines the expected workflow for safe and reviewable changes.

## Core rules

- keep commits focused and small
- preserve rollback and security behavior
- update tests and docs with behavior changes
- avoid silent compatibility breaks

## Current product baseline

Before changing behavior, assume these contracts are public:

- `install` = minimal xhttp-first strongest-default path
- `install --advanced` = manual prompt-driven setup
- `migrate-stealth` = supported managed migration from legacy `grpc/http2`
- `clients.json` = schema v2 with per-config `variants[]`
- `export/raw-xray/` = raw per-variant xray client json artifacts

## Local setup

### Prerequisites

- linux or wsl
- bash 4.3+
- git
- `shellcheck`, `shfmt`, `bats`, `actionlint`
- node.js (or `npx`) for markdown lint

### Clone and track upstream

```bash
git clone https://github.com/YOUR_USERNAME/network-stealth-core.git
cd network-stealth-core
git remote add upstream https://github.com/neket371/network-stealth-core.git
git fetch upstream
```

## Repository layout

| Path | Purpose |
|---|---|
| `xray-reality.sh` | bootstrap wrapper |
| `lib.sh` | runtime core and dispatcher |
| `install.sh` | dependency setup and lifecycle entrypoints |
| `config.sh` | config generation and client artifacts |
| `service.sh` | systemd, firewall, and runtime status |
| `health.sh` | health monitor and diagnostics |
| `export.sh` | client export templates |
| `modules/` | extracted reusable modules |
| `tests/bats/` | shell unit and integration tests |
| `tests/e2e/` | lifecycle and migration scenarios |
| `docs/` | bilingual documentation |

## Mandatory local checks

Run before push:

```bash
make lint
make test
make release-check
make ci
```

Equivalent direct commands:

```bash
bash tests/lint.sh
bats tests/bats
bash scripts/check-release-consistency.sh
```

## Coding standards

1. keep scripts safe under `set -euo pipefail`
2. quote variables consistently
3. avoid `eval` for user-controlled input
4. reuse shared validators
5. use atomic writes for critical files
6. keep mutating flows rollback-safe

## High-risk areas

Changes in these areas require extra coverage:

- bootstrap and download verification
- permission and path handling
- systemd unit generation
- firewall apply and rollback
- backup stack and cleanup traps
- migration between legacy transport and xhttp
- generated client artifacts and export paths

## Testing expectations

- every behavior change should include or update bats coverage
- lifecycle-sensitive changes should include e2e checks
- docs updates must pass markdown lint and command-contract checks

Useful targeted runs:

```bash
bats tests/bats/unit.bats
bats tests/bats/integration.bats
bats tests/bats/transport.bats
```

## Documentation update scope

Behavior changes usually affect:

- `README.md`
- `README.ru.md`
- `docs/en/*.md`
- `docs/ru/*.md`
- `.github/CONTRIBUTING.md`
- `.github/SECURITY.md`

If a change touches public install behavior, migration, or artifacts, update both languages in the same pass.

## Release metadata expectations

If you prepare a release:

- bump `SCRIPT_VERSION`
- update wrapper/readme release markers
- add matching sections to both changelogs
- do not tag until branch CI is green

## Pull request checklist

- [ ] local checks are green (`make ci`)
- [ ] tests cover changed behavior
- [ ] docs updated for user-visible changes
- [ ] both changelogs updated when release metadata is involved
- [ ] no secrets in commits
- [ ] rollback and security behavior preserved

## Security reporting

Do not open public issues for vulnerabilities.

Use GitHub private vulnerability reporting. See [SECURITY.md](SECURITY.md).
