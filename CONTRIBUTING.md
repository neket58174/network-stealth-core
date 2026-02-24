# Contributing

Thanks for contributing to `Xray Reality Ultimate`.

This guide defines the expected workflow for safe, reviewable, and reliable changes.

## Core rules

- keep commits focused and easy to review
- preserve security controls and rollback behavior
- include tests and docs updates with behavior changes
- avoid silent compatibility breaks

## Local setup

### Prerequisites

- Linux or WSL
- Bash 4.3+
- Git
- `shellcheck`, `shfmt`, `bats`, `actionlint`
- Node.js (or `npx`) for markdown lint

### Clone and track upstream

```bash
git clone https://github.com/YOUR_USERNAME/network-stealth-core.git
cd network-stealth-core
git remote add upstream https://github.com/neket58174/network-stealth-core.git
git fetch upstream
```

## Repository layout

| Path | Purpose |
|---|---|
| `xray-reality.sh` | bootstrap wrapper |
| `lib.sh` | runtime core, validation, action dispatch |
| `install.sh` | dependency setup and Xray install/update |
| `config.sh` | config generation and key/client artifacts |
| `service.sh` | systemd + firewall + lifecycle operations |
| `health.sh` | health monitor and diagnose support |
| `export.sh` | export templates for supported clients |
| `modules/` | extracted reusable modules |
| `tests/bats/` | unit/integration shell tests |
| `tests/e2e/` | lifecycle and scenario tests |

## Mandatory local checks

Run before every push:

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

### Shell conventions

1. keep scripts `set -euo pipefail`-safe
2. quote variables consistently
3. avoid `eval` for runtime/user input
4. reuse validators instead of ad-hoc checks
5. use atomic writes for critical files
6. preserve rollback guarantees on mutating flows

### High-risk areas

Changes in these areas require extra attention and test coverage:

- bootstrap and download verification
- path/permission handling
- systemd unit generation
- firewall apply/rollback
- rollback stack and cleanup traps

## Testing expectations

- every behavior change should add or adjust BATS coverage
- lifecycle-sensitive changes should include e2e checks when relevant
- documentation updates must pass markdown lint and docs command contracts

Example targeted runs:

```bash
bats tests/bats/unit.bats
bats tests/bats/integration.bats
bats tests/bats/health.bats
```

## Branches and commits

### Branch naming

- `fix/<topic>`
- `feat/<topic>`
- `docs/<topic>`
- `security/<topic>`

### Commit format

Use short, direct messages:

```text
type(scope): summary
```

Examples:

- `fix(config): harden temporary config validation`
- `docs(readme): refresh quick-start section`
- `security(wrapper): tighten bootstrap pin handling`

## Pull request checklist

- [ ] local checks are green (`make ci`)
- [ ] tests cover changed behavior
- [ ] docs updated for user-visible changes
- [ ] `CHANGELOG.md` updated when needed
- [ ] no secrets included in commits
- [ ] rollback/security behavior preserved

## Documentation update scope

Behavior changes usually affect one or more of:

- `README.md`
- `README.ru.md`
- `ARCHITECTURE.md`
- `OPERATIONS.md`
- `SECURITY.md`
- `CHANGELOG.md`

## Security reporting

Do not open public issues for vulnerabilities.

Use responsible disclosure via GitHub private vulnerability reporting. See `SECURITY.md`.
