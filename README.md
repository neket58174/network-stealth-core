<h1 align="center">Xray Reality Ultimate</h1>

<p align="center">
  Production-ready Xray Reality bootstrap with strict validation, rollback safety, and client exports.
</p>

<p align="center">
  <a href="https://github.com/neket58174/network-stealth-core/releases"><img alt="release" src="https://img.shields.io/badge/release-v4.1.7-0f766e"></a>
  <a href="LICENSE"><img alt="license" src="https://img.shields.io/badge/license-MIT-97ca00"></a>
  <a href="OPERATIONS.md"><img alt="platform" src="https://img.shields.io/badge/platform-linux%20server-1d4ed8"></a>
  <a href="Makefile"><img alt="qa" src="https://img.shields.io/badge/qa-make%20ci-334155"></a>
</p>

## What this project is

`Xray Reality Ultimate` is a Bash-first automation project for deploying and operating Xray Reality on Linux servers.

It is designed around three priorities:

- predictable installation and update flows
- security-first defaults (validation, integrity checks, privilege separation)
- operational clarity (rollback, diagnostics, export artifacts)

## Canonical source

Use only the official repository for scripts, tags, and release artifacts:

- `https://github.com/neket58174/network-stealth-core`

If installation instructions are copied from forks or mirrors, verify them before running.

## Documentation

| File | Purpose |
|---|---|
| `README.ru.md` | Full Russian guide |
| `ARCHITECTURE.md` | Runtime architecture and module contracts |
| `OPERATIONS.md` | Day-2 runbook, incident handling, rollback |
| `SECURITY.md` | Security model, controls, and disclosure policy |
| `CONTRIBUTING.md` | Development workflow and contribution standards |
| `CHANGELOG.md` | Release history and compatibility notes |

## Quick start

### Recommended: universal install

Works in regular shells and constrained environments (`chroot`, limited `/dev/fd`).

```bash
curl -fL https://raw.githubusercontent.com/neket58174/network-stealth-core/main/xray-reality.sh -o /tmp/xray-reality.sh
sudo bash /tmp/xray-reality.sh install
```

### Alternative: one-line install

```bash
sudo bash <(curl -fsSL https://raw.githubusercontent.com/neket58174/network-stealth-core/main/xray-reality.sh) install
```

If you see `/dev/fd/...: no such file or directory`, use universal install.

### Pinned bootstrap (supply-chain hardened)

```bash
curl -fL https://raw.githubusercontent.com/neket58174/network-stealth-core/main/xray-reality.sh -o /tmp/xray-reality.sh
sudo XRAY_REPO_COMMIT=<full_commit_sha> bash /tmp/xray-reality.sh install
```

### Bootstrap source selection

Default bootstrap source is `main` (latest fixes).

```bash
curl -fL https://raw.githubusercontent.com/neket58174/network-stealth-core/main/xray-reality.sh -o /tmp/xray-reality.sh
sudo bash /tmp/xray-reality.sh install
```

To force latest release tag instead:

```bash
curl -fL https://raw.githubusercontent.com/neket58174/network-stealth-core/main/xray-reality.sh -o /tmp/xray-reality.sh
sudo XRAY_BOOTSTRAP_DEFAULT_REF=release bash /tmp/xray-reality.sh install
```

## Core commands

| Command | Description |
|---|---|
| `install` | Install full stack |
| `add-clients [N]` | Add `N` client configs |
| `add-keys [N]` | Alias of `add-clients` |
| `update` | Update Xray core |
| `repair` | Reapply units, firewall, monitoring, and artifact consistency checks |
| `status` | Show runtime state and config summary |
| `logs [xray\|health\|all]` | Stream logs |
| `diagnose` | Collect diagnostics snapshot |
| `rollback [dir]` | Restore previous backup session |
| `uninstall` | Full removal |
| `check-update` | Check upstream updates |

Example:

```bash
sudo bash xray-reality.sh status
sudo bash xray-reality.sh diagnose
sudo bash xray-reality.sh logs
```

## Runtime profiles

| Profile | Internal Tier | Config Limit | Intended Usage |
|---|---|---:|---|
| `ru` | `tier_ru` | 100 | Main RU domain pool |
| `ru-auto` | `tier_ru` | auto 5 | Fast default install |
| `global-ms10` | `tier_global_ms10` | 10 | Low-count global profile |
| `global-ms10-auto` | `tier_global_ms10` | auto 10 | Fast global-ms10 install |
| `custom` | `custom` | 100 | User-managed domain set |

## Key CLI flags

```bash
--domain-profile ru|ru-auto|global-ms10|global-ms10-auto|custom
--transport grpc|http2
--progress-mode auto|bar|plain|none
--num-configs N
--start-port N
--server-ip IPV4 --server-ip6 IPV6
--yes --non-interactive
--verbose
```

## Security highlights

- strict runtime input and path validation
- controlled download surface via allowlisted hosts
- Xray integrity verification (`sha256` + optional `minisign`)
- transactional file writes with rollback support
- hardened `systemd` service and unprivileged runtime user

See [SECURITY.md](SECURITY.md) for full details.

## Export artifacts

Generated after `install`, `add-clients`, and `repair`:

- `/etc/xray/private/keys/export/clashmeta.yaml`
- `/etc/xray/private/keys/export/singbox.json`
- `/etc/xray/private/keys/export/nekoray-fragment.json`
- `/etc/xray/private/keys/export/v2rayn-fragment.json`

## Tested OS matrix

CI smoke and lifecycle checks are maintained for:

- `ubuntu-22.04`
- `ubuntu-24.04`
- `debian-12`
- `fedora-41`
- `almalinux-9`

## Local QA

```bash
make lint
make test
make release-check
make ci
```

Windows helper scripts:

```powershell
pwsh ./scripts/markdownlint.ps1
pwsh ./scripts/windows/run-validation.ps1
```

## Docker

```bash
docker pull ghcr.io/neket58174/network-stealth-core:vX.Y.Z
docker run --rm ghcr.io/neket58174/network-stealth-core:vX.Y.Z --help
```

## License

MIT License. See [LICENSE](LICENSE).
